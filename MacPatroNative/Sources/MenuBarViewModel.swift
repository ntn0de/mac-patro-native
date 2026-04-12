
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
    private let calendarService: NepaliCalendarServing

    public init(dataService: DataServiceProtocol = DataService(), calendarService: NepaliCalendarServing = NepaliCalendarService.shared) {
        self.dataService = dataService
        self.calendarService = calendarService
        updateMenuBarText()
        
        // Update whenever the settings change
        settings.settingsChangedPublisher
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
        guard let display = calendarService.currentDisplay() else {
            menuBarIconText = menuBarText
            iconName = "1"
            return
        }

        menuBarIconText = calendarService.menuBarText(for: display, format: settings.dateFormat, separator: settings.separator)
        iconName = display.dayString
    }
}
