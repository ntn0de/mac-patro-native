
import XCTest
@testable import MacPatroKit

final class DateConverterTests: XCTestCase {

    func testToGregorianConversion() {
        let testData: [[String: [Int]]] = [
            ["bs": [1970,1,1], "expectedGreg": [1913,4,13]],
            ["bs": [1980,1,21], "expectedGreg": [1923,5,3]],
            ["bs": [2007,1,1], "expectedGreg": [1950,4,13]],
            ["bs": [2007,1,31], "expectedGreg": [1950,5,13]],
            ["bs": [2007,2,32], "expectedGreg": [1950,6,14]],
            ["bs": [2008,12,31], "expectedGreg": [1952,4,12]],
            ["bs": [2081,4,11], "expectedGreg": [2024,7,26]],
        ]

        for data in testData {
            let bsDate = NepaliDate(bsYear: data["bs"]![0], bsMonth: data["bs"]![1], bsDay: data["bs"]![2])
            let expectedGregDate = data["expectedGreg"]!
            
            let adDate = DateConverter.toGregorianDate(from: bsDate)!
            
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let components = calendar.dateComponents([.year, .month, .day], from: adDate)
            
            XCTAssertEqual(components.year, expectedGregDate[0])
            XCTAssertEqual(components.month, expectedGregDate[1])
            XCTAssertEqual(components.day, expectedGregDate[2])
        }
    }

    func testToNepaliConversion() {
        let testData: [[String: [Int]]] = [
            ["greg": [1913,4,13], "expectedBS": [1970,1,1]],
            ["greg": [1923,5,3], "expectedBS": [1980,1,21]],
            ["greg": [1950,4,13], "expectedBS": [2007,1,1]],
            ["greg": [1950,5,13], "expectedBS": [2007,1,31]],
            ["greg": [1950,6,14], "expectedBS": [2007,2,32]],
            ["greg": [1952,4,12], "expectedBS": [2008,12,31]],
            ["greg": [2024,7,26], "expectedBS": [2081,4,11]],
        ]

        for data in testData {
            let gregDate = data["greg"]!
            let expectedBSDate = data["expectedBS"]!
            
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let adDate = calendar.date(from: DateComponents(year: gregDate[0], month: gregDate[1], day: gregDate[2]))!
            
            let bsDate = DateConverter.toNepaliDate(from: adDate)!
            
            XCTAssertEqual(bsDate.bsYear, expectedBSDate[0])
            XCTAssertEqual(bsDate.bsMonth, expectedBSDate[1])
            XCTAssertEqual(bsDate.bsDay, expectedBSDate[2])
        }
    }

