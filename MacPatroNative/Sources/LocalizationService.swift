import Foundation

public class LocalizationService {
    public static let shared = LocalizationService()

    private let nepaliDays = [
        "Sunday": "आइतबार",
        "Monday": "सोमबार",
        "Tuesday": "मङ्गलबार",
        "Wednesday": "बुधबार",
        "Thursday": "बिहिबार",
        "Friday": "शुक्रबार",
        "Saturday": "शनिबार"
    ]

    public func nepaliDay(for englishDay: String) -> String {
        return nepaliDays[englishDay] ?? englishDay
    }
}
