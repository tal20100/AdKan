# Plan 06 — Backend Architecture

Supabase (EU Frankfurt) + Edge Functions (Deno / TypeScript). Aligned with ADR 0003 (push), ADR 0004 (data policy), `/specs/0002-leaderboard-core.md` (schema detail).

---

## Supabase project layout

```
supabase/
├── config.toml                   # project ref, region, local-dev
├── migrations/
│   ├── 0001_base_tables.sql
│   ├── 0002_rls_policies.sql
│   ├── 0003_leaderboard_function.sql
│   ├── 0004_push_quota.sql
│   ├── 0005_entitlements.sql
│   └── 0006_indexes.sql
├── functions/
│   ├── sign-up/                  # bootstrap a new user after Apple Sign-In
│   ├── send-friend-invite/       # create friendship invite + deep-link code
│   ├── sync-daily-score/         # the ONLY sync endpoint (ADR 0004)
│   ├── calculate-rank-changes/   # runs post-sync; triggers send-push
│   ├── send-push/                # APNs HTTP/2 direct; JWT ES256
│   ├── weekly-recap/             # Friday 18:00 IL cron-invoked
│   ├── validate-receipt/         # StoreKit 2 receipt verification
│   └── viral-unlock-check/       # check if user's invites ≥3 installed
└── seed.sql                      # local dev seed data only; no prod data
```

Supabase secrets (set via dashboard or `supabase secrets set`): see `/plan/02-infrastructure-setup.md §supabase-secrets`.

---

## Schema (consolidated; full DDL in `/specs/0002`)

```sql
-- users
create table users (
  id          uuid primary key default gen_random_uuid(),
  apple_sub   text unique not null,                -- Apple Sign-In 'sub' claim; never Apple Email Relay
  email_hash  text,                                -- sha256 of relay email; used only for account recovery lookups
  preferred_locale text not null default 'he' check (preferred_locale in ('he','en')),
  push_token  text,                                -- APNs token; nullable until first-foreground registration
  created_at  timestamptz not null default now()
);

-- friendships (symmetric; both rows inserted)
create table friendships (
  user_id     uuid not null references users(id) on delete cascade,
  friend_id   uuid not null references users(id) on delete cascade,
  status      text not null check (status in ('pending','accepted','blocked')),
  created_at  timestamptz not null default now(),
  primary key (user_id, friend_id)
);

-- groups
create table groups (
  id          uuid primary key default gen_random_uuid(),
  template    text not null check (template in ('friends','roommates','partner','coworkers')),
  created_by  uuid not null references users(id),
  created_at  timestamptz not null default now()
);

create table group_members (
  group_id    uuid not null references groups(id) on delete cascade,
  user_id     uuid not null references users(id) on delete cascade,
  joined_at   timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- the payload (ADR 0004)
create table daily_scores (
  user_id             uuid not null references users(id) on delete cascade,
  date                date not null,
  daily_total_minutes int  not null check (daily_total_minutes between 0 and 1439),
  synced_at           timestamptz not null default now(),
  primary key (user_id, date)
);

-- entitlements (mirror of StoreKit 2 state, server-side truth)
create table entitlements (
  user_id         uuid primary key references users(id) on delete cascade,
  kind            text not null check (kind in ('none','trial','monthly','annual','lifetime')),
  expires_at      timestamptz,                    -- null for lifetime; in-future for active
  original_txn_id text not null,                  -- StoreKit 2 original_transaction_id for refund handling
  updated_at      timestamptz not null default now()
);

-- push rate-limiting (ADR 0003)
create table push_quota (
  user_id uuid not null references users(id) on delete cascade,
  date    date not null,
  count   int  not null default 0,
  primary key (user_id, date)
);

-- invite codes (viral unlock)
create table invite_codes (
  code         text primary key,                   -- 6-char alphanumeric
  inviter_id   uuid not null references users(id),
  group_id     uuid references groups(id),
  redeemed_by  uuid references users(id),
  created_at   timestamptz not null default now(),
  redeemed_at  timestamptz
);
```

Full indexes + RLS policies are in `/specs/0002-leaderboard-core.md §schema`.

---

## RLS posture

Every table: `alter table <t> enable row level security;`

Default: **deny all**. Explicit policies per table:

### `users`
- `select using (auth.uid() = id)` — user reads self only.
- `update using (auth.uid() = id)` — user updates own `preferred_locale` + `push_token`.
- No insert from client (use `sign-up` Edge Function with service role).

### `friendships`
- `select using (auth.uid() = user_id or auth.uid() = friend_id)` — read rows where self is either side.
- Insert/update/delete via `send-friend-invite` Edge Function only.

### `daily_scores`
- Client `select` — none directly. Use `leaderboard_for(user_id)` `SECURITY DEFINER` function.
- Client `insert/update` — only via `sync-daily-score` Edge Function (service role).

### `leaderboard_for(user_uuid uuid)` (SECURITY DEFINER)
Returns daily_total_minutes for accepted friends + self over the last 7 days. This is the ONLY read path for another user's score. No raw join available from client.

```sql
create or replace function leaderboard_for(user_uuid uuid)
returns table(user_id uuid, date date, daily_total_minutes int)
language plpgsql
security definer
set search_path = public
as $$
begin
  if user_uuid <> auth.uid() then
    raise exception 'not authorized';
  end if;
  return query
  select ds.user_id, ds.date, ds.daily_total_minutes
  from daily_scores ds
  where ds.user_id = user_uuid
     or ds.user_id in (
       select friend_id from friendships
       where user_id = user_uuid and status = 'accepted'
     )
     and ds.date >= current_date - 6;
end
$$;
```

