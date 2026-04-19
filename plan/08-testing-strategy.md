# Plan 08 — Testing Strategy

TDD, three validation tiers, fixture matrix, CI gate definitions, TestFlight test plan.

**Rule 5:** `qa-engineer` writes the failing test FIRST. Implementation follows.

---

## Three validation tiers

### Tier 1 — fast loop (seconds, offline)
- Every CI run, every local build.
- XCTest units + swift-snapshot-testing for views + XCUITest for flows.
- `StubScreenTimeProvider` fixtures — no device needed.
- 80% of the app covered here.
- Budget: full suite <5 min on Xcode Cloud.

### Tier 2 — medium loop (hours, TestFlight)
- 3–5 Israeli external testers on real iPhones.
- Real `FamilyControls` entitlement in effect (after Apple approval).
- Scripted test plan below; testers run once per TestFlight build.
- Hours-to-days feedback latency.
- Covers: permission flow, real-device aggregate accuracy, push delivery, StoreKit real-sandbox purchases, realtime leaderboard on live network.

### Tier 3 — remote eyes (days, production)
- Sentry crashes + PostHog funnels + Supabase Edge Function logs.
- Catches what testers don't self-report: silent failures, drop-offs, crash spikes.
- Founder + orchestrator check dashboards daily during beta.

---

## Unit test matrix

| Module | Coverage target | Tests |
|---|---|---|
| `AdKanCore/Models` | 100% encoders/decoders | `UserCodableTests`, `SurveyAnswerCodableTests`, `EntitlementCodableTests` |
| `AdKanCore/Infra/Database` | 100% migrations | `DatabaseMigrationTests` — apply 0→N on fresh db, verify schema |
| `AdKanScreenTime/Provider` | 100% contract | `ScreenTimeProviderContractTests` — runs against Real + Stub |
| `AdKanScreenTime/Fixtures` | all fixtures | `StubScreenTimeProviderFixtureTests` |
| `AdKanScreenTime/Aggregator` | happy path + midnight boundary | `DailyTotalAggregatorTests` |
| `AdKanAppGroupShared` | round-trip | `AppGroupCrumbRoundtripTests` — extension-target writes, main-app reads |
| `AdKanBackend/RPC/DailySyncRPC` | payload shape | `DailySyncPayloadAntiDriftTest` (**ADR-0004 tripwire**) |
| `AdKanFeatures/Onboarding/ViewModels` | 5 screens | `SurveyViewModelTests` — each Q1...Q5 transition |
| `AdKanFeatures/Onboarding/Effects` | 4 effects | `SurveyEffectDispatcherTests` — each effect applied correctly |
| `AdKanFeatures/Leaderboard/ViewModels` | realtime + rank compute | `LeaderboardViewModelTests` |
| `AdKanFeatures/Paywall/Commerce` | StoreKitTest | `PaywallViewModelStoreKitTests` — uses StoreKitTest framework |
| `AdKanAnalytics/EventCatalog` | event-name whitelist | `EventCatalogWhitelistTests` — assert every PostHog call uses an enum case |

---

## Snapshot test matrix

Using `swift-snapshot-testing` (SPM package). Each screen rendered in 6 configurations: (HE, EN) × (iPhone SE 3rd gen, iPhone 15, iPhone 15 Pro Max).

| Screen | Configurations | Notes |
|---|---|---|
| Splash | 2 × 3 = 6 | logo + loader |
| Onboarding Q1 | 6 | RTL chevron mirroring |
| Onboarding Q2 | 6 | 4-option picker |
| Onboarding Q3 | 6 | top-enemy chooser |
| Onboarding Q4 | 6 | crew template chooser |
| Onboarding Q5 | 6 | goal slider |
| Leaderboard empty | 6 | invite bar visible |
| Leaderboard with friends | 6 + (fixture × 3) = 18 | `low`, `goalHit`, `spiraling` fixtures |
| Paywall | 6 | lifetime hero position |
| Friday recap | 6 | IG-Story share card |
| Settings | 6 | retake, language, privacy |

Snapshots stored in `AdKanTests/__Snapshots__/`. Regenerating requires `qa-engineer` explicit approval to guard against accidental UI regressions being normalized.

---

## XCUITest (UI flow)

| Test | Steps |
|---|---|
| `OnboardingFlowUITests.happyPath` | Launch → through all 5 Qs → lands on leaderboard |
| `OnboardingFlowUITests.skipPath` | Launch → skip each Q → lands on leaderboard with default answers |
| `OnboardingFlowUITests.retakePath` | Settings → retake → Q1 → lands back on Settings |
| `PaywallFlowUITests.fourthFriendTrigger` | Leaderboard with 3 friends → tap invite → paywall |
| `PaywallFlowUITests.threeTierPresent` | Paywall → assert 3 tier buttons visible with correct ₪ |

XCUITests are slow; keep the suite tight. Unit + snapshot tests are the bulk.

---

## Fixture catalog (ScreenTimeFixture)

From ADR 0005:

