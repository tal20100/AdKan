# Plan 09 — Seven-Day Execution

Day-by-day deliverable map. Morning goal, afternoon goal, end-of-day demo, blockers. "Demo" means a thing the founder can look at or run — not a promise.

---

## Day 0 (today) — Plan lock

**Already done in planning mode:**
- 32-file scaffold authored (root + research + prd + specs + adr + plan)
- Agent specs written
- Master plan at `C:/Users/Tal/.claude/plans/you-are-the-founding-iterative-peach.md`
- Day 1 first-three-commands defined (§7 master plan)

**Before Day 1 begins:**
- Founder types `approved, begin execution`.
- Founder starts the Apple Developer Program enrollment (§02-infrastructure-setup §apple-developer-program) — runs in parallel with Claude's Day 1 work.

---

## Day 1 — Governance + smoke test

### Morning
**Goal:** prove the environment + hooks work end-to-end before a single line of feature code.

Tasks:
1. Commit the existing scaffold (Batches 1–11) as initial commit. Verify all hooks fire without false positives.
2. `node scripts/hello-mac.mjs` → expect `Mac bridge: OFFLINE (expected)` + exit 0.
3. Verify the pre-commit localization gate on a deliberately-broken `.xcstrings` fixture; revert.
4. Verify pre-edit secret scan on a deliberately-seeded fake token; revert.

### Afternoon
**Goal:** Supabase + PostHog + Sentry signups complete (founder-action), Xcode Cloud connected.

Tasks (founder actions in parallel; Claude waits + verifies):
5. Founder completes `§supabase`, `§posthog`, `§sentry` from `/plan/02`.
6. Founder pastes keys into `.env.local` (NOT committed).
7. Claude verifies `.env.local` is gitignored, `.env.example` has matching shape.
8. Founder submits FamilyControls entitlement (if not already done).

### End-of-day demo
- `git log` shows 1–3 commits with clean hook output.
- Founder has ticked items 1–6 in `/plan/02` checklist.
- `plan/status.md` updated: "Day 1 complete. Apple Developer enrollment in flight; FamilyControls entitlement submitted, awaiting review."

### Blockers possible
- Apple Developer Program approval >24h — Day 2 can still proceed with stubs, but the Xcode Cloud wiring slips.

---

## Day 2 — Project skeleton

### Morning
**Goal:** Xcode project + SPM packages compile empty; CLAUDE.md + plan/specs present; first "Hello AdKan" view renders in simulator.

Tasks:
1. Claude orchestrator requests: `/plugin install frontend-design@anthropics-claude-code`.
2. Founder types the `/plugin` command; confirms `ok`.
3. Scaffold Xcode project `AdKan.xcodeproj` with SPM packages per `/plan/05`. (Founder on Mac-less machine: claude authors the project files and `Package.swift` contents; founder opens in Xcode Cloud or a future Mac. Alternative: claude scripts the `.xcodeproj` via `xcodegen` spec file so the project is text-generable.)
4. Author `AdKanApp.swift`, `AppRoot/RootView.swift` — renders a blank screen with `Text(L10n.App.displayName)`.
5. Write the 20 initial `.xcstrings` keys from `/plan/07`.

### Afternoon
**Goal:** `ScreenTimeProvider` protocol + Stub + fixture catalog + contract tests green.

Tasks:
6. Write `App/ScreenTime/Provider/ScreenTimeProvider.swift` (protocol).
7. Write `StubScreenTimeProvider.swift` with all 5 fixtures.
8. Write `ScreenTimeFixture.swift` enum.
9. `qa-engineer` writes `ScreenTimeProviderContractTests.swift` FIRST — failing.
10. Make tests green against Stub.
11. GRDB main-app database migration 0001 (empty schema; just verifies pool opens and closes).

### End-of-day demo
- Build succeeds.
- `AdKan` launches in simulator, shows "AdKan / עד כאן" text in the device language.
- `xcrun xcodebuild test -scheme AdKan` reports Stub contract tests pass.

---

