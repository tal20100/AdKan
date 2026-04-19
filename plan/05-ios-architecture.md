# Plan 05 — iOS Architecture

SPM package graph, target layout, module boundaries, and folder structure for the AdKan Xcode project.

**Source ADRs:** 0001 (state management), 0002 (local storage), 0005 (ScreenTime abstraction).

---

## Xcode project layout

```
AdKan.xcodeproj
├── AdKan (app target, iOS 16.0+)
├── AdKanTests (unit + snapshot)
├── AdKanUITests (XCUITest)
├── DeviceActivityMonitorExtension (app extension, iOS 16.0+)
└── DeviceActivityMonitorExtensionTests
```

Two targets for the extension (`DeviceActivityMonitorExtension`) and main app share code via SPM packages — never via "shared target membership," which tends to accidentally link heavy SDKs into the extension.

---

## SPM package graph

```
AdKan (app)
├── AdKanCore                — currency models, date utils, Codable infra
├── AdKanDesignSystem        — colors, typography, SF Symbol catalog, AdKan-specific components
├── AdKanLocalization        — .xcstrings resource + LocalizedStringKey helpers
├── AdKanScreenTime          — ScreenTimeProvider protocol + Stub + Real + Aggregator
│   └── AdKanAppGroupShared  — shared SQLite crumbs schema (also linked by extension)
├── AdKanFeatures
│   ├── Onboarding           — 5-question survey
│   ├── Leaderboard          — home + friend cards + realtime
│   ├── Paywall              — StoreKit 2 + 3-tier paywall
│   ├── Settings             — fixture selector, retake, account, privacy
│   └── FridayRecap          — weekly recap + IG-Story share
├── AdKanBackend             — Supabase client wrapper, typed RPC calls
├── AdKanAnalytics           — PostHog + Sentry thin wrappers
└── AdKanPushBridge          — APNs token registration handshake

DeviceActivityMonitorExtension (extension)
└── AdKanAppGroupShared      — ONLY shared package; raw sqlite3 writer
```

Extension target MUST NOT link: `AdKanCore`, `AdKanDesignSystem`, `AdKanLocalization`, `AdKanFeatures`, `AdKanBackend`, `AdKanAnalytics`, `AdKanPushBridge`, `AdKanScreenTime` (except the crumbs-shared subset).

Rule enforcement: `architecture-auditor` grep at PR time checks `DeviceActivityMonitorExtension/Package.swift` dependencies.

---

## Folder structure on disk

