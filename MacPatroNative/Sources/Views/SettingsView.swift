import ServiceManagement
import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var settings = SettingsService.shared
    @Environment(\.dismiss) var dismiss
    private let calendarService: NepaliCalendarServing

    private let day: String
    private let month: String
    private let year: String

    public init(calendarService: NepaliCalendarServing = NepaliCalendarService.shared) {
        self.calendarService = calendarService

        if let today = calendarService.currentDisplay() {
            self.day = today.dayString
            self.month = today.monthName
            self.year = today.yearString
        } else {
            self.day = "-"
            self.month = "-"
            self.year = "-"
        }
    }

    private func exampleString(for format: SettingsService.DateFormat) -> String {
        let separator = settings.separator.rawValue
        switch format {
        case .day:
            return day
        case .dayMonth:
            return [day, month].joined(separator: separator)
        case .dayMonthYear:
            return [day, month, year].joined(separator: separator)
        }
    }

    private var launchAtLogin: Binding<Bool> {
        Binding {
            SMAppService.mainApp.status == .enabled
        } set: { enabled in
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                log("Failed to update launch at login:", error)
            }
        }
    }

    public var body: some View {
        VStack {
            Form {
                Picker("Format:", selection: $settings.dateFormat) {
                    ForEach(SettingsService.DateFormat.allCases) { format in
                        Text(exampleString(for: format)).tag(format)
                    }
                }
                
                Picker("Separator:", selection: $settings.separator) {
                    ForEach(SettingsService.Separator.allCases) { separator in
                        Text(separator.nepaliName).tag(separator)
                    }
                }
                
                Toggle("Show Nepal Time", isOn: $settings.showNepalTime)
                Toggle("Launch at Login", isOn: launchAtLogin)
            }
            
            Spacer()
            
            CheckForUpdatesView()
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 300, height: 300)
    }
}
