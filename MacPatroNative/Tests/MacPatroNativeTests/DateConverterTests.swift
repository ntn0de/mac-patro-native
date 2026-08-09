
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
//            XCTAssertEqual(components.day, expectedGregDate[2])
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
