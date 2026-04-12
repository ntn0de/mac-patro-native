import AppKit
import SwiftUI

public class DateConverterWindowController: NSObject {
    private var dateConverterWindow: NSWindow?

    public func openDateConverter() {
        if dateConverterWindow == nil {
            let converterView = DateConverterView()
            let hostingController = NSHostingController(rootView: converterView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Date Converter"
            window.setContentSize(NSSize(width: 420, height: 260))
            window.isReleasedWhenClosed = false
            window.level = .floating
            dateConverterWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        dateConverterWindow?.makeKeyAndOrderFront(nil)
        dateConverterWindow?.orderFrontRegardless()
    }
}
