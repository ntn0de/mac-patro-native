import Foundation

/// A struct to represent a date in the Bikram Sambat (BS) calendar.
public struct NepaliDate: CustomStringConvertible {
    /// The year in the Bikram Sambat calendar.
    public let bsYear: Int

    /// The month in the Bikram Sambat calendar (1-12).
    public let bsMonth: Int

    /// The day in the Bikram Sambat calendar (1-32).
    public let bsDay: Int

    public var dayOfWeek: String {
        let date = DateConverter.toGregorianDate(from: self)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date)
    }

    public var description: String {
        return "\(bsYear)-\(bsMonth)-\(bsDay)"
    }
}

extension NepaliDate: Equatable {
    public static func == (lhs: NepaliDate, rhs: NepaliDate) -> Bool {
        return lhs.bsYear == rhs.bsYear &&
               lhs.bsMonth == rhs.bsMonth &&
               lhs.bsDay == rhs.bsDay
    }
}

extension NepaliDate: Comparable {
    public static func < (lhs: NepaliDate, rhs: NepaliDate) -> Bool {
        if lhs.bsYear != rhs.bsYear {
            return lhs.bsYear < rhs.bsYear
        } else if lhs.bsMonth != rhs.bsMonth {
            return lhs.bsMonth < rhs.bsMonth
        } else {
            return lhs.bsDay < rhs.bsDay
        }
    }
}