## Day 3 — Onboarding

### Morning
**Goal:** 5-question survey UI + navigation + local persistence.

Tasks:
1. Author `Features/Onboarding/Views/Survey01HoursView.swift` through `Survey05GoalView.swift`.
2. `SurveyViewModel` with state transitions.
3. `SurveyAnswer` enum + `survey_answers` GRDB table (migration 0002).
4. `qa-engineer` writes `SurveyViewModelTests` FIRST — failing.
5. Make tests green.

### Afternoon
**Goal:** Survey effects + Apple Sign-In + first Supabase call.

Tasks:
6. `SurveyEffectDispatcher` — apply each effect (PushSchedule, TopEnemy, GroupTemplate, GoalBaseline).
7. Apple Sign-In flow in `Backend/Auth/AppleSignInFlow.swift`.
8. `sign-up` Edge Function deployed to Supabase.
9. On survey completion: call `sign-up` → receive session JWT → persist.

### End-of-day demo
- Full onboarding flow works end-to-end in simulator against Stub + real Supabase.
- New row in `users` table visible in Supabase dashboard.
- `plan/status.md` updated.

---

## Day 4 — Leaderboard + realtime + push scaffold

### Morning
**Goal:** Leaderboard UI renders against fixture friends; realtime subscription live.

Tasks:
1. `Features/Leaderboard/Views/LeaderboardScreen.swift` + `FriendRowView.swift`.
2. `LeaderboardViewModel` — consumes `ScreenTimeProvider.todayTotalMinutes()`.
3. Supabase schema migrations 0001–0003 (users, friendships, daily_scores, leaderboard_for function).
4. `qa-engineer` writes `LeaderboardViewModelTests` FIRST.
5. Realtime subscription on `daily_scores` via `LeaderboardSubscription.swift`.

### Afternoon
**Goal:** Push notifications wired end-to-end.

Tasks:
6. Founder creates APNs `.p8` per `/plan/02 §apns-p8`.
7. Founder uploads `.p8` contents to Supabase secrets per `§supabase-secrets`.
8. Edge Function `send-push` deployed — signs ES256 JWT, posts to APNs.
9. Edge Function `calculate-rank-changes` deployed — diffs rank against previous snapshot.
10. `Features/PushBridge/PushTokenRegistrar.swift` — register APNs token, persist to `users.push_token`.

### End-of-day demo
- Leaderboard renders 1 real row (self).
- Test via Supabase dashboard: manually insert a `daily_scores` row for the user → leaderboard updates via realtime within seconds.
- Test push: invoke `send-push` from Supabase Studio → device receives localized notification.

---

## Day 5 — Paywall + receipt verification

### Morning
**Goal:** StoreKit 2 products configured; paywall UI rendered; sandbox purchases work.

Tasks:
1. Founder creates 3 IAP products in App Store Connect per `/specs/0003`:
   - `adkan.monthly.1290` (auto-renewable, 3-day intro)
   - `adkan.annual.69` (auto-renewable, 3-day intro)
   - `adkan.lifetime.99` (non-consumable)
2. `Features/Paywall/Views/PaywallScreen.swift` — 3 tiers, lifetime hero.
3. `Features/Paywall/Commerce/ProductCatalog.swift` — loads `Product.products(for: ids)`.
4. `TransactionObserver.swift` — long-lived listener for `Transaction.updates`.
5. `qa-engineer` writes `PaywallViewModelStoreKitTests` FIRST using StoreKitTest.
6. Make tests green.

### Afternoon
**Goal:** Receipt verification Edge Function + entitlement persistence.

Tasks:
7. Edge Function `validate-receipt` deployed.
8. `Features/Paywall/Commerce/ReceiptVerifier.swift` — calls Edge Function.
9. `entitlements` table + migration 0005.
10. Success path: purchase → client calls validate-receipt → server verifies → upserts entitlement → client updates `EnvironmentValues.entitlement`.
11. 4th-friend-paywall-trigger in `LeaderboardScreen.onInviteTapped` — check entitlement, present paywall if `.none`.

