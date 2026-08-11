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
    private let calendarService: NepaliCalendarServing
    private var cancellables = Set<AnyCancellable>()
    
    public init(date: Date? = nil, dataService: DataServiceProtocol = DataService(), calendarService: NepaliCalendarServing = NepaliCalendarService.shared) {
        self.calendarService = calendarService
        let initialDate = date ?? calendarService.currentDateForConversion
        self.date = initialDate
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
        guard let nepaliDate = calendarService.nepaliDate(from: date) else {
            yearData = nil
            days = []
            monthYearString = ""
            englishMonthRange = ""
            return
        }

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
        guard let nepaliDate = calendarService.nepaliDate(from: date) else {
            days = []
            monthYearString = ""
            englishMonthRange = ""
            return
        }

        guard let daysInMonth = DateConverter.daysInMonth(year: nepaliDate.bsYear, month: nepaliDate.bsMonth) else {
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
                if let prevDayGregorian = Calendar.nepal.date(byAdding: .day, value: -(i+1), to: firstGregorianOfMonth),
                   let prevDayNepali = DateConverter.toNepaliDate(from: prevDayGregorian) {
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
                if let nextDayGregorian = Calendar.nepal.date(byAdding: .day, value: i, to: nextMonthStartDate),
                   let nextDayNepali = DateConverter.toNepaliDate(from: nextDayGregorian) {
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
        guard let nextMonthStart = DateConverter.startOfNepaliMonth(for: date, addingMonths: 1) else { return }
        date = nextMonthStart
        fetchAndGenerateCalendar()
    }
    
    func goToPreviousMonth() {
        guard let previousMonthStart = DateConverter.startOfNepaliMonth(for: date, addingMonths: -1) else { return }
        date = previousMonthStart
        fetchAndGenerateCalendar()
    }

    func goToToday() {
        date = calendarService.currentDateForConversion
        fetchAndGenerateCalendar()
        loadTodayData()
    }

    public func forceRefresh() {
        self.yearData = nil
        self.todayYearData = nil

        guard let viewedNepaliDate = calendarService.nepaliDate(from: date) else {
            generateCalendar()
            return
        }

        currentYear = viewedNepaliDate.bsYear
        dataService.loadData(forYear: viewedNepaliDate.bsYear, bundle: .main, ignoringCache: true) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let yearData):
                    self.yearData = yearData
                case .failure(let error):
                    #if DEBUG
                    print("Failed to force refresh viewed year data: \(error)")
                    #endif
                    self.yearData = nil
                }
                self.generateCalendar()
            }
        }

        loadTodayData(ignoringCache: true)
    }

    private func loadTodayData(ignoringCache: Bool = false) {
        guard let todayNepali = calendarService.currentNepaliDate() else {
            todayYearData = nil
            return
        }

        dataService.loadData(forYear: todayNepali.bsYear, bundle: .main, ignoringCache: ignoringCache) { result in
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
    public func upcomingEvents(limit: Int = 3) -> [UpcomingEvent] {
        guard let todayNepali = calendarService.currentNepaliDate(), let yearData = todayYearData else {
            return []
        }

        let today = Calendar.nepal.startOfDay(for: calendarService.currentDateForConversion)
        return yearData.data.flatMap { month in
            month.days.compactMap { day in
                guard !day.event.isEmpty, day.event != "--",
                      let dayNumber = Int(day.dayInEn),
                      let date = DateConverter.toGregorianDate(from: NepaliDate(bsYear: todayNepali.bsYear, bsMonth: month.month, bsDay: dayNumber)),
                      date >= today
                else { return nil }

                return UpcomingEvent(title: day.event, date: date)
            }
        }
        .sorted { $0.date < $1.date }
        .prefix(limit)
        .map { $0 }
    }

    public func getInfo(for date: Date) -> (isHoliday: Bool, event: String?, tithi: String?) {
        guard let nepaliDate = calendarService.nepaliDate(from: date) else {
            return (date.isSaturday(), nil, nil)
        }

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

public struct UpcomingEvent: Identifiable {
    public let title: String
    public let date: Date

    public var id: String { "\(title)-\(date.timeIntervalSince1970)" }

    public var daysRemaining: Int {
        Calendar.nepal.dateComponents([.day], from: Calendar.nepal.startOfDay(for: Date()), to: Calendar.nepal.startOfDay(for: date)).day ?? 0
    }

    public var tooltip: String {
        let nepaliDate = NepaliCalendarService.shared.display(for: date)?.fullDateString ?? ""
        return [nepaliDate, DateConverter.formatEnglishDate(date: date)]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
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
