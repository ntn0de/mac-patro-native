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

    private var lastKnownDayStart: Date
    
    private init() {
        lastKnownDayStart = Calendar.current.startOfDay(for: Date())

        // For day changes when the app is running
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePossibleDayChange),
            name: .NSCalendarDayChanged,
            object: nil
        )
        
        // For day changes that occur while the system is asleep
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handlePossibleDayChange),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Catch overnight transitions if the calendar-day notification was missed.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handlePossibleDayChange),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
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
    
    @objc private func handlePossibleDayChange() {
        DispatchQueue.main.async {
            self.publishIfDayChanged()
        }
    }

    /// Publishes only when the local calendar day has advanced since the last known day.
    public func publishIfDayChanged() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        guard todayStart != lastKnownDayStart else { return }
        lastKnownDayStart = todayStart
        #if DEBUG
        print("DateChangeService detected a day change. Broadcasting notification.")
        #endif
        dayDidChange.send(())
    }
}
