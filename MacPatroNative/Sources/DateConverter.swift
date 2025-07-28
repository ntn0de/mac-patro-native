
import Foundation

public final class DateConverter {
    
    private static let bsEpoch: TimeInterval = -1789948800 // 1913-04-13 00:00:00 UTC
    private static let bsYearZero = 1970
    private static let msPerDay: TimeInterval = 86400
    
    private static let encodedMonthLengths: [Int64] = [
        5315258,5314490,9459438,8673005,5315258,5315066,9459438,8673005,5315258,5314298,9459438,5327594,5315258,5314298,9459438,5327594,5315258,5314286,9459438,5315306,5315258,5314286,8673006,5315306,5315258,5265134,8673006,5315258,5315258,9459438,8673005,5315258,5314298,9459438,8673005,5315258,5314298,9459438,8473322,5315258,5314298,9459438,5327594,5315258,5314298,9459438,5327594,5315258,5314286,8673006,5315306,5315258,5265134,8673006,5315306,5315258,9459438,8673005,5315258,5314490,9459438,8673005,5315258,5314298,9459438,8473325,5315258,5314298,9459438,5327594,5315258,5314298,9459438,5327594,5315258,5314286,9459438,5315306,5315258,5265134,8673006,5315306,5315258,5265134,8673006,5315258,5314490,9459438,8673005,5315258,5314298,9459438,8669933,5315258,5314298,9459438,8473322,5315258,5314298,9459438,5327594,5315258,5314286,9459438,5315306,5315258,5265134,8673006,5315306,5315258,5265134,8673006,5315258,5527226,5527226,5528046,5527277,5528250,5528057,5527277,5527277
    ]
    
    public static func daysInMonth(year: Int, month: Int) -> Int? {
        guard month >= 1 && month <= 12 else { return nil }
        guard year >= bsYearZero && year < bsYearZero + encodedMonthLengths.count else { return nil }
        return 29 + Int((encodedMonthLengths[year - bsYearZero] >> ((month - 1) * 2)) & 3)
    }
    
    public static func toGregorianDate(from nepaliDate: NepaliDate) -> Date? {
        let year = nepaliDate.bsYear
        var month = nepaliDate.bsMonth
        let day = nepaliDate.bsDay

        guard let daysInMonth = daysInMonth(year: year, month: month), day >= 1, day <= daysInMonth else {
            return nil
        }

        var timestamp = bsEpoch + (Double(day - 1) * msPerDay)
        month -= 1
        
        var y = year
        while y >= bsYearZero {
            while month > 0 {
                timestamp += (Double(self.daysInMonth(year: y, month: month)!) * msPerDay)
                month -= 1
            }
            month = 12
            y -= 1
        }

        return Date(timeIntervalSince1970: timestamp)
    }

    public static func gregorianToBikramSambat(date: Date) -> NepaliDate {
        return toNepaliDate(from: date)!
    }

    public static func formatEnglishDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    public static func toNepaliDate(from gregorianDate: Date) -> NepaliDate? {
        let days = Int(floor((gregorianDate.timeIntervalSince1970 - bsEpoch) / msPerDay)) + 1
        
        var year = bsYearZero
        var month = 1
        
        var remainingDays = days
        
        while remainingDays > 0 {
            let daysInMonth = self.daysInMonth(year: year, month: month)!
            if remainingDays > daysInMonth {
                remainingDays -= daysInMonth
                month += 1
                if month > 12 {
                    month = 1
                    year += 1
                }
            } else {
                return NepaliDate(bsYear: year, bsMonth: month, bsDay: remainingDays)
            }
        }
        return nil
    }
}
