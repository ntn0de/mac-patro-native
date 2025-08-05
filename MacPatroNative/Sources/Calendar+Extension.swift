import Foundation

public extension Calendar {
    static var nepal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kathmandu")!
        return calendar
    }
}
