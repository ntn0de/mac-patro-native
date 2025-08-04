import AppKit
import SwiftUI
import Combine
import MacPatroKit

class StatusBarController: NSObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var menu: NSMenu
    private var menuBarViewModel: MenuBarViewModel
    private var cancellables = Set<AnyCancellable>()
    private var mainView: MainView
    private var eventMonitor: EventMonitor?
    private var aboutWindow: NSWindow?
    private var settingsWindowController = SettingsWindowController()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        mainView = MainView()
        menuBarViewModel = MenuBarViewModel()
        menu = NSMenu()

        super.init()

        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: mainView)
        popover.delegate = self
        
        let aboutMenuItem = NSMenuItem(title: "About", action: #selector(about), keyEquivalent: "")
        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)
        
        let forceUpdateMenuItem = NSMenuItem(title: "Force update year data", action: #selector(forceUpdate), keyEquivalent: "")
        forceUpdateMenuItem.target = self
        menu.addItem(forceUpdateMenuItem)

        let settingsMenuItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)

        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitMenuItem)
        
        menuBarViewModel.$menuBarIconText.assign(to: \.title, on: statusItem.button!).store(in: &cancellables)

        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, self.popover.isShown {
                self.closePopover(sender: event)
            }
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            if popover.isShown {
                closePopover(sender: sender)
            } else {
                if let button = statusItem.button {
                    let positioningRect = NSRect(x: 0, y: button.bounds.height + 12, width: button.bounds.width, height: 0)
                    NSApp.activate(ignoringOtherApps: true)
                    popover.show(relativeTo: positioningRect, of: button, preferredEdge: .minY)
                    eventMonitor?.start()
                }
            }
        }
    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
    
    func popoverDidClose(_ notification: Notification) {
        eventMonitor?.stop()
    }

    @objc func about() {
        if aboutWindow == nil {
            let aboutView = AboutView()
            let hostingController = NSHostingController(rootView: aboutView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "About MacPatro"
            window.isReleasedWhenClosed = false // Keep it in memory
            window.level = .floating
            aboutWindow = window
        }
        
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow?.makeKeyAndOrderFront(nil)
        aboutWindow?.orderFrontRegardless() // An extra measure
    }

    @objc func forceUpdate() {
        mainView.viewModel.forceRefresh()
    }

    @objc func openSettings() {
        settingsWindowController.openSettings()
    }
}

