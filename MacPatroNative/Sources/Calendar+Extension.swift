import Foundation

public extension Calendar {
    static var nepal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kathmandu")!
        return calendar
    }
    
    /// Gets a Date adjusted for Nepal timezone that can be used with DateConverter
    /// DateConverter works with UTC day boundaries, so we need to shift the date
    /// by Nepal's timezone offset to get the correct Nepali date
    static var currentDateForNepalConversion: Date {
        let now = Date()
        let nepalTimeZone = TimeZone(identifier: "Asia/Kathmandu")!
        let nepalOffset = nepalTimeZone.secondsFromGMT(for: now)
        
        // Add the Nepal timezone offset so when DateConverter calculates 
        // days from UTC epoch, it will count the correct Nepal day
        return now.addingTimeInterval(TimeInterval(nepalOffset))
    }
}