```
/AdKan
├── App/                                 # main app
│   ├── AdKanApp.swift                   # @main, environment injection
│   ├── AppRoot/
│   │   ├── RootView.swift               # splash → onboarding || leaderboard
│   │   ├── Router.swift                 # @Observable navigation
│   │   └── AppDependencies.swift        # DI container
│   ├── Core/                            # AdKanCore package sources
│   │   ├── Models/
│   │   │   ├── User.swift
│   │   │   ├── Entitlement.swift
│   │   │   ├── Friendship.swift
│   │   │   ├── DailyScore.swift
│   │   │   └── SurveyAnswer.swift
│   │   ├── Infra/
│   │   │   ├── Database.swift           # GRDB pool
│   │   │   ├── KeychainStore.swift      # DB encryption key
│   │   │   └── ISO8601.swift
│   │   └── Utilities/
│   ├── ScreenTime/                      # AdKanScreenTime package
│   │   ├── Provider/
│   │   │   ├── ScreenTimeProvider.swift
│   │   │   ├── RealScreenTimeProvider.swift
│   │   │   ├── StubScreenTimeProvider.swift
│   │   │   └── AuthorizationStatus.swift
│   │   ├── Authorization/
│   │   │   ├── PermissionCoordinator.swift
│   │   │   └── PermissionBanner.swift
│   │   ├── Aggregator/
│   │   │   ├── AppGroupCrumbReader.swift
│   │   │   └── DailyTotalAggregator.swift
│   │   └── Fixtures/
│   │       ├── ScreenTimeFixture.swift
│   │       └── FixtureSelector.swift    # DEBUG-only Settings row
│   ├── AppGroupShared/                  # AdKanAppGroupShared package
│   │   └── CrumbSchema.swift            # CREATE TABLE, column names
│   ├── DesignSystem/                    # AdKanDesignSystem package
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   ├── Icons.swift
│   │   ├── Components/
│   │   │   ├── AdKanButton.swift
│   │   │   ├── AdKanCard.swift
│   │   │   └── AvatarView.swift         # stateful mascot
│   │   └── Layout/
│   │       └── RTLMirroring.swift
│   ├── Localization/                    # AdKanLocalization package
│   │   ├── Localizable.xcstrings
│   │   └── L10n.swift                   # typed keys
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── Views/
│   │   │   │   ├── Survey01HoursView.swift
│   │   │   │   ├── Survey02BiggestHitView.swift
│   │   │   │   ├── Survey03TopEnemyView.swift
│   │   │   │   ├── Survey04CrewView.swift
│   │   │   │   └── Survey05GoalView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── SurveyViewModel.swift
│   │   │   └── Effects/
│   │   │       └── SurveyEffectDispatcher.swift
│   │   ├── Leaderboard/
│   │   │   ├── Views/
│   │   │   │   ├── LeaderboardScreen.swift
│   │   │   │   ├── FriendRowView.swift
│   │   │   │   └── InviteBarView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── LeaderboardViewModel.swift
│   │   │   └── Realtime/
│   │   │       └── LeaderboardSubscription.swift
│   │   ├── Paywall/
│   │   │   ├── Views/
│   │   │   │   └── PaywallScreen.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── PaywallViewModel.swift
│   │   │   └── Commerce/
│   │   │       ├── TransactionObserver.swift
│   │   │       ├── ProductCatalog.swift
│   │   │       └── ReceiptVerifier.swift
│   │   ├── FridayRecap/
│   │   │   └── (view + share card)
│   │   └── Settings/
│   │       ├── SettingsScreen.swift
│   │       ├── RetakeSurveyRow.swift
│   │       └── DevFixtureSelectorRow.swift  # DEBUG only
│   ├── Backend/                         # AdKanBackend package
│   │   ├── SupabaseClient.swift
│   │   ├── Auth/
│   │   │   └── AppleSignInFlow.swift
│   │   └── RPC/
│   │       ├── SignUpRPC.swift
│   │       ├── LeaderboardRPC.swift
│   │       ├── DailySyncRPC.swift
│   │       └── ViralUnlockRPC.swift
│   ├── Analytics/                       # AdKanAnalytics package
│   │   ├── PostHogAnalytics.swift
│   │   ├── SentryClient.swift
│   │   └── EventCatalog.swift           # enum of all allowed event names
│   └── PushBridge/                      # AdKanPushBridge package
│       ├── PushTokenRegistrar.swift
│       └── PushHandler.swift
├── DeviceActivityMonitorExtension/      # separate Xcode target
│   ├── DeviceActivityMonitorExtension.swift
│   ├── AppGroupCrumbWriter.swift        # raw sqlite3
│   ├── Info.plist
│   └── DeviceActivityMonitorExtension.entitlements
├── AdKanTests/
│   ├── Core/
│   ├── ScreenTime/
│   ├── Features/
│   │   ├── Onboarding/
│   │   ├── Leaderboard/
│   │   ├── Paywall/
│   │   └── FridayRecap/
│   └── Snapshots/
├── AdKanUITests/
│   └── OnboardingFlowUITests.swift
├── Package.swift                        # top-level if fully SPM; else *.xcodeproj with SPM packages under Packages/
└── config/
    ├── app-identity.json                # (already written Batch 1)
    └── mac-bridge.json                  # gitignored
```

---

## Key architectural rules

### 1. Environment as DI
All cross-cutting dependencies flow through SwiftUI Environment, never singletons:

```swift
extension EnvironmentValues {
    @Entry var currentUser: User?
    @Entry var entitlement: Entitlement = .none
    @Entry var screenTimeProvider: any ScreenTimeProvider = StubScreenTimeProvider.default
    @Entry var supabase: SupabaseClient = .shared
    @Entry var analytics: any Analytics = StubAnalytics()
}
```

Exceptions — two singletons allowed, reason documented:
- `TransactionObserver.shared` — must live across the whole app lifetime to catch `Transaction.updates` the instant StoreKit emits them.
- `AppGroupCrumbWriter.shared` — extension target's single write path; initialized once per extension invocation.

