
import Foundation

public class DateFormattingService {
    public static let shared = DateFormattingService()
    
    private let dateFormats = ["d-MMMM", "yyyy-MM-dd", "MMMM d, yyyy"]
    
    public func formattedDate(for date: Date) -> String {
        let formatIndex = UserDefaults.standard.integer(forKey: "dateFormat")
        let format = dateFormats[formatIndex]
        
        let nepaliDate = DateConverter.toNepaliDate(from: date)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        let day = nepaliDate.bsDay
        let month = NepaliMonth(rawValue: nepaliDate.bsMonth)!.name
        let year = nepaliDate.bsYear
        
        let nepaliDay = NumberFormatter.nepaliString(from: day)
        let nepaliYear = NumberFormatter.nepaliString(from: year)
        let nepaliMonth = NumberFormatter.nepaliString(from: nepaliDate.bsMonth)

        var dateString = format.replacingOccurrences(of: "d", with: nepaliDay)
        dateString = dateString.replacingOccurrences(of: "MMMM", with: month)
        dateString = dateString.replacingOccurrences(of: "yyyy", with: nepaliYear)
        dateString = dateString.replacingOccurrences(of: "MM", with: nepaliMonth)
        dateString = dateString.replacingOccurrences(of: "dd", with: nepaliDay)
        
        return dateString
    }
}
