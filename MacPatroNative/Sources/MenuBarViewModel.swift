
import Foundation
import SwiftUI
import Combine

public class MenuBarViewModel: ObservableObject {
    @Published public var menuBarText: String = "MacPatro"
    @Published public var iconName: String = "1"
    @Published public var menuBarIconText: String = ""

    private var cancellables = Set<AnyCancellable>()
    private let settings = SettingsService.shared
    private let dataService: DataServiceProtocol

    public init(dataService: DataServiceProtocol = DataService()) {
        self.dataService = dataService
        updateMenuBarText()
        
        // Update whenever the settings change
        settings.objectWillChange
            .sink { [weak self] _ in
                self?.updateMenuBarText()
            }
            .store(in: &cancellables)
        
        // Subscribe to the centralized day change publisher
        DateChangeService.shared.dayDidChange
            .sink { [weak self] in
                #if DEBUG
                print("MenuBarViewModel received day change notification. Refreshing.")
                #endif
                self?.updateMenuBarText()
            }
            .store(in: &cancellables)

        // Subscribe to data update notifications
        dataService.dataDidUpdate
            .sink { [weak self] _ in
                #if DEBUG
                print("MenuBarViewModel received new data notification. Refreshing.")
                #endif
                self?.updateMenuBarText()
            }
            .store(in: &cancellables)
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
