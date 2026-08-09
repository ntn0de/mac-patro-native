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
        VStack(alignment: .leading, spacing: 12) {
            settingPicker(icon: "textformat", title: "Format") {
                Picker("Format", selection: $settings.dateFormat) {
                    ForEach(SettingsService.DateFormat.allCases) { format in
                        Text(exampleString(for: format)).tag(format)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }

            Divider()

            settingPicker(icon: "arrow.left.and.right", title: "Separator") {
                Picker("Separator", selection: $settings.separator) {
                    ForEach(SettingsService.Separator.allCases) { separator in
                        Text(separator.nepaliName).tag(separator)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }

            Divider()

            Toggle(isOn: $settings.showNepalTime) {
                Label("Show Nepal Time", systemImage: "clock")
            }

            Toggle(isOn: launchAtLogin) {
                Label("Launch at Login", systemImage: "power")
            }

            Divider()

            CheckForUpdatesView()

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 380)
    }

    @ViewBuilder
    private func settingPicker<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            content()
        }
    }
}
