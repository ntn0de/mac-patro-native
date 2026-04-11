
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

    enum CodingKeys: String, CodingKey {
        case isHoliday
        case event
        case tithi
        case day
        case dayInEn
        case en
    }

    public init(isHoliday: Bool, event: String, tithi: String?, day: String, dayInEn: String, en: String) {
        self.isHoliday = isHoliday
        self.event = event
        self.tithi = tithi
        self.day = day
        self.dayInEn = dayInEn
        self.en = en
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isHoliday = try container.decode(Bool.self, forKey: .isHoliday)
        event = try container.decodeIfPresent(String.self, forKey: .event) ?? ""
        tithi = try container.decodeIfPresent(String.self, forKey: .tithi)
        day = try container.decode(String.self, forKey: .day)
        dayInEn = try container.decode(String.self, forKey: .dayInEn)
        en = try container.decode(String.self, forKey: .en)
    }
}