### 2. View Models are `@Observable` + iOS 16 fallback
`@AdKanObservable` property-wrapper macro shim (written Day 2) resolves to `@Observable` on iOS 17 and `ObservableObject`-conforming class on iOS 16. Views use `@State` (iOS 17) or `@StateObject` (iOS 16) accordingly. Discussed in ADR 0001.

### 3. No hard-coded strings in Swift
Every user-visible string goes through `L10n.xxx` resolving to `.xcstrings` keyed entries. Enforced by a grep gate in `pre-commit-localization-gate.mjs` extension: any Swift file containing a string literal that would likely render to a user — pattern matches any `Text("...")` or `.navigationTitle("...")` where the string isn't `L10n.<key>` — fails the hook (warn-level; `localization-lead` decides block vs. allow).

### 4. No hard-coded colors outside DesignSystem
`Color(hex:)` or `Color(red:green:blue:)` is banned outside `AdKanDesignSystem/Colors.swift`. Enforced by grep gate.

### 5. Navigation via NavigationStack + Router
`Router` is a single `@Observable` object injected at root. No `NavigationLink(destination:)` with a view literal — always `.navigationDestination(for: Route.self)` with a `Route` enum.

### 6. No Combine publishers in new code
Observation (iOS 17) handles reactivity. iOS 16 fallback uses `ObservableObject` + `@Published`. Combine custom publishers are a `code-smell` unless bridging third-party callback APIs.

### 7. Error handling
Two error kinds:
- `AdKanError` enum — user-facing, localized messages, shown via `AlertState`.
- Internal `Error` — thrown, logged to Sentry (sanitized, no payload echoes).

No empty `catch { }`. Ever. `try?` only in UI gate paths where a nil result is semantically acceptable.

### 8. Async/await everywhere
No callback-based APIs in new code. `withCheckedThrowingContinuation` bridges StoreKit / FamilyControls where their async variants don't exist.

---

## iOS 16 vs 17 branching

Minimum: iOS 16.0. Prefer APIs available in iOS 16 unless iOS 17 gives material benefit. Where iOS 17 wins meaningfully:
- `@Observable` macro — use with iOS 16 fallback (above).
- `.scrollTargetBehavior(.paging)` — polish only; gracefully degrades.
- `ContentUnavailableView` — polish only; custom empty-state view on iOS 16.

Never: `SwiftData` (rejected in ADR 0002), `Tips` framework, `.scrollPosition(id:)` without fallback.

---

## Build configurations

| Config | Scheme | Provider | Analytics | Signing |
|---|---|---|---|---|
| Debug (sim) | `AdKan (Debug)` | StubScreenTimeProvider | StubAnalytics | Development |
| Debug (device) | `AdKan (Debug)` | Real (if entitlement + permission) else Stub | PostHog dev project | Development |
| Release (TestFlight) | `AdKan (Release)` | RealScreenTimeProvider | PostHog production | Distribution |
| Release (App Store) | `AdKan (Release)` | RealScreenTimeProvider | PostHog production | Distribution |

The stub→real cutover is Day-4-or-later after FamilyControls entitlement approval. Until approval: Release uses Stub too, with a DEBUG banner that reads "Demo mode — awaiting entitlement." Prevents false real-data demos to testers.

---

## Files and responsibilities during Build

Not all files above are written in the 7-day Build. The MVP subset:
- `AppRoot/*` — Day 2
- `Core/Infra/Database.swift` — Day 2
- `ScreenTime/Provider/*`, `Fixtures/*` — Day 2
- `Localization/Localizable.xcstrings` + 20 initial keys — Day 2
- `Features/Onboarding/*` — Day 3
- `Features/Leaderboard/*` + realtime — Day 4
- `Backend/Auth/AppleSignInFlow.swift`, `Backend/RPC/*` — Day 3-4
- `Features/Paywall/*` — Day 5
- `Analytics/*`, `PushBridge/*` — Day 5-6
- `DeviceActivityMonitorExtension/*` — Day 6 (real provider only — stub path doesn't need the extension running)
- `Features/FridayRecap/*` — Day 7 or v1.1 if time runs short

Per `/plan/09-seven-day-execution.md`.
