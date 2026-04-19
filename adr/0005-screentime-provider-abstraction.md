# ADR 0005 — ScreenTime Provider Abstraction

**Status:** Accepted.
**Date:** 2026-04-18.
**Deciders:** architecture-auditor, ios-engineer, qa-engineer.

## Context

AdKan's core product depends on Apple's `FamilyControls` / `DeviceActivity` / `ManagedSettings` frameworks. Three hard realities:

1. These frameworks do not work in the iOS Simulator — `AuthorizationCenter.shared.requestAuthorization(.individual)` fails with error 3 on simulator. Physical iPhone + paid Apple Developer Program + registered bundle ID required.
2. The founder does not currently have a physical iPhone. (See `/plan/00-overview.md` kill-gate #1.)
3. The `FamilyControls` entitlement takes 1–30+ days for Apple to approve after submission. Code that calls these APIs unconditionally will not compile + run on TestFlight until approval lands.

If we couple view models, aggregator logic, and UI directly to `DeviceActivity` and `FamilyControls`, the 80% of the app that doesn't depend on real device data (onboarding, leaderboard UI, paywall, settings, localization, navigation) becomes untestable and undemo-able until a physical device + approved entitlement are both ready. That is an unacceptable blocker for a solo-dev 7-day sprint.

## Decision

Introduce a single protocol — `ScreenTimeProvider` — as the ONLY abstraction over Apple's Screen Time stack.

- `RealScreenTimeProvider` — FamilyControls-backed. Only compiled into Release + TestFlight builds. Only exercises the API surface when running on a physical device with approved entitlement.
- `StubScreenTimeProvider` — returns deterministic fixtures (`low`, `goalHit`, `slipping`, `spiraling`, `zero`). Used in: simulator, all XCTest/XCUITest targets, all snapshot tests, Debug builds by default, PR previews.

Injection via SwiftUI `Environment`:
```swift
extension EnvironmentValues {
    @Entry var screenTimeProvider: any ScreenTimeProvider = StubScreenTimeProvider.default
}
```

Every view, view model, and aggregator **MUST** consume the provider through the environment. Direct imports of `FamilyControls` / `DeviceActivity` / `ManagedSettings` are allowed ONLY inside:
- `App/ScreenTime/Provider/RealScreenTimeProvider.swift`
- `App/ScreenTime/Extension/DeviceActivityMonitorExtension/*`

The `architecture-auditor` agent enforces this with a grep gate in the pre-commit hook.

## Alternatives considered

### Conditional `#if targetEnvironment(simulator)` scattered throughout code
- **Pros:** no extra protocol, no DI boilerplate.
- **Cons:** compile-time bifurcation scatters device-specific assumptions across the codebase. Testing becomes untenable; you can't substitute fixtures at test time, only at compile time. Every view model carries dead branches.

Rejected — unmaintainable and untestable at feature scale.

### Wrap only authorization; call DeviceActivity directly everywhere else
- **Pros:** smaller abstraction.
- **Cons:** still forces real-device-only development for the 80% of the app that just needs `Int todayMinutes` and `Int yesterdayMinutes`. Leaderboard UI remains untestable.

Rejected — too narrow to deliver the device-less development guarantee.

### Use Apple's `DeviceActivityReport` with mock data
- Not a mock surface; `DeviceActivityReport` is a read-only report extension, not a substitutable dependency.

Rejected — not what it's for.

## Contract

```swift
protocol ScreenTimeProvider: Sendable {
    var authorizationStatus: AuthorizationStatus { get async }
    func requestAuthorization() async throws
    func todayTotalMinutes() async -> Int
    func yesterdayTotalMinutes() async -> Int
    func isPermissionStillGranted() async -> Bool
}

enum AuthorizationStatus: Sendable {
    case notDetermined
    case denied
    case approved
}
```

The contract is **deliberately minimal**. Every field MUST be derivable from the allowed export payload of ADR 0004 (`dailyTotalMinutes: Int`). No per-app data. No per-category data. No tokens. No raw events. If a future feature needs more, that is a signal to reopen ADR 0004 — not to widen this protocol.

## Fixture catalog (StubScreenTimeProvider)

| Fixture | todayMinutes | yesterdayMinutes | Narrative |
|---|---|---|---|
| `zero` | 0 | 0 | Brand-new user, day zero. |
| `low` | 80 | 110 | Under goal, trending down. |
| `goalHit` | 120 | 130 | At the Q5 goal. |
| `slipping` | 180 | 140 | 50 min over goal; slight regression. |
| `spiraling` | 420 | 380 | 3× goal, sustained. Avatar reaches `spiraling` state. |

Fixture selection in Debug builds via `/App/ScreenTime/Fixtures/FixtureSelector.swift` — a DEBUG-gated row in Settings. Defaults to `goalHit` so previews render a "normal success" state.

## Build configurations

- Debug (simulator or device) → `StubScreenTimeProvider` by default. Flip to real via Settings → Developer → `Use real FamilyControls`.
- Release + TestFlight + App Store → `RealScreenTimeProvider` unconditionally. A compile-time assertion in `AdKanApp.swift` prevents accidental stub shipping.

```swift
#if !DEBUG
  precondition(
    ProcessInfo.processInfo.environment["ADKAN_USE_STUB_SCREEN_TIME_PROVIDER"] == nil,
    "Stub provider must never ship in Release"
  )
#endif
```

## Testing strategy

`ScreenTimeProviderContractTests` — a single XCTest suite parameterized over `RealScreenTimeProvider` and `StubScreenTimeProvider`. Both must satisfy:

1. `authorizationStatus` eventually resolves to one of the three enum cases.
2. `todayTotalMinutes()` returns 0...1439.
3. `yesterdayTotalMinutes()` returns 0...1439.
4. `isPermissionStillGranted()` returns `true` iff `authorizationStatus == .approved`.

Real-provider assertions that require a device are skipped when `XCTSkipIf(isSimulator)`. Stub-provider assertions run always.

## Consequences

**Positive:**
- 80% of the app ships, demos, and tests without a physical iPhone or approved entitlement.
- The `qa-engineer` can write UI + view-model tests Day 1 against deterministic fixtures.
- Snapshot tests are stable across runs (no real time, no real device state).
- When the entitlement lands, flipping the DI is a one-line change — no feature rewrites.
- Clear architectural boundary: anyone grepping for `DeviceActivity` sees exactly two files and reviews them carefully.

**Negative:**
- One extra indirection for every Screen Time call.
- Fixtures must be kept meaningful — if we add a new derived metric, we add it to every fixture or tests will drift.
- Some classes of real-device bugs (permission revocation timing, token churn) cannot be caught by stubs. Mitigated by the Tier-2 TestFlight test plan in `/plan/08-testing-strategy.md`.
