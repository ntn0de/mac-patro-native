import Foundation

import Combine

public class SettingsService: ObservableObject {
    public static let shared = SettingsService()
    public let settingsChangedPublisher = PassthroughSubject<Void, Never>()

    public enum DateFormat: String, CaseIterable, Identifiable {
        case day = "D"
        case dayMonth = "D Month"
        case dayMonthYear = "D Month Year"

        public var id: String { self.rawValue }

        public var nepaliName: String {
            switch self {
            case .day: "दिन"
            case .dayMonth: "दिन महिना"
            case .dayMonthYear: "दिन महिना वर्ष"
            }
        }
    }

    public enum Separator: String, CaseIterable, Identifiable {
        case space = " "
        case hyphen = "-"

        public var id: String { self.rawValue }

        public var nepaliName: String {
            switch self {
            case .space: "खाली ठाउँ"
            case .hyphen: "-"
            }
        }
    }

    @Published public var dateFormat: DateFormat {
        didSet {
            UserDefaults.standard.set(dateFormat.rawValue, forKey: "menuBarDateFormat")
            settingsChangedPublisher.send()
        }
    }

    @Published public var separator: Separator {
        didSet {
            UserDefaults.standard.set(separator.rawValue, forKey: "menuBarSeparator")
            settingsChangedPublisher.send()
        }
    }

    private init() {
        let savedFormat = UserDefaults.standard.string(forKey: "menuBarDateFormat") ?? DateFormat.dayMonth.rawValue
        self.dateFormat = DateFormat(rawValue: savedFormat) ?? .dayMonth

        let savedSeparator = UserDefaults.standard.string(forKey: "menuBarSeparator") ?? Separator.space.rawValue
        self.separator = Separator(rawValue: savedSeparator) ?? .space
    }
}
