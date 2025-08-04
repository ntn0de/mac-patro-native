import Foundation
import Combine
import AppKit

/// A singleton service that detects and publishes day changes.
///
/// This service listens for the `NSCalendarDayChanged` notification and `NSWorkspace.didWakeNotification`.
/// This ensures that date changes are detected both when the app is running and when the system wakes from sleep.
/// This allows multiple view models to subscribe to a single source of truth for date changes,
/// ensuring all date-sensitive UI components refresh consistently and efficiently.
public class DateChangeService {
    
    /// The shared singleton instance of the service.
    public static let shared = DateChangeService()
    
    /// A Combine publisher that emits a `Void` event when the system day changes.
    public let dayDidChange = PassthroughSubject<Void, Never>()
    
    private init() {
        // For day changes when the app is running
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDayChange),
            name: .NSCalendarDayChanged,
            object: nil
        )
        
        // For day changes that occur while the system is asleep
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleDayChange),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        #if DEBUG
        print("DateChangeService initialized and listening for day changes and system wake events.")
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    @objc private func handleDayChange() {
        #if DEBUG
        print("DateChangeService detected a day change or system wake. Broadcasting notification.")
        #endif
        // Ensure the notification is sent on the main thread, as it will trigger UI updates.
        DispatchQueue.main.async {
            self.dayDidChange.send(())
        }
    }
}
