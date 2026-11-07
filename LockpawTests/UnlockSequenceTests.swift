import XCTest
@testable import Lockpaw

final class UnlockSequenceTests: XCTestCase {
    private let down = 125, up = 126, x = 7, s = 1, a = 0

    private func matcher(timeout: TimeInterval = 5) -> SequenceMatcher {
        SequenceMatcher(desktop: [down, up, down, up, x], screensaver: [down, up, down, up, s], timeout: timeout)
    }

    func testDefaultsAreValidAndDistinct() {
        XCTAssertTrue(UnlockSequence.isValid(UnlockSequence.defaultDesktop))
        XCTAssertTrue(UnlockSequence.isValid(UnlockSequence.defaultScreensaver))
        XCTAssertNil(UnlockSequence.conflict(desktop: UnlockSequence.defaultDesktop, screensaver: UnlockSequence.defaultScreensaver))
    }

    func testWholeSequenceMatchesAndNothingShorterDoes() {
        var m = matcher()
        XCTAssertNil(m.feed(keyCode: down))
        XCTAssertNil(m.feed(keyCode: up))
        XCTAssertNil(m.feed(keyCode: down))
        XCTAssertNil(m.feed(keyCode: up))
        XCTAssertEqual(m.feed(keyCode: x), .desktop)
    }

    func testSharedPrefixResolvesOnTheLastKey() {
        var m = matcher()
        for code in [down, up, down, up] { XCTAssertNil(m.feed(keyCode: code)) }
        XCTAssertEqual(m.feed(keyCode: s), .screensaver)
    }

    func testWrongKeyRestarts() {
        var m = matcher()
        for code in [down, up, down] { _ = m.feed(keyCode: code) }
        XCTAssertNil(m.feed(keyCode: a))
        for code in [up, x] { XCTAssertNil(m.feed(keyCode: code)) }
        // A fresh full sequence still works afterwards.
        for code in [down, up, down, up] { XCTAssertNil(m.feed(keyCode: code)) }
        XCTAssertEqual(m.feed(keyCode: x), .desktop)
    }

    func testWrongKeyThatIsAFirstKeyCountsAsAFirstKey() {
        var m = matcher()
        for code in [down, up, down, up] { _ = m.feed(keyCode: code) }
        XCTAssertNil(m.feed(keyCode: down))   // wrong here, but starts a new attempt
        for code in [up, down, up] { XCTAssertNil(m.feed(keyCode: code)) }
        XCTAssertEqual(m.feed(keyCode: x), .desktop)
    }

    func testSilenceResetsProgress() {
        var m = matcher(timeout: 5)
        let t0 = Date()
        for (i, code) in [down, up, down, up].enumerated() { _ = m.feed(keyCode: code, now: t0.addingTimeInterval(Double(i))) }
        XCTAssertNil(m.feed(keyCode: x, now: t0.addingTimeInterval(20)))
    }

    func testMatchResetsSoItCannotFireTwice() {
        var m = matcher()
        for code in [down, up, down, up] { _ = m.feed(keyCode: code) }
        XCTAssertEqual(m.feed(keyCode: x), .desktop)
        XCTAssertNil(m.feed(keyCode: x))
    }

    func testPrefixConflictIsRefused() {
        XCTAssertNotNil(UnlockSequence.conflict(desktop: [down, up, down, up], screensaver: [down, up, down, up, s]))
        XCTAssertNotNil(UnlockSequence.conflict(desktop: [down, up, down, up, x], screensaver: [down, up, down, up, x]))
    }

    func testDisplayNames() {
        XCTAssertEqual(UnlockSequence.display(UnlockSequence.defaultDesktop), "\u{2193} \u{2191} \u{2193} \u{2191} X")
        XCTAssertEqual(UnlockSequence.display(UnlockSequence.defaultScreensaver), "\u{2193} \u{2191} \u{2193} \u{2191} S")
    }
}
