# ADR 0003 — Push Notifications

**Status:** Accepted.
**Date:** 2026-04-18.
**Deciders:** backend-engineer, security-reviewer, privacy-engineer.

## Context

Rank-change pushes are the main retention hook (PRD 0002). They must fire within 15 minutes of the rank change, be rate-limited to 3/day per user, be localized HE/EN, and respect the privacy boundary (no per-app data in push payload).

Two common patterns:
1. **Firebase Cloud Messaging (FCM) → APNs** — the 2024–2025 Supabase docs default pattern.
2. **Direct APNs HTTP/2** — Supabase Edge Function signs a JWT with the `.p8` AuthKey and POSTs directly to Apple.

## Decision

Use **direct APNs HTTP/2 from a Supabase Edge Function**, signed with the `.p8` AuthKey stored in Supabase secrets.

## Alternatives considered

### FCM as relay
- **Pros:** documented Supabase pattern, easier multi-platform extension (if we ever ship Android).
- **Cons:**
  - Adds Google as a dependency for IL user data (privacy-team objection).
  - One more third party in the secret graph.
  - Cost: free tier is generous, but failure mode is opaque (Google closes silently on abuse).
  - Requires uploading the `.p8` to Firebase, expanding its blast radius.

Rejected because privacy-engineer opposes Google as a default dependency for a privacy-sensitive app, and the additional integration surface is not worth the "easier Android" option when v1 is iPhone-only.

### Third-party push providers (OneSignal, Pushwoosh)
- **Pros:** rich targeting features, A/B testing built in.
- **Cons:** all treat user data as an asset; all require SDK integration on the device, which Rule 2 would flag; all require sharing the push token with them.

Rejected.

### Web push only (no native)
- Not applicable for iOS app.

Rejected.

## Implementation

### Secret layout
Supabase project secrets (server-side only, never in repo):
- `APNS_KEY_ID` — 10-char key identifier from Apple Developer portal.
- `APNS_TEAM_ID` — 10-char team ID.
- `APNS_AUTH_KEY_P8_CONTENTS` — full contents of `AuthKey_<keyId>.p8`.
- `APNS_TOPIC` = `com.taltalhayun.adkan`.
- `APNS_ENVIRONMENT` = `production` or `sandbox` (TestFlight uses sandbox).

The `.p8` file contents are radioactive. NEVER in the repo. NEVER echoed in logs. The `pre-edit-secret-scan` hook's `AuthKey_*` filename pattern catches accidental commits; the `[A-Za-z0-9+/=]{40,}` regex catches accidental paste-in.

### JWT signing (Deno Edge Function)

```ts
// supabase/functions/send-push/index.ts
import { create, getNumericDate } from "https://deno.land/x/djwt/mod.ts";

const jwt = await create(
  { alg: "ES256", kid: Deno.env.get("APNS_KEY_ID")!, typ: "JWT" },
  { iss: Deno.env.get("APNS_TEAM_ID")!, iat: getNumericDate(0) },
  privateKey  // imported from APNS_AUTH_KEY_P8_CONTENTS
);

const resp = await fetch(`https://api.push.apple.com/3/device/${pushToken}`, {
  method: "POST",
  headers: {
    "authorization": `bearer ${jwt}`,
    "apns-topic": Deno.env.get("APNS_TOPIC")!,
    "apns-push-type": "alert",
    "apns-priority": "5",
  },
  body: JSON.stringify({
    aps: {
      alert: { title: localizedTitle, body: localizedBody },
      sound: "default",
      badge: 1,
    }
  })
});
```

JWT rotated every ~55 minutes (Apple allows up to 60min before refresh required). Supabase Edge Function caches JWT across invocations via Deno KV for efficiency.

### Rate limiting

Postgres table `push_quota(user_id, date, count)`. Before sending, upsert increment; if `count > 3`, drop the push and log to PostHog `push_dropped_quota`.

### Localization

Push payload localized in the Edge Function, not on the device. User's `preferred_locale` column (`he` or `en`, set during onboarding) determines which string ships. Fallback: HE.

### Failure modes

- APNs returns `BadDeviceToken` → mark user's push token as stale, skip future pushes until re-registered.
- APNs returns `TooManyProviderTokenUpdates` → exponential backoff on the JWT refresh cadence.
- Certificate expired (`.p8` revoked by founder by accident) → Edge Function logs to Sentry; founder re-uploads new `.p8` to Supabase secrets.

## Consequences

**Positive:**
- No third party beyond Apple + Supabase.
- `.p8` lives in exactly one place.
- Smaller secret graph.
- Cheaper at scale (APNs is free; FCM free tier has limits).

**Negative:**
- More code to write than using FCM SDK.
- JWT signing in Deno requires an ES256 implementation — `djwt` or Web Crypto API.
- If we ship Android in v2, we have to reimplement — but Android is not in v1 scope.
