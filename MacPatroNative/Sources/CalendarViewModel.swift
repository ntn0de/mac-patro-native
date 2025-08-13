import Foundation
import SwiftUI
import Combine

public class CalendarViewModel: ObservableObject {
    @Published var days: [CalendarCellInfo] = []
    @Published var monthYearString: String = ""
    @Published var englishMonthRange: String = ""
    
    private var date: Date
    private var yearData: YearData?
    @Published var todayYearData: YearData?
    private var currentYear: Int = 0
    
    private var dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    public init(date: Date = Calendar.currentDateForNepalConversion, dataService: DataServiceProtocol = DataService()) {
        self.date = date
        self.dataService = dataService
        fetchAndGenerateCalendar()
        
        // Load data for today's events
        loadTodayData()
        
        // Subscribe to the centralized day change publisher
        DateChangeService.shared.dayDidChange
            .sink { [weak self] in
                #if DEBUG
                print("CalendarViewModel received day change notification. Refreshing.")
                #endif
                self?.goToToday()
            }
            .store(in: &cancellables)

        // Subscribe to data update notifications
        dataService.dataDidUpdate
            .sink { [weak self] _ in
                #if DEBUG
                print("CalendarViewModel received new data notification. Forcing refresh.")
                #endif
                self?.forceRefresh()
            }
            .store(in: &cancellables)
    }
    
