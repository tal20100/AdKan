import XCTest
@testable import AdKan

final class ScreenTimeProviderContractTests: XCTestCase {

    func test_stub_todayMinutes_inValidRange() async {
        for fixture in ScreenTimeFixture.all {
            let provider = StubScreenTimeProvider(fixture: fixture)
            let minutes = await provider.todayTotalMinutes()
            XCTAssertTrue((0...1439).contains(minutes), "\(fixture.name): \(minutes) out of range")
        }
    }

    func test_stub_yesterdayMinutes_inValidRange() async {
        for fixture in ScreenTimeFixture.all {
            let provider = StubScreenTimeProvider(fixture: fixture)
            let minutes = await provider.yesterdayTotalMinutes()
            XCTAssertTrue((0...1439).contains(minutes), "\(fixture.name): \(minutes) out of range")
        }
    }

    func test_stub_authorizationStatus_isApproved() async {
        let provider = StubScreenTimeProvider.goalHit
        let status = await provider.authorizationStatus
        XCTAssertEqual(status, .approved)
    }

    func test_stub_permissionStillGranted() async {
        let provider = StubScreenTimeProvider.goalHit
        let granted = await provider.isPermissionStillGranted()
        XCTAssertTrue(granted)
    }

    func test_fixtures_haveExpectedValues() async {
        let zero = StubScreenTimeProvider.zero
        XCTAssertEqual(await zero.todayTotalMinutes(), 0)
        XCTAssertEqual(await zero.yesterdayTotalMinutes(), 0)

        let goalHit = StubScreenTimeProvider.goalHit
        XCTAssertEqual(await goalHit.todayTotalMinutes(), 120)

        let spiraling = StubScreenTimeProvider.spiraling
        XCTAssertEqual(await spiraling.todayTotalMinutes(), 420)
    }
}
