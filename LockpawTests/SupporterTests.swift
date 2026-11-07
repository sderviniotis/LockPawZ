import XCTest
@testable import Lockpaw

final class SeasonalSkinTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        return calendar
    }

    private func season(_ year: Int, _ month: Int, _ day: Int) -> SeasonalSkin? {
        SeasonalSkin.current(on: calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!, calendar: calendar)
    }

    func testHalloweenWindow() {
        XCTAssertNil(season(2026, 10, 23))
        XCTAssertEqual(season(2026, 10, 24), .halloween)
        XCTAssertEqual(season(2026, 10, 31), .halloween)
        XCTAssertEqual(season(2026, 11, 1), .halloween)
        XCTAssertNil(season(2026, 11, 2))
    }

    func testWinterWindow() {
        XCTAssertNil(season(2026, 11, 30))
        XCTAssertEqual(season(2026, 12, 1), .winter)
        XCTAssertEqual(season(2026, 12, 31), .winter)
        XCTAssertEqual(season(2027, 1, 1), .winter)
        XCTAssertNil(season(2027, 1, 2))
    }

    func testLunarNewYearWindow() {
        // 2027: 6 February. Two days before through day 15.
        XCTAssertNil(season(2027, 2, 3))
        XCTAssertEqual(season(2027, 2, 4), .lunarNewYear)
        XCTAssertEqual(season(2027, 2, 20), .lunarNewYear)
        XCTAssertNil(season(2027, 2, 21))
        // 2028 falls in January.
        XCTAssertEqual(season(2028, 1, 26), .lunarNewYear)
    }

    func testMidsummerIsTheFridayBetween19And25June() {
        // 2027: Midsummer Eve is Friday 25 June.
        XCTAssertEqual(calendar.component(.day, from: SeasonalSkin.midsummerEve(year: 2027, calendar: calendar)!), 25)
        XCTAssertNil(season(2027, 6, 23))
        XCTAssertEqual(season(2027, 6, 24), .midsummer)
        XCTAssertEqual(season(2027, 6, 27), .midsummer)
        XCTAssertNil(season(2027, 6, 28))
        // 2026: Friday 19 June.
        XCTAssertEqual(calendar.component(.day, from: SeasonalSkin.midsummerEve(year: 2026, calendar: calendar)!), 19)
    }

    func testOrdinaryDayHasNoSeason() {
        XCTAssertNil(season(2026, 10, 7))
        XCTAssertNil(season(2027, 4, 15))
    }

    func testLunarTableCoversTheNextDecade() {
        for year in 2026...2035 { XCTAssertNotNil(SeasonalSkin.lunarNewYearDates[year], "\(year)") }
    }
}
