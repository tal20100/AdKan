# Spec 0004 — Privacy and Permissions (implementation)

**Implements:** `/prd/0004-privacy-and-permissions.md`.
**Owner:** ios-engineer + privacy-engineer (veto). **Reviewers:** security-reviewer (veto), qa-engineer.

## Module layout

```
App/ScreenTime/
├── Provider/
│   ├── ScreenTimeProvider.swift            # protocol; the ONLY abstraction over FamilyControls
│   ├── RealScreenTimeProvider.swift        # FamilyControls-backed; only runs on device
│   └── StubScreenTimeProvider.swift        # fixtures; used in simulator + all tests
├── Authorization/
│   ├── PermissionCoordinator.swift         # pre-prompt, requestAuthorization, re-check
│   └── PermissionBanner.swift              # friendly re-enable UX for revoked permission
├── Extension/
│   └── DeviceActivityMonitorExtension/     # separate target, ≤500 LOC, SDK-free
│       ├── DeviceActivityMonitorExtension.swift
│       └── AppGroupCrumbWriter.swift       # raw sqlite3 writes to shared SQLite
├── Aggregator/
│   ├── AppGroupCrumbReader.swift           # main-app side, reads crumbs left by extension
│   └── DailyTotalAggregator.swift          # computes dailyTotalMinutes from crumbs
└── Fixtures/
    ├── ScreenTimeFixture.swift             # fixture cases: low, goalHit, slipping, spiraling, zero
    └── FixtureSelector.swift               # DEBUG-only Settings row
```

## `ScreenTimeProvider` protocol

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

Every UI and view model binds to this protocol via SwiftUI Environment:
```swift
extension EnvironmentValues {
    @Entry var screenTimeProvider: any ScreenTimeProvider = StubScreenTimeProvider.default
}
```

Production builds (Release) inject `RealScreenTimeProvider`. Debug builds and simulator inject `StubScreenTimeProvider` by default; fixture selectable via `FixtureSelector` in Settings.

## `StubScreenTimeProvider`

```swift
final class StubScreenTimeProvider: ScreenTimeProvider {
    static let `default` = StubScreenTimeProvider(fixture: .goalHit)
    var fixture: ScreenTimeFixture

    var authorizationStatus: AuthorizationStatus { get async { .approved } }
    func requestAuthorization() async throws {}
    func todayTotalMinutes() async -> Int { fixture.todayMinutes }
    func yesterdayTotalMinutes() async -> Int { fixture.yesterdayMinutes }
    func isPermissionStillGranted() async -> Bool { true }
}

enum ScreenTimeFixture {
    case low           // 80m today, trending down
    case goalHit       // at Q5 goal
    case slipping      // goal + 30m
    case spiraling     // 3x goal for 3 days
    case zero          // new user

    var todayMinutes: Int { ... }
    var yesterdayMinutes: Int { ... }
}
```

## `RealScreenTimeProvider`

```swift
import FamilyControls
import DeviceActivity
import ManagedSettings

final class RealScreenTimeProvider: ScreenTimeProvider {
    private let center = AuthorizationCenter.shared

    var authorizationStatus: AuthorizationStatus {
        get async {
            switch await center.authorizationStatus {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .approved: return .approved
            @unknown default: return .notDetermined
            }
        }
    }

    func requestAuthorization() async throws {
        try await center.requestAuthorization(for: .individual)
    }

    func todayTotalMinutes() async -> Int {
        await AppGroupCrumbReader.shared.todayMinutes()
    }

    func yesterdayTotalMinutes() async -> Int {
        await AppGroupCrumbReader.shared.yesterdayMinutes()
    }

    func isPermissionStillGranted() async -> Bool {
        await authorizationStatus == .approved
    }
}
```

## `DeviceActivityMonitorExtension`

Separate target. Memory budget: ≤4 MB (well under Jetsam 6 MB). No external SDKs (no Sentry, no PostHog, no Supabase, no GRDB).

```swift
import DeviceActivity
import ManagedSettings
import SQLite3  // system library, not an SPM package

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        AppGroupCrumbWriter.shared.appendCrumb(.intervalStart(activity: activity.rawValue, at: Date()))
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        AppGroupCrumbWriter.shared.appendCrumb(.intervalEnd(activity: activity.rawValue, at: Date()))
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        AppGroupCrumbWriter.shared.appendCrumb(.threshold(event: event.rawValue, at: Date()))
    }
}
```

## `AppGroupCrumbWriter` (raw sqlite3)

Uses the system `sqlite3` C library directly — no GRDB, no ORM. Just prepared-statement inserts. Target SQLite file: `<AppGroupContainer>/adkan-extension-crumbs.db`, WAL mode enabled for concurrent main-app reads.

```swift
final class AppGroupCrumbWriter {
    static let shared = AppGroupCrumbWriter()
    private var db: OpaquePointer?

    init() {
        let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.taltalhayun.adkan")!
            .appendingPathComponent("adkan-extension-crumbs.db")
        sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
        createTableIfNeeded()
    }

    func appendCrumb(_ crumb: Crumb) {
        let sql = "INSERT INTO crumbs (kind, payload, timestamp) VALUES (?, ?, ?)"
        // prepare, bind, step, finalize
    }
}
```

## `DailyTotalAggregator`

Main-app side. On every foreground:
1. Read crumbs from shared SQLite.
2. Aggregate into `dailyTotalMinutes` for today and yesterday.
3. Feed back into `ScreenTimeProvider.todayTotalMinutes()` / `yesterdayTotalMinutes()`.
4. Trigger `DailySyncUploader` to upload yesterday's total (if not already synced).

## App Group setup

- Entitlement `com.apple.security.application-groups` added to both main app and extension target.
- Group ID: `group.com.taltalhayun.adkan`. Registered in Apple Developer portal.
- Founder-action to enable: `/plan/02-infrastructure-setup.md` §app-group-setup.

## Permission pre-prompt UX

See PRD 0004 for copy. Implementation:
- Pre-prompt is an in-app SwiftUI sheet, not a UIAlertController.
- Two buttons: `הבנתי | Got it` (continues to system dialog) and `דלג | Skip` (enters manual-entry mode).
- NEVER auto-request on launch — always user-initiated via the first tap on "view my usage."

## Daily permission re-check

```swift
@Observable
final class PermissionCoordinator {
    var permissionState: AuthorizationStatus = .notDetermined

    func checkOnForeground(provider: any ScreenTimeProvider) async {
        let current = await provider.authorizationStatus
        if permissionState == .approved && current != .approved {
            // revoked — show banner
            await showReEnableBanner()
        }
        permissionState = current
    }
}
```

## Tests

- `ScreenTimeProviderContractTests` — run the same test suite against both `RealScreenTimeProvider` and `StubScreenTimeProvider`. Protocol contract must be satisfied by both.
- `StubScreenTimeProviderFixtureTests` — each fixture returns expected `todayMinutes` / `yesterdayMinutes`.
- `AppGroupCrumbRoundtripTests` — write crumbs from extension test target, read from main app test target, assert aggregation.
- `PermissionCoordinatorRevocationTests` — simulate approved → denied transition, assert banner shown.

## Out of scope for v1

- Manual-entry-mode UX polish (minimum-viable in v1).
- `DeviceActivityReportExtension` (read-only reports) — deferred to v1.1.
- `ShieldConfiguration` extension — needed for Premium app-blocking. Scaffolded but feature-flagged off in v1.
- Differential-privacy noise on aggregated minutes.
