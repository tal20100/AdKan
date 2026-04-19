# ADR 0004 — Data-Leaves-Device Policy

**Status:** Accepted. **BINDING. VETO-PROTECTED.**
**Date:** 2026-04-18.
**Deciders:** privacy-engineer, security-reviewer. Founder-approved.

## Context

AdKan processes Screen Time data via Apple's FamilyControls / DeviceActivity APIs. Apple's App Store Review Guideline 5.1.2 states:
> "Data gathered from the HomeKit API, HealthKit, Consumer Health Records API, MovementDisorderAPIs, ClassKit, or from Depth and/or Facial Mapping tools (e.g., ARKit, Camera APIs, or Photo APIs) **may not be used for marketing, advertising, or use-based data mining**, including by third parties."

Screen Time APIs are in the same spirit. Apple has not explicitly ruled on whether anonymous aggregate sync for a consented leaderboard is permitted, but the safest reading — the one that survives the strictest reviewer — is **do not export any identifiable usage data at all**.

The competing pressure: AdKan's core product REQUIRES some comparative metric across friends for the leaderboard to function.

## Decision

**The ONLY field that crosses the network per user per day is `dailyTotalMinutes: Int`.**

Nothing else. Ever.

Formally:
```swift
struct DailySync: Codable {
    let userId: UUID        // anonymous Supabase UUID, NOT Apple ID, NOT IDFA
    let date: Date          // ISO8601 YYYY-MM-DD
    let dailyTotalMinutes: Int  // 0..1439
}
```

The following are RADIOACTIVE and must NEVER be transmitted to Supabase, PostHog, Sentry, or any third party:
- Per-app usage (TikTok minutes, Instagram minutes, etc.)
- Per-category usage (Social, Entertainment, etc.)
- Per-hour buckets
- Pickup count
- FamilyActivitySelection token payloads
- DeviceActivity thresholds reached
- Shield activation events
- Notification-interaction timestamps
- Device identifiers beyond the Supabase UUID (no IDFA, no IDFV, no push token visible outside the Edge Function)
- User location
- Contacts, calendar, health
- Apple Sign-In relay email (stored encrypted for account recovery; never displayed, never analytics, never leaderboard)

## Veto authority

Any pull request, code change, analytics event, Edge Function, database column, or API surface that ADDS a field crossing the device-network boundary requires sign-off from BOTH:
- `security-reviewer` agent
- `privacy-engineer` agent

Either can veto the change unilaterally. Veto reason logged in `/plan/status.md`.

The `pre-commit-secret-scan` hook will fail a commit that introduces a new field in `DailySync` or equivalent payloads. Test `DailySyncPayloadSchemaTest` (see `/specs/0002-leaderboard-core.md`) uses Swift `Mirror` reflection to assert the payload has exactly three keys. That test is a tripwire.

## Alternatives rejected

### "We can sync per-category totals; categories are not per-app."
Rejected. Categories still reveal behavior patterns that could be mined. Also, Apple's Guideline 5.1.2 language is broad enough that a strict reviewer would flag category sync. Risk not worth any leaderboard improvement.

### "We can sync with differential privacy noise."
Rejected for v1 — adds implementation complexity, weakens the simple user-facing promise ("we only send one number"). Revisit if product needs push toward it.

### "We can sync encrypted payloads end-to-end-encrypted between friends."
Rejected for v1 — same complexity argument. The single-integer payload is already so minimal that E2E adds no user-meaningful protection.

### "We can store raw events on-device forever, only sync aggregates."
Accepted — that's already the design. On-device retention is 90 days (GRDB cleanup job nightly). No user-facing justification for longer.

## User-facing commitment (marketing copy, HE+EN)

Pre-flight to any public claim:
- HE: `הנתונים שלך נשארים בטלפון. רק מספר אחד יומי (סך המינוטים) נשלח כדי שהלוח יעבוד.`
- EN: `Your data stays on your phone. Only one daily number (total minutes) is sent so the leaderboard works.`

This copy ships in onboarding (PRD 0004 pre-prompt) and in the App Store privacy description. If marketing ever wants a different framing, both `security-reviewer` and `privacy-engineer` must approve.

## Consequences

**Positive:**
- Defensible, simple, truthful privacy story.
- Minimum blast radius if Supabase is breached (a list of `<UUID, date, int>` tuples is barely exploitable).
- Simpler App Store privacy nutrition label.
- Easier IL legal compliance.
- Feature velocity preserved — the boundary is bright, so new features don't require endless privacy debates.

**Negative:**
- Can't build features that require richer cross-friend analytics (e.g., "you and Rona both lose most time to TikTok" — this would require per-app sync, forbidden here).
- Friday-recap personalization is constrained to on-device computation only.
- Any future "share your deep stats" feature requires explicit per-user opt-in with a new boundary crossing, which would require a new ADR.

## Audit trail

`privacy-engineer` runs a quarterly audit:
1. `grep -R "sync" supabase/functions/ | grep -v "sync-daily-score"` — assert no other sync function exists without review.
2. `grep -R "daily_total_minutes\|daily_category\|per_app" supabase/functions/` — assert only `daily_total_minutes` is referenced.
3. Schema diff against the last audited version — flag new columns in any sync-touching table.