`security-reviewer` + `privacy-engineer` double-review this function on every change.

### `entitlements`
- `select using (auth.uid() = user_id)`.
- `insert/update/delete` via `validate-receipt` Edge Function only (service role).

### `push_quota`, `invite_codes`, `groups`, `group_members`
Policies in `/specs/0002`.

---

## Edge Functions catalog

All functions are Deno, TypeScript, deployed via `supabase functions deploy <name>`. Each exports `Deno.serve((req) => ...)`.

### `sign-up`
**Input:** Apple Sign-In ID token (JWT).
**Behavior:**
1. Verify token against Apple's JWKS.
2. Extract `sub` claim.
3. Upsert into `users` (by `apple_sub`). Hash the relay email (if present) to `email_hash`.
4. Return Supabase session JWT + `user_id`.

### `send-friend-invite`
**Input:** authenticated user; target_invite_code OR target_phone_hash (invite via deep-link).
**Behavior:** generate 6-char `invite_codes.code`, return deep-link `https://adkan.link/invite/<code>`.

### `sync-daily-score`
**Input:** `{ date: 'YYYY-MM-DD', dailyTotalMinutes: Int }` — authenticated user.
**Behavior:**
1. Validate shape strictly. Exactly 2 keys. Reject any extra field (`privacy-engineer` test: `DailySyncPayloadAntiDriftTest`).
2. Validate `dailyTotalMinutes between 0 and 1439`.
3. Validate `date` is today or yesterday (no backfill beyond yesterday).
4. Upsert `daily_scores` on (user_id, date).
5. Enqueue `calculate-rank-changes` for the user's friend set.

### `calculate-rank-changes`
**Input:** user_id.
**Behavior:**
1. Compute 7-day sum for user and each accepted friend.
2. Diff against previous rank snapshot cached in Redis/KV.
3. For each user whose rank changed: call `send-push`.
4. Update snapshot.

### `send-push`
**Input:** `{ user_id, title_key, body_key, locale, interpolation? }`.
**Behavior:**
1. Check `push_quota` — drop if daily count ≥3.
2. Load the ES256 JWT (cached across invocations via Deno KV; refresh every ~55 min).
3. Localize the payload in Edge Function (locale from `users.preferred_locale`, fallback `he`). Locked copy in `/specs/0002 §push-copy`.
4. POST to `https://api.push.apple.com/3/device/<push_token>` per ADR 0003.
5. On `BadDeviceToken` → null out `users.push_token`. On `TooManyProviderTokenUpdates` → exponential backoff on JWT refresh.
6. Increment `push_quota.count`.

### `weekly-recap`
**Trigger:** Supabase cron scheduled `0 15 * * 5` UTC (Friday 18:00 Israel Standard Time; adjust for DST).
**Behavior:**
1. For each active user, compute week stats (total minutes, rank, delta vs. last week).
2. Generate recap payload server-side (to avoid device bias).
3. Queue push with deep link to recap screen in-app.

### `validate-receipt`
**Input:** `{ original_transaction_id, jws_representation }` — from StoreKit 2.
**Behavior:**
1. Verify against Apple's `verifyReceipt` (legacy) or preferably App Store Server API `GetAllSubscriptionStatuses` / `GetTransactionHistory` (modern StoreKit 2 server verification) — use the JWS approach per Apple's 2025 guidance.
2. Determine current entitlement.
3. Upsert `entitlements` row.
4. Return current entitlement to client.

### `viral-unlock-check`
**Input:** authenticated user.
**Behavior:** count `invite_codes` where `inviter_id = auth.uid() and redeemed_by is not null`. If ≥3 and no existing trial entitlement: grant 7-day group-of-10 trial via `entitlements` upsert.

---

## Secret flow

- `.env.local` on the founder's Windows: client-side keys only (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `POSTHOG_PROJECT_KEY`, `SENTRY_DSN`).
- Supabase project secrets: server-side keys (`APNS_AUTH_KEY_P8_CONTENTS`, `APNS_KEY_ID`, `APNS_TEAM_ID`, `APPLE_SHARED_SECRET`, service role key — auto-managed by Supabase).
- Xcode Cloud environment: client-side keys mirrored from `.env.local`, plus `SENTRY_AUTH_TOKEN` for dSYM upload.

Never: `.p8` contents in the repo. Never: service role key in the repo. Never: client code calling Apple's App Store Server API directly (always through Edge Function).

---

## Realtime

Supabase Realtime on `daily_scores` where `user_id in (friend_ids)`. Subscribed from `LeaderboardSubscription.swift` on `LeaderboardScreen.onAppear`; unsubscribed on disappear. Server-side broadcast-auth ensures users only receive events for rows they're allowed to read (RLS enforced on realtime payloads since Supabase Realtime v2).

---

## Observability

- Edge Function logs: Supabase log console. Sentry integration via `@sentry/deno` — capture unhandled errors with redacted payloads (strip push tokens, strip JWTs, strip `apple_sub`).
- Metrics: basic counters via `console.log("[metric] <name> <value>")` scraped via log-drain. Full metrics as post-v1 enhancement.
