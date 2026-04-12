import Foundation

public struct NepaliDateDisplay {
    public let gregorianDate: Date
    public let nepaliDate: NepaliDate
    public let dayString: String
    public let monthName: String
    public let yearString: String
    public let dayOfWeekName: String
    public let fullDateString: String
}

public protocol NepaliCalendarServing {
    var currentDateForConversion: Date { get }
    func currentNepaliDate() -> NepaliDate?
    func nepaliDate(from gregorianDate: Date) -> NepaliDate?
    func display(for gregorianDate: Date) -> NepaliDateDisplay?
    func currentDisplay() -> NepaliDateDisplay?
    func menuBarText(for display: NepaliDateDisplay, format: SettingsService.DateFormat, separator: SettingsService.Separator) -> String
}

public final class NepaliCalendarService {
    public static let shared = NepaliCalendarService()

    private let currentDateProvider: () -> Date

    public init(currentDateProvider: @escaping () -> Date = { Calendar.currentDateForNepalConversion }) {
        self.currentDateProvider = currentDateProvider
    }

    public var currentDateForConversion: Date {
        currentDateProvider()
    }

    public func currentNepaliDate() -> NepaliDate? {
        nepaliDate(from: currentDateForConversion)
    }

    public func nepaliDate(from gregorianDate: Date) -> NepaliDate? {
        DateConverter.toNepaliDate(from: gregorianDate)
    }

    public func display(for gregorianDate: Date) -> NepaliDateDisplay? {
        guard let nepaliDate = nepaliDate(from: gregorianDate) else {
            return nil
        }

        let dayString = NumberFormatter.nepaliString(from: nepaliDate.bsDay)
        let monthName = NepaliMonth(rawValue: nepaliDate.bsMonth)?.name ?? ""
        let yearString = NumberFormatter.nepaliString(from: nepaliDate.bsYear)
        let dayOfWeekName = LocalizationService.shared.nepaliDay(for: nepaliDate.dayOfWeek)
        let fullDateString = "\(dayOfWeekName) \(dayString), \(monthName) \(yearString)"

        return NepaliDateDisplay(
            gregorianDate: gregorianDate,
            nepaliDate: nepaliDate,
            dayString: dayString,
            monthName: monthName,
            yearString: yearString,
            dayOfWeekName: dayOfWeekName,
            fullDateString: fullDateString
        )
    }

    public func currentDisplay() -> NepaliDateDisplay? {
        display(for: currentDateForConversion)
    }

    public func menuBarText(for display: NepaliDateDisplay, format: SettingsService.DateFormat, separator: SettingsService.Separator) -> String {
        let components: [String]

        switch format {
        case .day:
            components = [display.dayString]
        case .dayMonth:
            components = [display.dayString, display.monthName]
        case .dayMonthYear:
            components = [display.dayString, display.monthName, display.yearString]
        }

        return components.joined(separator: separator.rawValue)
    }
}

extension NepaliCalendarService: NepaliCalendarServing {}
