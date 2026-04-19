# ADR 0001 — State Management

**Status:** Accepted.
**Date:** 2026-04-18.
**Deciders:** architecture-auditor, ios-engineer.

## Context

AdKan is a reactive iOS app with several independent stateful flows: onboarding, leaderboard realtime subscription, paywall, permissions, entitlements. Solo founder; fast iteration priority. iOS 16 minimum deployment target. Two serious candidates:

- **The Composable Architecture (TCA)** — predictable Redux-ish, exhaustive testing, feature-module scaling.
- **Observation framework + `@Observable`** — Apple's native, minimal ceremony, iOS 17+ first-class.

## Decision

Use **Observation + `@Observable`** on iOS 17, with the `Combine` + `ObservableObject` fallback path on iOS 16.

Concretely:
- View models are marked `@Observable` (iOS 17) or conform to `ObservableObject` (iOS 16 fallback). We use a `@propertyWrapper` shim `@AdKanObservable` that resolves to the right underlying type at compile time.
- SwiftUI views consume view models via `@State` (iOS 17 native) or `@StateObject` (iOS 16).
- No centralized store / reducer. Each feature module owns its own view models.
- Navigation via `@Observable` router objects + SwiftUI `NavigationStack`.

## Alternatives considered

### TCA
- **Pros:** exhaustive testing, predictable reducer semantics, feature-module scaling, strong community, good for teams.
- **Cons:** learning-curve cost for solo founder, 10k+ LOC overhead in compile time, pulls in `swift-case-paths` + `swift-identified-collections` + `swift-dependencies`, steeper SwiftUI integration, iOS 16 support requires backport shims.

Rejected because: solo dev velocity dominates over testability-at-scale for a 7-day MVP. Revisit at v2.

### Combine + ObservableObject alone (no Observation)
- **Pros:** works uniformly on iOS 16 and 17.
- **Cons:** unnecessarily coarse re-rendering on iOS 17, misses Observation's per-property granularity, looks dated.

Rejected because: iOS 17 is the vast majority of our target population; we want the better rendering story there.

### SwiftData's model macros for state
- Not a state-management tool — rejected as out of scope.

## Consequences

**Positive:**
- Fast to write, minimal boilerplate.
- Native Apple APIs — no external dependency risk.
- SwiftUI integration is seamless.
- Previews work trivially with fixture `@Observable` view models.

**Negative:**
- Tests cannot exhaustively verify state-transition graphs the way TCA enables. Mitigation: snapshot testing + explicit `LeaderboardViewModelTests` / `PaywallViewModelTests` covering the paths we care about.
- No built-in time-travel debugger. Mitigation: PostHog breadcrumbs + Sentry crumbs in view model methods.

## Implementation notes

- All view models live in `App/Features/<feature>/ViewModels/`.
- Shared state (current user, entitlement, permission status) lives in SwiftUI Environment:
  ```swift
  extension EnvironmentValues {
      @Entry var currentUser: User?
      @Entry var entitlement: Entitlement = .none
      @Entry var screenTimeProvider: any ScreenTimeProvider = StubScreenTimeProvider.default
  }
  ```
- No singletons except `TransactionObserver.shared` and `AppGroupCrumbWriter.shared` (both have non-negotiable lifecycle reasons).
