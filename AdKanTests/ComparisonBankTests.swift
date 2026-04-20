import XCTest
@testable import AdKan

final class ComparisonBankTests: XCTestCase {

    func test_allComparisonsProduceNonEmptyText() {
        for template in ComparisonBank.all {
            let resolved = template.resolve(savedMinutes: 120)
            XCTAssertFalse(resolved.textEN.isEmpty, "EN text empty for icon \(resolved.icon)")
            XCTAssertFalse(resolved.textHE.isEmpty, "HE text empty for icon \(resolved.icon)")
        }
    }

    func test_randomReturnsRequestedCount() {
        let results = ComparisonBank.random(savedMinutes: 60, count: 3)
        XCTAssertEqual(results.count, 3)
    }

    func test_randomReturnsEmptyForZeroMinutes() {
        let results = ComparisonBank.random(savedMinutes: 0, count: 3)
        XCTAssertTrue(results.isEmpty)
    }

    func test_everestMathIsCorrect() {
        let template = ComparisonBank.all.first { $0.icon == "🏔️" }!
        let resolved = template.resolve(savedMinutes: 480) // 8 hours = summit push
        XCTAssertTrue(resolved.textEN.contains("100"), "8h should be ~100% of summit push, got: \(resolved.textEN)")
    }

    func test_issOrbitMathIsCorrect() {
        let template = ComparisonBank.all.first { $0.icon == "🛸" }!
        let resolved = template.resolve(savedMinutes: 92) // one orbit
        XCTAssertTrue(resolved.textEN.contains("1.0"), "92min should be ~1 orbit, got: \(resolved.textEN)")
    }

    func test_heartbeatMathIsCorrect() {
        let template = ComparisonBank.all.first { $0.icon == "💓" }!
        let resolved = template.resolve(savedMinutes: 1) // 1 min = ~72 beats
        XCTAssertTrue(resolved.textEN.contains("72"), "1min should be 72 beats, got: \(resolved.textEN)")
    }

    func test_localeSelection() {
        let resolved = ComparisonBank.all.first!.resolve(savedMinutes: 60)
        XCTAssertFalse(resolved.text(locale: "en").isEmpty)
        XCTAssertFalse(resolved.text(locale: "he").isEmpty)
        XCTAssertNotEqual(resolved.text(locale: "en"), resolved.text(locale: "he"))
    }
}
