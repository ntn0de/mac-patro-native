
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
    
}
