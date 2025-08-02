
import Foundation

public struct YearData: Codable {
    public let lastUpdatedAt: Int64
    public let data: [MonthData]

    enum CodingKeys: String, CodingKey {
        case lastUpdatedAt = "last_updated_at"
        case data
    }
}

public struct MonthData: Codable {
    public let month: Int
    public let days: [DayData]
}

public struct DayData: Codable {
    public let isHoliday: Bool
    public let event: String
    public let tithi: String?
    public let day: String
    public let dayInEn: String
    public let en: String
}
