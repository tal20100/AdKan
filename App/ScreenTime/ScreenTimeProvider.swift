import SwiftUI

// MARK: - Protocol

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

// MARK: - Environment key

private struct ScreenTimeProviderKey: EnvironmentKey {
    static let defaultValue: any ScreenTimeProvider = StubScreenTimeProvider.goalHit
}

extension EnvironmentValues {
    var screenTimeProvider: any ScreenTimeProvider {
        get { self[ScreenTimeProviderKey.self] }
        set { self[ScreenTimeProviderKey.self] = newValue }
    }
}

// MARK: - Stub implementation

struct StubScreenTimeProvider: ScreenTimeProvider {
    let fixture: ScreenTimeFixture

    var authorizationStatus: AuthorizationStatus {
        get async { .approved }
    }

    func requestAuthorization() async throws {}

    func todayTotalMinutes() async -> Int {
        fixture.todayMinutes
    }

    func yesterdayTotalMinutes() async -> Int {
        fixture.yesterdayMinutes
    }

    func isPermissionStillGranted() async -> Bool {
        true
    }

    static let zero = StubScreenTimeProvider(fixture: .zero)
    static let low = StubScreenTimeProvider(fixture: .low)
    static let goalHit = StubScreenTimeProvider(fixture: .goalHit)
    static let slipping = StubScreenTimeProvider(fixture: .slipping)
    static let spiraling = StubScreenTimeProvider(fixture: .spiraling)
}

// MARK: - Fixtures

struct ScreenTimeFixture: Sendable {
    let name: String
    let todayMinutes: Int
    let yesterdayMinutes: Int

    static let zero = ScreenTimeFixture(name: "zero", todayMinutes: 0, yesterdayMinutes: 0)
    static let low = ScreenTimeFixture(name: "low", todayMinutes: 80, yesterdayMinutes: 110)
    static let goalHit = ScreenTimeFixture(name: "goalHit", todayMinutes: 95, yesterdayMinutes: 110)
    static let slipping = ScreenTimeFixture(name: "slipping", todayMinutes: 180, yesterdayMinutes: 140)
    static let spiraling = ScreenTimeFixture(name: "spiraling", todayMinutes: 420, yesterdayMinutes: 380)

    static let all: [ScreenTimeFixture] = [.zero, .low, .goalHit, .slipping, .spiraling]
}
