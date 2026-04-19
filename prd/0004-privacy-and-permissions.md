# PRD 0004 — Privacy and Permissions

**Owner:** privacy-engineer + security-reviewer (both with veto power). **Reviewers:** ios-engineer, app-store-reviewer, backend-engineer.

## Problem

ScreenTime data is the most sensitive data an iOS app can touch short of HealthKit. Apple's Guideline 5.1.2 prohibits "marketing, advertising, or use-based data mining" of Screen Time data. Aggregate consented leaderboard sync is legally ambiguous. Users can revoke the permission with one Settings toggle. The user has no physical iPhone, so this PRD is also the blueprint external TestFlight testers will follow.

We design for the strictest reasonable reading of Apple's policy + a privacy stance we can defend publicly in Hebrew and English.

## The data boundary (binding, veto-protected)

See `/adr/0004-data-leaves-device-policy.md`.

The ONLY field that crosses the network per user per day:
```swift
struct DailySync: Codable {
    let userId: UUID         // Supabase-issued anonymous
    let date: Date           // ISO8601, YYYY-MM-DD
    let dailyTotalMinutes: Int
}
```

Never syncs: per-app usage, per-category usage, per-hour bucket, ScreenTime tokens, FamilyActivitySelection payloads, device identifiers (IDFA, IDFV, push token beyond Apple APNs pairing), location, contacts, calendar, health.

`security-reviewer` and `privacy-engineer` have pre-commit veto on any PR adding a field to the sync payload. Hooks in `.claude/settings.json` enforce.

## FamilyControls permission flow

1. **When requested:** after onboarding survey completes, on the first home-screen entry.
2. **Why framed:** pre-prompt explains the ask in plain language.
   - HE: `כדי להראות לך כמה זמן אתה במסך, האפליקציה צריכה הרשאה מאפל. הנתונים לא יוצאים מהטלפון — רק סכום יומי אחד (במינוטים) נשלח כדי שהלוח יעבוד.`
   - EN: `To show your screen time, we need Apple's permission. Data never leaves your phone — only a single daily total (in minutes) is sent so the leaderboard works.`
3. **System dialog:** `AuthorizationCenter.shared.requestAuthorization(.individual)`.
4. **On denial:** friendly screen, not blocking.
   - HE: `אין בעיה. הלוח יעבוד בלי נתונים אמיתיים — אתה תזין בעצמך בסוף היום.`
   - EN: `No problem. The leaderboard still works — you'll enter your minutes manually at end of day.`
   This keeps the app usable even if permission is denied. Manual-entry mode is v1.0, not v1.1.

## Daily permission re-check

Research finding (Phase 1): users can revoke Screen Time permission in iOS Settings with a single toggle. Unpatchable.

The app re-checks `AuthorizationCenter.shared.authorizationStatus` on every foreground. If the status has changed from `.approved` to anything else:
- Friendly in-app banner, not a full-screen blocker.
  - HE: `נראה שכיבית את ההרשאה. אתה רוצה להפעיל אותה מחדש?`
  - EN: `Looks like you turned off the permission. Want to re-enable?`
- Button: **`הפעל מחדש | Re-enable`** → triggers `requestAuthorization` again.
- Dismiss button: **`מאוחר יותר | Later`** → hides for 24 hours.

## The stub provider (device-less development)

Because the founder has no iPhone, the `StubScreenTimeProvider` (see `/adr/0005-screentime-provider-abstraction.md`) runs in simulator and debug builds. It returns deterministic fixture data:
- `fixture_low_usage`: 1h 20m daily total, trending down.
- `fixture_goal_hit`: exactly at the Q5 goal.
- `fixture_slipping`: goal + 30m, trending up.
- `fixture_spiraling`: 3x goal for 3 consecutive days.
- `fixture_zero`: 0m (new user first day).

Fixtures are selectable via a debug-build-only Settings row. Never surface in Release.

## Apple Sign-In flow

1. User lands on launch screen → **`Sign in with Apple`** button.
2. User approves → Apple returns a relay email + opaque user identifier.
3. Supabase `supabase.auth.signInWithIdToken(provider: .apple, idToken:...)` exchanges the token for a Supabase session.
4. Supabase issues an anonymous `userId: UUID`. This is the only user identifier ever sent to our backend. Apple's relay email is stored encrypted and used only for account recovery — never displayed, never analytics, never leaderboard.
5. On logout, session is revoked, local GRDB cache is wiped.

No email+password. No phone OTP. No magic links.

## App Group

All cross-process data between main app and `DeviceActivityMonitorExtension` flows through App Group `group.com.taltalhayun.adkan`. SQLite file at `Library/Application Support/adkan-extension-crumbs.db` within the App Group container.

Extension writes. Main app reads and aggregates. Main app is the ONLY process that ever computes `dailyTotalMinutes` and syncs to Supabase.

## What appears on the Apple privacy nutrition label

Per App Store Connect submission:
- **Data linked to you:** none.
- **Data not linked to you:** Usage Data (→ "Product Interaction" — anonymous leaderboard score only).
- **Data used to track you:** none.
- **Data types collected:** "Other data types — Daily screen time total, aggregated, anonymous."

`app-store-reviewer` agent validates this against the actual code before every submission.

## Founder-action items for FamilyControls entitlement request

When the founder submits the entitlement application (Day-1 founder-action):
- App description emphasizes: **"Personal self-monitoring and friend-based motivation. Not used for surveillance, advertising, or data mining."**
- Avoid phrases like "track," "monitor," "watch" — App Review treats these as red flags.
- Prefer: "reflect," "review," "aggregate," "share-with-consent."
- Submit as `.individual` authorization, NOT `.child`. Child requires the app to be parental-control framed.

## Out of scope for v1

- End-to-end encryption of the daily minutes field (overkill for a non-sensitive integer).
- Self-hosted Supabase (accepted trust in Supabase EU Frankfurt).
- Differential privacy noise on the aggregate.
- Export-my-data download flow (Apple's App Store Privacy Report covers this; revisit if legal requires).