| Fixture | todayMinutes | yesterdayMinutes | UI state |
|---|---|---|---|
| `zero` | 0 | 0 | empty-state prompt |
| `low` | 80 | 110 | avatar `chill`, green bar |
| `goalHit` | 120 | 130 | avatar `streakWinning`, amber bar |
| `slipping` | 180 | 140 | avatar `stressed`, red bar |
| `spiraling` | 420 | 380 | avatar `spiraling`, red + warning |

Used by: snapshot tests, SwiftUI previews, DEBUG fixture selector in Settings.

---

## `DailySyncPayloadAntiDriftTest` (the tripwire)

The single most important test. Protects the ADR-0004 privacy boundary.

```swift
final class DailySyncPayloadAntiDriftTest: XCTestCase {
    func test_payload_has_exactly_three_keys() throws {
        let payload = DailySyncPayload(
            userId: UUID(),
            date: Date(),
            dailyTotalMinutes: 120
        )
        let encoded = try JSONEncoder().encode(payload)
        let dict = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        let keys = Set(dict.keys)
        XCTAssertEqual(keys, Set(["userId", "date", "dailyTotalMinutes"]),
                       "ADR 0004 violation: DailySyncPayload must carry EXACTLY these 3 keys. Adding a field requires security-reviewer + privacy-engineer sign-off and an ADR amendment.")
    }

    func test_payload_has_no_unexpected_stored_properties() {
        // Swift Mirror reflection — catches field additions that Codable omits
        let payload = DailySyncPayload(
            userId: UUID(),
            date: Date(),
            dailyTotalMinutes: 0
        )
        let mirror = Mirror(reflecting: payload)
        let labels = Set(mirror.children.compactMap { $0.label })
        XCTAssertEqual(labels, Set(["userId", "date", "dailyTotalMinutes"]))
    }
}
```

If either assertion fails, the commit is blocked via `pre-commit-test-gate` hook. Adding a field requires:
1. Amend ADR 0004.
2. Update this test's expected set.
3. Obtain BOTH `security-reviewer` and `privacy-engineer` sign-off.
4. Log veto-votes in `plan/status.md`.

---

## Tier-2 TestFlight test plan (scripted)

Given to each Israeli tester with each TestFlight build. Tester reports results via a Google Form / Airtable (founder-action to create the form; not automated in v1).

**Setup**
1. Install AdKan from TestFlight invitation email.
2. Launch AdKan.
3. Sign in with Apple.

**Onboarding**
4. Complete all 5 survey questions (choose any answer).
5. On the Screen Time permission prompt, tap "Got it" / "הבנתי", then approve in the system dialog.
6. Confirm avatar renders and leaderboard screen loads.

**Invite flow**
7. Tap "Invite a friend."
8. Share the invite deep-link with another tester.
9. Other tester clicks the link, completes onboarding, becomes a friend.
10. Confirm both see each other on the leaderboard within 2 minutes.

**Push**
11. After at least one day of Screen Time data, wait for rank change push.
12. Tap the push. App should open to the leaderboard with the updated rank.

**Paywall**
13. Add a second friend (you now have 2). No paywall.
14. Add a third (3). No paywall.
15. Attempt to add a fourth. Paywall should appear.
16. Inspect paywall — confirm 3 tiers visible with correct ILS prices.
17. Start 3-day trial on Annual (sandbox). Confirm purchase succeeds in sandbox.
18. Confirm paywall dismisses and you can add the 4th friend.

**Privacy**
19. Settings → Privacy → read the privacy sentence. Confirm it says "Your data stays on your phone. Only one daily number (total minutes) is sent so the leaderboard works." in HE and EN.
20. Settings → Language → switch HE ↔ EN. Confirm entire UI reflows with correct RTL/LTR mirroring.

**Revocation**
21. iOS Settings → Screen Time → (revoke AdKan's access).
22. Foreground AdKan. Confirm the permission banner appears with re-enable CTA.
23. Tap re-enable. Confirm it takes you back to Screen Time settings.

**Regression sweeps**
24. Kill AdKan from app switcher. Relaunch. Confirm it resumes on leaderboard, no data loss.
25. Airplane-mode on → foreground AdKan → no crash. Airplane-mode off → data re-syncs within 1 min.

---

## CI gate definitions

Xcode Cloud workflow `Build + Test + TestFlight`:

| Stage | Gate | Failure action |
|---|---|---|
| Build | Swift compile clean | Fail build |
| Lint | SwiftLint (warnings-as-errors for style rules) | Fail build |
| Unit tests | 100% pass | Fail build |
| Snapshot tests | 100% match | Fail build; upload diffs as artifacts |
| XCUITest | 100% pass on iPhone 15 sim (iOS 17.5) | Fail build |
| Secret scan | gitleaks clean | Fail build |
| Localization gate | parity check | Fail build |
| TestFlight upload | success | Notify founder on failure |

Xcode Cloud posts status to GitHub PR checks. Merge blocked until green.

---

## Pre-commit vs CI

Pre-commit hooks: fast, local, cheap — secret scan, localization parity, test-gate for TDD proof.
CI: full suite, slower, authoritative — the gate for shipping.

Don't skip pre-commit with `--no-verify` unless founder explicitly authorizes. Agents never use `--no-verify`.
