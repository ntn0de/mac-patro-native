
import Foundation
import SwiftUI
import Combine

public class MenuBarViewModel: ObservableObject {
    @Published public var menuBarText: String = "MacPatro"
    @Published public var iconName: String = "1"
    @Published public var menuBarIconText: String = ""

    private var settingsCancellable: AnyCancellable?
    private let settings = SettingsService.shared

    public init() {
        updateMenuBarText()
        
        // Update whenever the settings change
        settingsCancellable = settings.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateMenuBarText()
            }
        }
        
        // Also update every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateMenuBarText()
        }
    }

    private func updateMenuBarText() {
        let nepaliDate = DateConverter.toNepaliDate(from: Date())!
        let day = NumberFormatter.nepaliString(from: nepaliDate.bsDay)
        let month = NepaliMonth(rawValue: nepaliDate.bsMonth)!.name
        let year = NumberFormatter.nepaliString(from: nepaliDate.bsYear)
        
        var components: [String] = []
        
        switch settings.dateFormat {
        case .day:
            components.append(day)
        case .dayMonth:
            components.append(day)
            components.append(month)
        case .dayMonthYear:
            components.append(day)
            components.append(month)
            components.append(year)
        }
        
        menuBarIconText = components.joined(separator: settings.separator.rawValue)
        iconName = NumberFormatter.nepaliString(from: nepaliDate.bsDay)
    }
}
