
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

    func testUpcomingEventsIncludesNamedEventsFromToday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = calendar.date(from: DateComponents(year: 2024, month: 7, day: 26))!
        let service = NepaliCalendarService(currentDateProvider: { today })
        let dataService = MockDataService()
        let viewModel = CalendarViewModel(date: today, dataService: dataService, calendarService: service)
        viewModel.todayYearData = YearData(lastUpdatedAt: 1, data: [
            MonthData(month: 4, days: [
                DayData(isHoliday: true, event: "Today", tithi: nil, day: "११", dayInEn: "11", en: "2024-07-26"),
                DayData(isHoliday: false, event: "Tomorrow", tithi: nil, day: "१२", dayInEn: "12", en: "2024-07-27"),
                DayData(isHoliday: false, event: "--", tithi: nil, day: "१३", dayInEn: "13", en: "2024-07-28")
            ])
        ])

        XCTAssertEqual(viewModel.upcomingEvents().map(\.title), ["Today", "Tomorrow"])
    }

    func testAsoj2083CalendarIncludesDay31() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 17)))
        let service = NepaliCalendarService(currentDateProvider: { date })
        let viewModel = CalendarViewModel(date: date, dataService: MockDataService(), calendarService: service)
        viewModel.generateCalendar()

        let currentMonthDays = viewModel.days.filter(\.isCurrentMonth)
        XCTAssertEqual(currentMonthDays.count, 31)
        XCTAssertEqual(currentMonthDays.last?.nepaliDay, "३१")
        XCTAssertEqual(currentMonthDays.last?.date, date)
        XCTAssertEqual(viewModel.days.first(where: { $0.date == date })?.isCurrentMonth, true)
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
        ("testUpcomingEventsIncludesNamedEventsFromToday", testUpcomingEventsIncludesNamedEventsFromToday),
        ("testForceRefreshBypassesCache", testForceRefreshBypassesCache),
    ]
}