### End-of-day demo
- Sandbox purchase of annual tier in simulator → entitlement updates → paywall dismisses → user can invite 4th friend.
- Refund / cancel flow tested in sandbox: `Transaction.updates` revokes entitlement.

---

## Day 6 — Extension + analytics + polish

### Morning
**Goal:** `DeviceActivityMonitorExtension` target builds; App Group crumbs pipeline works.

Tasks:
1. Create Xcode target `DeviceActivityMonitorExtension`.
2. Add entitlement `com.apple.security.application-groups` = `group.com.taltalhayun.adkan` to both main app and extension.
3. Implement `DeviceActivityMonitorExtension.swift` (3 callbacks).
4. Implement `AppGroupCrumbWriter.swift` (raw sqlite3).
5. `AppGroupCrumbReader.swift` main-app side.
6. `DailyTotalAggregator.swift` computes `dailyTotalMinutes`.
7. `qa-engineer` writes `AppGroupCrumbRoundtripTests` FIRST (requires multi-target test setup).
8. Make tests green.

### Afternoon
**Goal:** PostHog + Sentry wired; permission banner; settings screen.

Tasks:
9. PostHog SDK integrated; events from `EventCatalog.swift`.
10. Sentry SDK integrated; dSYM upload script in Xcode Cloud post-build.
11. `PermissionCoordinator.swift` + `PermissionBanner.swift`.
12. `Features/Settings/SettingsScreen.swift` — language, retake, privacy, (DEBUG: fixture selector).
13. Founder recruits 3–5 IL TestFlight testers per `/plan/02 §testflight-testers`.

### End-of-day demo
- Full simulator walkthrough in both HE and EN.
- PostHog dashboard shows the 5-event funnel.
- Sentry shows one deliberately-crashed canary event.

---

## Day 7 — TestFlight + Friday recap

### Morning
**Goal:** First external TestFlight build; testers install and complete Tier-2 test plan.

Tasks:
1. Founder confirms App Store Connect app record + TestFlight group set up.
2. Xcode Cloud workflow `Build + Test + TestFlight` runs on push to `main`.
3. Build success → auto-upload → external testers receive invite emails.
4. First tester runs `/plan/08 §tier-2` test plan.

### Afternoon
**Goal:** Friday recap + IG-Story share + fix top tester-reported bugs.

Tasks:
5. `Features/FridayRecap/*` — weekly recap screen.
6. IG-Story share card generator (snapshot + `UIActivityViewController`).
7. `weekly-recap` Edge Function deployed with Friday 18:00 IL cron.
8. Triage tester reports. Fix P0/P1 bugs. Re-deploy.

### End-of-day demo
- TestFlight build live for 3–5 testers.
- First real `daily_scores` row from a tester appears in Supabase.
- Recap card shares to Instagram from a real iPhone.
- `plan/status.md` updated: **MVP complete. Ready for iteration based on tester feedback.**

---

## Cut list if time runs short

Priority order for cuts, highest-cut-first:

1. Friday recap UI polish (keep backend, ship minimal share card).
2. IG-Story share (use generic share sheet instead).
3. Viral-unlock trigger (leave the `invite_codes` table, punt the +7-day unlock logic to v1.1).
4. `DeviceActivityReport` extension (deferred to v1.1 per `/specs/0004 §out-of-scope`).
5. Settings language switcher (Settings can always detect system locale; manual switch is nice-to-have).
6. DEBUG fixture selector in Settings (dev-only; not shipped anyway).

**Do NOT cut:**
- Privacy boundary enforcement.
- TDD + test suite.
- Localization parity.
- Paywall 4th-friend trigger (the monetization core).
- Apple Sign-In flow.

---

## Pause cadence

Every 4–5 files written: orchestrator posts `plan/status.md` summary + awaits founder `continue`. This is non-negotiable — it's how founder stays informed without micromanaging.

Typical day: 3 pauses × 4 files = 12 files/day. That's ambitious; some days will be fewer.