    private func fetchAndGenerateCalendar() {
        let nepaliDate = DateConverter.toNepaliDate(from: date)!
        if self.yearData == nil || nepaliDate.bsYear != self.currentYear {
            #if DEBUG
            print("Year changed or no data. Fetching for \(nepaliDate.bsYear)")
            #endif
            self.currentYear = nepaliDate.bsYear
            dataService.loadData(forYear: nepaliDate.bsYear, bundle: .main) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let yearData):
                        self.yearData = yearData
                        #if DEBUG
                        print("Data loaded for \(yearData.data.count) months. First event: \(yearData.data.first?.days.first?.event ?? "N/A")")
                        #endif
                    case .failure(let error):
                        #if DEBUG
                        print("Failed to load year data: \(error)")
                        #endif
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
        let firstWeekday = Calendar.nepal.component(.weekday, from: firstGregorianOfMonth) // 1 = Sun
        
        // 2. Pad with previous month's days
        let daysToPad = firstWeekday - 1
        if daysToPad > 0 {
            for i in (0..<daysToPad).reversed() {
                if let prevDayGregorian = Calendar.nepal.date(byAdding: .day, value: -(i+1), to: firstGregorianOfMonth) {
                    let prevDayNepali = DateConverter.gregorianToBikramSambat(date: prevDayGregorian)
                    calendarDays.append(
                        CalendarCellInfo(
                            nepaliDay: NumberFormatter.nepaliString(from: prevDayNepali.bsDay),
                            englishDay: Calendar.nepal.component(.day, from: prevDayGregorian),
                            date: prevDayGregorian,
                            isCurrentMonth: false,
                            isHoliday: isHoliday(date: prevDayNepali),
                            event: getEvent(date: prevDayNepali),
                            tithi: getTithi(date: prevDayNepali)
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
                        englishDay: Calendar.nepal.component(.day, from: currentGregorianDate),
                        date: currentGregorianDate,
                        isCurrentMonth: true,
                        isHoliday: isHoliday(date: currentNepaliDate),
                        event: getEvent(date: currentNepaliDate),
                        tithi: getTithi(date: currentNepaliDate)
                    )
                )
            }
        }
        
        // 4. Pad with next month's days
        let totalDays = 42
        let remainingDays = totalDays - calendarDays.count
        if let nextMonthStartDate = Calendar.nepal.date(byAdding: .day, value: daysInMonth, to: firstGregorianOfMonth) {
            for i in 0..<remainingDays {
                if let nextDayGregorian = Calendar.nepal.date(byAdding: .day, value: i, to: nextMonthStartDate) {
                    let nextDayNepali = DateConverter.gregorianToBikramSambat(date: nextDayGregorian)
                    calendarDays.append(
                        CalendarCellInfo(
                            nepaliDay: NumberFormatter.nepaliString(from: nextDayNepali.bsDay),
                            englishDay: Calendar.nepal.component(.day, from: nextDayGregorian),
                            date: nextDayGregorian,
                            isCurrentMonth: false,
                            isHoliday: isHoliday(date: nextDayNepali),
                            event: getEvent(date: nextDayNepali),
                            tithi: getTithi(date: nextDayNepali)
                        )
                    )
                }
            }
        }
        
        self.days = Array(calendarDays.prefix(totalDays))
    }
    
    func isHoliday(date: NepaliDate) -> Bool {
        guard let dayData = getDayData(for: date, from: yearData) else { return false }
        return dayData.isHoliday
    }

    func getEvent(date: NepaliDate) -> String? {
        guard let dayData = getDayData(for: date, from: yearData), !dayData.event.isEmpty, dayData.event != "--" else { return nil }
        return dayData.event
    }

    func getTithi(date: NepaliDate) -> String? {
        guard let dayData = getDayData(for: date, from: yearData), let tithi = dayData.tithi, !tithi.isEmpty else { return nil }
        return tithi
    }
    
    func isTodayHoliday(date: NepaliDate) -> Bool {
        guard let dayData = getDayData(for: date, from: todayYearData) else { return false }
        return dayData.isHoliday
    }
    
    func getTodayEvent(date: NepaliDate) -> String? {
        guard let dayData = getDayData(for: date, from: todayYearData), !dayData.event.isEmpty, dayData.event != "--" else { return nil }
        return dayData.event
    }

    func getTodayTithi(date: NepaliDate) -> String? {
        guard let dayData = getDayData(for: date, from: todayYearData), let tithi = dayData.tithi, !tithi.isEmpty else { return nil }
        return tithi
    }

    private func getDayData(for date: NepaliDate, from yearData: YearData?) -> DayData? {
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
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Kathmandu")
        
        let firstMonthName = dateFormatter.string(from: firstGregorian)
        let lastMonthName = dateFormatter.string(from: lastGregorian)
        
        if firstMonthName == lastMonthName {
            self.englishMonthRange = firstMonthName
        } else {
            self.englishMonthRange = "\(firstMonthName) - \(lastMonthName)"
        }
    }
    
    func goToNextMonth() {
        date = Calendar.nepal.date(byAdding: .month, value: 1, to: date)!
        fetchAndGenerateCalendar()
    }
    
    func goToPreviousMonth() {
        date = Calendar.nepal.date(byAdding: .month, value: -1, to: date)!
        fetchAndGenerateCalendar()
    }

    func goToToday() {
        date = Calendar.currentDateForNepalConversion
        fetchAndGenerateCalendar()
    }

    public func forceRefresh() {
        self.yearData = nil
        self.todayYearData = nil
        fetchAndGenerateCalendar()
        loadTodayData()
    }

    private func loadTodayData() {
        let todayNepali = DateConverter.toNepaliDate(from: Calendar.currentDateForNepalConversion)!
        dataService.loadData(forYear: todayNepali.bsYear, bundle: .main) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let yearData):
                    self.todayYearData = yearData
                case .failure(let error):
                    #if DEBUG
                    print("Failed to load today's year data: \(error)")
                    #endif
                    self.todayYearData = nil
                }
            }
        }
    }
    public func getInfo(for date: Date) -> (isHoliday: Bool, event: String?, tithi: String?) {
        let nepaliDate = DateConverter.toNepaliDate(from: date)!
        let isToday = Calendar.nepal.isDateInToday(date)
        
        let yearDataToUse = isToday ? todayYearData : yearData
        
        guard let dayData = getDayData(for: nepaliDate, from: yearDataToUse) else {
            return (date.isSaturday(), nil, nil)
        }
        
        let isHoliday = dayData.isHoliday || date.isSaturday()
        let event = (dayData.event.isEmpty || dayData.event == "--") ? nil : dayData.event
        let tithi = (dayData.tithi?.isEmpty ?? true) ? nil : dayData.tithi
        
        return (isHoliday, event, tithi)
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
    public let tithi: String?
}
