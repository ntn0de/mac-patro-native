import Foundation
import SwiftUI

public class CalendarViewModel: ObservableObject {
    @Published var days: [CalendarCellInfo] = []
    @Published var monthYearString: String = ""
    @Published var englishMonthRange: String = ""
    
    private var date: Date
    private var yearData: YearData?
    private var currentYear: Int = 0
    
    private var dataService: DataServiceProtocol
    
    public init(date: Date = Date(), dataService: DataServiceProtocol = DataService()) {
        self.date = date
        self.dataService = dataService
        fetchAndGenerateCalendar()
    }
    
    private func fetchAndGenerateCalendar() {
        let nepaliDate = DateConverter.toNepaliDate(from: date)!
        if self.yearData == nil || nepaliDate.bsYear != self.currentYear {
            print("Year changed or no data. Fetching for \(nepaliDate.bsYear)")
            self.currentYear = nepaliDate.bsYear
            dataService.loadData(forYear: nepaliDate.bsYear, bundle: .main) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let yearData):
                        self.yearData = yearData
                        print("Data loaded for \(yearData.data.count) months. First event: \(yearData.data.first?.days.first?.event ?? "N/A")")
                    case .failure(let error):
                        print("Failed to load year data: \(error)")
                        self.yearData = nil
                    }
                    self.generateCalendar()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.generateCalendar()
            }
        }
    }
    
    func generateCalendar() {
        guard let nepaliDate = DateConverter.toNepaliDate(from: date),
              let daysInMonth = DateConverter.daysInMonth(year: nepaliDate.bsYear, month: nepaliDate.bsMonth) else {
            return
        }
        
        updateEnglishMonthRange(nepaliDate: nepaliDate, daysInMonth: daysInMonth)
        
        if let nepaliMonth = NepaliMonth(rawValue: nepaliDate.bsMonth) {
            self.monthYearString = "\(nepaliMonth.name) \(NumberFormatter.nepaliString(from: nepaliDate.bsYear))"
        }
        
        var calendarDays: [CalendarCellInfo] = []
        
        // 1. Get first day of Nepali month and its weekday
        let firstDayOfMonth = NepaliDate(bsYear: nepaliDate.bsYear, bsMonth: nepaliDate.bsMonth, bsDay: 1)
        guard let firstGregorianOfMonth = DateConverter.toGregorianDate(from: firstDayOfMonth) else { return }
        let firstWeekday = Calendar.current.component(.weekday, from: firstGregorianOfMonth) // 1 = Sun
        
        // 2. Pad with previous month's days
        let daysToPad = firstWeekday - 1
        if daysToPad > 0 {
            for i in (0..<daysToPad).reversed() {
                if let prevDayGregorian = Calendar.current.date(byAdding: .day, value: -(i+1), to: firstGregorianOfMonth) {
                    let prevDayNepali = DateConverter.gregorianToBikramSambat(date: prevDayGregorian)
                    calendarDays.append(
                        CalendarCellInfo(
                            nepaliDay: NumberFormatter.nepaliString(from: prevDayNepali.bsDay),
                            englishDay: Calendar.current.component(.day, from: prevDayGregorian),
                            date: prevDayGregorian,
                            isCurrentMonth: false,
                            isHoliday: isHoliday(date: prevDayNepali),
                            event: getEvent(date: prevDayNepali)
                        )
                    )
                }
            }
        }
        
        // 3. Add current month's days
        for day in 1...daysInMonth {
            let currentNepaliDate = NepaliDate(bsYear: nepaliDate.bsYear, bsMonth: nepaliDate.bsMonth, bsDay: day)
            if let currentGregorianDate = DateConverter.toGregorianDate(from: currentNepaliDate) {
                calendarDays.append(
                    CalendarCellInfo(
                        nepaliDay: NumberFormatter.nepaliString(from: day),
                        englishDay: Calendar.current.component(.day, from: currentGregorianDate),
                        date: currentGregorianDate,
                        isCurrentMonth: true,
                        isHoliday: isHoliday(date: currentNepaliDate),
                        event: getEvent(date: currentNepaliDate)
                    )
                )
            }
        }
        
        // 4. Pad with next month's days
        let totalDays = 42
        let remainingDays = totalDays - calendarDays.count
        if let nextMonthStartDate = Calendar.current.date(byAdding: .day, value: daysInMonth, to: firstGregorianOfMonth) {
            for i in 0..<remainingDays {
                if let nextDayGregorian = Calendar.current.date(byAdding: .day, value: i, to: nextMonthStartDate) {
                    let nextDayNepali = DateConverter.gregorianToBikramSambat(date: nextDayGregorian)
                    calendarDays.append(
                        CalendarCellInfo(
                            nepaliDay: NumberFormatter.nepaliString(from: nextDayNepali.bsDay),
                            englishDay: Calendar.current.component(.day, from: nextDayGregorian),
                            date: nextDayGregorian,
                            isCurrentMonth: false,
                            isHoliday: isHoliday(date: nextDayNepali),
                            event: getEvent(date: nextDayNepali)
                        )
                    )
                }
            }
        }
        
        self.days = Array(calendarDays.prefix(totalDays))
    }
    
    func isHoliday(date: NepaliDate) -> Bool {
        guard let dayData = getDayData(for: date) else { return false }
        return dayData.isHoliday
    }

    func getEvent(date: NepaliDate) -> String? {
        guard let dayData = getDayData(for: date), !dayData.event.isEmpty, dayData.event != "--" else { return nil }
        return dayData.event
    }

    private func getDayData(for date: NepaliDate) -> DayData? {
        guard let yearData = yearData,
              let monthData = yearData.data.first(where: { $0.month == date.bsMonth }),
              let dayData = monthData.days.first(where: { $0.dayInEn == String(date.bsDay) })
        else {
            return nil
        }
        return dayData
    }
    
    private func updateEnglishMonthRange(nepaliDate: NepaliDate, daysInMonth: Int) {
        let firstNepaliDate = NepaliDate(bsYear: nepaliDate.bsYear, bsMonth: nepaliDate.bsMonth, bsDay: 1)
        let lastNepaliDate = NepaliDate(bsYear: nepaliDate.bsYear, bsMonth: nepaliDate.bsMonth, bsDay: daysInMonth)
        
        guard let firstGregorian = DateConverter.toGregorianDate(from: firstNepaliDate),
              let lastGregorian = DateConverter.toGregorianDate(from: lastNepaliDate) else {
            self.englishMonthRange = ""
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        let firstMonthName = dateFormatter.string(from: firstGregorian)
        let lastMonthName = dateFormatter.string(from: lastGregorian)
        
        if firstMonthName == lastMonthName {
            self.englishMonthRange = firstMonthName
        } else {
            self.englishMonthRange = "\(firstMonthName) - \(lastMonthName)"
        }
    }
    
    func goToNextMonth() {
        date = Calendar.current.date(byAdding: .month, value: 1, to: date)!
        fetchAndGenerateCalendar()
    }
    
    func goToPreviousMonth() {
        date = Calendar.current.date(byAdding: .month, value: -1, to: date)!
        fetchAndGenerateCalendar()
    }

    func goToToday() {
        date = Date()
        fetchAndGenerateCalendar()
    }

    public func forceRefresh() {
        self.yearData = nil
        fetchAndGenerateCalendar()
    }
}

public struct CalendarCellInfo: Identifiable, Hashable {
    public let id = UUID()
    public let nepaliDay: String
    public let englishDay: Int
    public let date: Date
    public let isCurrentMonth: Bool
    public let isHoliday: Bool
    public let event: String?
}
