# Spec 0002 — Leaderboard Core (implementation)

**Implements:** `/prd/0002-leaderboard-core.md`.
**Owner:** social-graph-engineer + backend-engineer. **Reviewers:** privacy-engineer (veto), qa-engineer, ios-engineer.

## Supabase schema (DDL)

```sql
-- Every user gets an anonymous UUID from Supabase Auth.
create table public.users (
  id uuid primary key default gen_random_uuid(),
  apple_relay_email text,                 -- encrypted at rest, never displayed, account-recovery only
  display_name text not null,             -- user-chosen, HE or EN
  avatar_pack text not null default 'default',
  created_at timestamptz not null default now()
);

create table public.friendships (
  user_id uuid not null references public.users(id) on delete cascade,
  friend_id uuid not null references public.users(id) on delete cascade,
  status text not null check (status in ('pending','accepted','blocked')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  primary key (user_id, friend_id)
);

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  template text not null check (template in ('friends','roommates','partner','coworkers')),
  owner_id uuid not null references public.users(id),
  created_at timestamptz not null default now()
);

create table public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- THE privacy boundary. Only these three fields per user per day leave the device.
create table public.daily_scores (
  user_id uuid not null references public.users(id) on delete cascade,
  date date not null,
  daily_total_minutes integer not null check (daily_total_minutes >= 0 and daily_total_minutes < 1440),
  updated_at timestamptz not null default now(),
  primary key (user_id, date)
);

create table public.entitlements (
  user_id uuid primary key references public.users(id) on delete cascade,
  tier text not null check (tier in ('none','trial','subscriber','lifetime')),
  trial_expires_at timestamptz,
  source text,                           -- 'viral_unlock' | 'intro_offer' | 'purchase' | 'manual'
  updated_at timestamptz not null default now()
);
```

## Row-Level Security

All tables: RLS enabled. Policies:

```sql
alter table public.daily_scores enable row level security;

create policy "users read own scores" on public.daily_scores
  for select using (auth.uid() = user_id);

-- Friends-only leaderboard read via SECURITY DEFINER function.
-- Direct SELECT from daily_scores by other users is blocked.
create or replace function public.leaderboard_for(requester uuid)
returns table(user_id uuid, display_name text, date date, daily_total_minutes int)
language sql security definer stable as $$
  select ds.user_id, u.display_name, ds.date, ds.daily_total_minutes
  from public.daily_scores ds
  join public.users u on u.id = ds.user_id
  where ds.date = current_date
    and (
      ds.user_id = requester
      or exists (
        select 1 from public.friendships f
        where f.user_id = requester and f.friend_id = ds.user_id and f.status = 'accepted'
      )
    )
  order by ds.daily_total_minutes asc;
$$;

create policy "users write own scores" on public.daily_scores
  for insert with check (auth.uid() = user_id);

create policy "users update own scores" on public.daily_scores
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

Footgun note from research: `SELECT COUNT(*)` can leak row count. All leaderboard reads go through `leaderboard_for()`; never a raw `COUNT(*) FROM daily_scores`.

## Edge Functions (Deno)

Catalog (full bodies written in Build phase, not this spec):
- `supabase/functions/sign-up` — post-Apple-Sign-In user row creation.
- `supabase/functions/send-friend-invite` — create pending friendship, generate deep link.
- `supabase/functions/sync-daily-score` — accept `{userId, date, dailyTotalMinutes}`, upsert. Rejects any extra fields (strict schema validation).
- `supabase/functions/calculate-rank-changes` — cron every 15min. For every group, compute new ranks, emit push for users whose rank changed.
- `supabase/functions/send-push` — called by `calculate-rank-changes`. Signs JWT with `.p8`, POSTs to APNs HTTP/2. No FCM.
- `supabase/functions/weekly-recap` — cron Friday 18:00 IL. Emits recap payloads to all active users.
- `supabase/functions/validate-receipt` — StoreKit 2 receipt verification via Apple's App Store Server API.
- `supabase/functions/viral-unlock-check` — called on friendship acceptance. If user has 3 accepted friends, trigger entitlement update to `.trial`.

## iOS client

`App/Features/Leaderboard/`:
```
├── Models/
│   ├── LeaderboardEntry.swift        # {userId, displayName, rank, dailyMinutes, change}
│   └── RankChange.swift              # .up | .down | .same
├── ViewModels/
│   └── LeaderboardViewModel.swift    # @Observable
├── Views/
│   ├── HomeScreen.swift              # top-enemy card + avatar + leaderboard + CTA
│   ├── LeaderboardRow.swift
│   └── TopEnemyCard.swift
└── Sync/
    ├── DailySyncUploader.swift       # calls sync-daily-score with { userId, date, dailyTotalMinutes }
    └── RealtimeLeaderboardListener.swift  # Supabase realtime subscription to daily_scores changes
```

`LeaderboardViewModel`:
```swift
@Observable final class LeaderboardViewModel {
    var entries: [LeaderboardEntry] = []
    var myRank: Int?
    var loading: Bool = false

    func refresh() async {
        loading = true; defer { loading = false }
        let rows = try await supabase.rpc("leaderboard_for", params: ["requester": userId]).execute()
        entries = rows.decoded()
        myRank = entries.firstIndex(where: { $0.userId == userId }).map { $0 + 1 }
    }

    func subscribeToRealtime() {
        realtimeChannel.on("postgres_changes", ...) { [weak self] _ in Task { await self?.refresh() } }
    }
}
```

## DailySyncUploader

Runs once per day on first foreground after midnight IL. Reads `dailyTotalMinutes` from `ScreenTimeProvider.yesterdayTotal()`. Uploads:
```swift
struct DailySyncPayload: Codable {
    let userId: UUID
    let date: String     // YYYY-MM-DD
    let dailyTotalMinutes: Int
}
```
NO OTHER FIELDS. Anti-drift test in `DailySyncUploaderTests` uses `Mirror` reflection to assert the payload has exactly those three keys.

## Rank-change push (APNs)

Edge Function `calculate-rank-changes` runs every 15min via Supabase cron. For each group:
1. Fetch today's daily_scores for all group members.
2. Compute ranks.
3. Compare to cached ranks from the previous run (stored in a `rank_cache` table).
4. For every user whose rank changed, enqueue a push.
5. Rate limit: max 3 pushes per user per day. Counter in Redis-less Postgres table `push_quota(user_id, date, count)`.

Push payload templated in both HE and EN; user's locale preference (from `users.preferred_locale` column) determines which string ships.

## Tests

- `LeaderboardViewModelTests` — feed mocked Supabase responses, assert `entries` + `myRank`.
- `DailySyncPayloadSchemaTest` — reflect payload, assert exactly 3 keys. FAILS if anyone adds a field.
- `LeaderboardForRPCTest` — integration test against a local Supabase instance, with fixture friendships, assert non-friends cannot leak.
- `RankCalculationTests` — for each input ordering, assert correct ranks and change deltas.
- `PushQuotaTests` — assert 4th push same day is dropped.

## Out of scope for v1

- In-app chat.
- Historical leaderboards (yesterday's, last-week's).
- Global / public leaderboards.
- Video reactions to rank changes.