    func testAsoj2083Boundary() throws {
        // Verified Asoj boundary; see docs/calendar-data-2083.md.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let asoj31 = NepaliDate(bsYear: 2083, bsMonth: 6, bsDay: 31)
        let kartik1 = NepaliDate(bsYear: 2083, bsMonth: 7, bsDay: 1)
        let october17 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 17)))
        let october18 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 18)))

        XCTAssertEqual(DateConverter.daysInMonth(year: 2083, month: 6), 31)
        XCTAssertEqual(DateConverter.toGregorianDate(from: asoj31), october17)
        XCTAssertEqual(DateConverter.toGregorianDate(from: kartik1), october18)
        XCTAssertEqual(DateConverter.toNepaliDate(from: october17), asoj31)
        XCTAssertEqual(DateConverter.toNepaliDate(from: october18), kartik1)
        XCTAssertNil(DateConverter.toGregorianDate(from: NepaliDate(bsYear: 2083, bsMonth: 6, bsDay: 32)))
    }

    func testPublished2083MonthBoundaries() throws {
        // Independently verified calendar boundaries; see docs/calendar-data-2083.md.
        let monthLengths = [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]
        let gregorianStarts = [
            [2026, 4, 14], [2026, 5, 15], [2026, 6, 15], [2026, 7, 17],
            [2026, 8, 17], [2026, 9, 17], [2026, 10, 18], [2026, 11, 17],
            [2026, 12, 16], [2027, 1, 15], [2027, 2, 13], [2027, 3, 15],
            [2027, 4, 14]
        ]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let starts = try gregorianStarts.map { parts in
            try XCTUnwrap(calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])))
        }

        for month in 1...12 {
            let length = monthLengths[month - 1]
            let firstDay = NepaliDate(bsYear: 2083, bsMonth: month, bsDay: 1)
            let lastDay = NepaliDate(bsYear: 2083, bsMonth: month, bsDay: length)
            let lastGregorian = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: starts[month]))

            XCTAssertEqual(DateConverter.daysInMonth(year: 2083, month: month), length, "Month \(month)")
            XCTAssertEqual(DateConverter.toGregorianDate(from: firstDay), starts[month - 1], "Month \(month) start")
            XCTAssertEqual(DateConverter.toNepaliDate(from: starts[month - 1]), firstDay, "Month \(month) start")
            XCTAssertEqual(DateConverter.toGregorianDate(from: lastDay), lastGregorian, "Month \(month) end")
            XCTAssertEqual(DateConverter.toNepaliDate(from: lastGregorian), lastDay, "Month \(month) end")
            XCTAssertNil(DateConverter.toGregorianDate(from: NepaliDate(bsYear: 2083, bsMonth: month, bsDay: length + 1)))
        }

        let newYear = NepaliDate(bsYear: 2084, bsMonth: 1, bsDay: 1)
        XCTAssertEqual(DateConverter.toGregorianDate(from: newYear), starts[12])
        XCTAssertEqual(DateConverter.toNepaliDate(from: starts[12]), newYear)
    }

    func testNepaliMonthNavigationAcrossSupportedDates() {
        let firstSupportedYear = DateConverter.supportedBSYearRange.lowerBound
        let lastSupportedYear = DateConverter.supportedBSYearRange.upperBound

        for year in firstSupportedYear...lastSupportedYear {
            for month in 1...12 {
                guard let daysInMonth = DateConverter.daysInMonth(year: year, month: month) else {
                    XCTFail("Missing month length for \(year)-\(month)")
                    return
                }

                for day in 1...daysInMonth {
                    let currentBsDate = NepaliDate(bsYear: year, bsMonth: month, bsDay: day)
                    guard let currentGregDate = DateConverter.toGregorianDate(from: currentBsDate) else {
                        XCTFail("Failed to convert \(currentBsDate) to Gregorian")
                        return
                    }

                    if !(year == firstSupportedYear && month == 1) {
                        let expectedPreviousMonth = month == 1
                            ? NepaliDate(bsYear: year - 1, bsMonth: 12, bsDay: 1)
                            : NepaliDate(bsYear: year, bsMonth: month - 1, bsDay: 1)

                        guard let previousMonthStart = DateConverter.startOfNepaliMonth(for: currentGregDate, addingMonths: -1),
                              let previousBsDate = DateConverter.toNepaliDate(from: previousMonthStart) else {
                            XCTFail("Failed previous-month navigation for \(currentBsDate)")
                            return
                        }

                        XCTAssertEqual(previousBsDate, expectedPreviousMonth, "Unexpected previous month from \(currentBsDate)")
                    }

                    if !(year == lastSupportedYear && month == 12) {
                        let expectedNextMonth = month == 12
                            ? NepaliDate(bsYear: year + 1, bsMonth: 1, bsDay: 1)
                            : NepaliDate(bsYear: year, bsMonth: month + 1, bsDay: 1)

                        guard let nextMonthStart = DateConverter.startOfNepaliMonth(for: currentGregDate, addingMonths: 1),
                              let nextBsDate = DateConverter.toNepaliDate(from: nextMonthStart) else {
                            XCTFail("Failed next-month navigation for \(currentBsDate)")
                            return
                        }

                        XCTAssertEqual(nextBsDate, expectedNextMonth, "Unexpected next month from \(currentBsDate)")
                    }
                }
            }
        }
    }

    func testToNepaliDateReturnsNilForUnsupportedDates() {
        let lowerOutOfRangeDate = Date(timeIntervalSince1970: -1789948800 - 86400)
        XCTAssertNil(DateConverter.toNepaliDate(from: lowerOutOfRangeDate))

        let upperOutOfRangeDate = try! XCTUnwrap(
            Calendar(identifier: .gregorian).date(from: DateComponents(year: 2200, month: 1, day: 1))
        )

        XCTAssertNil(DateConverter.toNepaliDate(from: upperOutOfRangeDate))
    }

    func testNepaliCalendarServiceReturnsNilForUnsupportedDates() {
        let service = NepaliCalendarService()
        let unsupportedDate = Date(timeIntervalSince1970: -1789948800 - 86400)

        XCTAssertNil(service.nepaliDate(from: unsupportedDate))
        XCTAssertNil(service.display(for: unsupportedDate))
    }
    
}
