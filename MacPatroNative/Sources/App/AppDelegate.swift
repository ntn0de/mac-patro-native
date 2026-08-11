import AppKit
import MacPatroKit
import Combine
import SwiftUI
import WidgetKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarController = StatusBarController()

        DateChangeService.shared.dayDidChange
            .sink { WidgetReload.reload() }
            .store(in: &cancellables)

        WidgetReload.reload()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard urls.contains(where: { $0.scheme == "macpatro" && $0.host == "calendar" }) else { return }
        statusBarController?.openCalendar()
    }
}

enum WidgetReload {
    static let kind = "MacPatroWidget.v2"

    static func reload() {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}
