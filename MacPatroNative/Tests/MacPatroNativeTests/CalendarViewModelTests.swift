
import XCTest
@testable import MacPatroKit

final class CalendarViewModelTests: XCTestCase {

    var viewModel: CalendarViewModel!
    var mockDataService: MockDataService!

    override func setUp() {
        super.setUp()
        mockDataService = MockDataService()
        viewModel = CalendarViewModel(dataService: mockDataService)
    }

    override func tearDown() {
        viewModel = nil
        mockDataService = nil
        super.tearDown()
    }

    func testIsHolidayOrSaturday() {
        // Test a regular weekday
        let regularDate = Date(timeIntervalSince1970: 1721884800) // Friday, July 25, 2025
        mockDataService.yearData = YearData(lastUpdatedAt: 0, data: [MonthData(month: 4, days: [DayData(isHoliday: false, event: "", day: "10", dayInEn: "25", en: "July")])])
        XCTAssertFalse(viewModel.isHolidayOrSaturday(date: regularDate))

        // Test a Saturday
//        let saturdayDate = Date(timeIntervalSince1970: 1721971200) // Saturday, July 26, 2025
//        mockDataService.yearData = YearData(lastUpdatedAt: 0, data: [MonthData(month: 4, days: [DayData(isHoliday: false, event: "", day: "11", dayInEn: "26", en: "July")])])
//        XCTAssertTrue(viewModel.isHolidayOrSaturday(date: saturdayDate))

        // Test a holiday
        let holidayDate = Date(timeIntervalSince1970: 1722057600) // Sunday, July 27, 2025
        mockDataService.yearData = YearData(lastUpdatedAt: 0, data: [MonthData(month: 4, days: [DayData(isHoliday: true, event: "Holiday", day: "12", dayInEn: "27", en: "July")])])
        XCTAssertTrue(viewModel.isHolidayOrSaturday(date: holidayDate))
    }
    
    static var allTests = [
        ("testIsHolidayOrSaturday", testIsHolidayOrSaturday),
    ]
}
