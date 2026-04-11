
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

    func testGetInfo() {
        // Test a regular weekday
        let regularDate = Date(timeIntervalSince1970: 1721884800) // Friday, July 25, 2025
        mockDataService.yearData = YearData(lastUpdatedAt: 0, data: [MonthData(month: 4, days: [DayData(isHoliday: false, event: "", tithi: "tithi", day: "10", dayInEn: "25", en: "July")])])
        let regularDateInfo = viewModel.getInfo(for: regularDate)
        XCTAssertFalse(regularDateInfo.isHoliday)

        // Test a Saturday
//        let saturdayDate = Date(timeIntervalSince1970: 1721971200) // Saturday, July 26, 2025
//        mockDataService.yearData = YearData(lastUpdatedAt: 0, data: [MonthData(month: 4, days: [DayData(isHoliday: false, event: "", tithi: "tithi", day: "11", dayInEn: "26", en: "July")])])
//        let saturdayDateInfo = viewModel.getInfo(for: saturdayDate)
//        XCTAssertTrue(saturdayDateInfo.isHoliday)

        // Test a holiday
        let holidayDate = Date(timeIntervalSince1970: 1722057600) // Sunday, July 27, 2025
        mockDataService.yearData = YearData(lastUpdatedAt: 0, data: [MonthData(month: 4, days: [DayData(isHoliday: true, event: "Holiday", tithi: "tithi", day: "12", dayInEn: "27", en: "July")])])
        let holidayDateInfo = viewModel.getInfo(for: holidayDate)
        XCTAssertTrue(holidayDateInfo.isHoliday)
    }

    func testForceRefreshBypassesCache() {
        let expectation = self.expectation(description: "Force refresh bypasses cache")

        mockDataService.yearData = YearData(lastUpdatedAt: 0, data: [MonthData(month: 4, days: [DayData(isHoliday: false, event: "", tithi: "tithi", day: "10", dayInEn: "25", en: "July")])])

        viewModel.forceRefresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.mockDataService.lastIgnoringCache, true)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
    
    static var allTests = [
        ("testGetInfo", testGetInfo),
        ("testForceRefreshBypassesCache", testForceRefreshBypassesCache),
    ]
}
