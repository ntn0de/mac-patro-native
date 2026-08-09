import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarController = StatusBarController()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard urls.contains(where: { $0.scheme == "macpatro" && $0.host == "calendar" }) else { return }
        statusBarController?.openCalendar()
    }
}
