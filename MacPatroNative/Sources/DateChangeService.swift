import Foundation
import Combine

/// A singleton service that detects and publishes day changes.
///
/// This service listens for the `NSCalendarDayChanged` notification and
/// broadcasts an event via a Combine publisher. This allows multiple
/// view models to subscribe to a single source of truth for date changes,
/// ensuring all date-sensitive UI components refresh consistently and efficiently.
public class DateChangeService {
    
    /// The shared singleton instance of the service.
    public static let shared = DateChangeService()
    
    /// A Combine publisher that emits a `Void` event when the system day changes.
    public let dayDidChange = PassthroughSubject<Void, Never>()
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDayChange),
            name: .NSCalendarDayChanged,
            object: nil
        )
        #if DEBUG
        print("DateChangeService initialized and listening for day changes.")
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .NSCalendarDayChanged, object: nil)
    }
    
    @objc private func handleDayChange() {
        #if DEBUG
        print("DateChangeService detected a day change. Broadcasting notification.")
        #endif
        // Ensure the notification is sent on the main thread, as it will trigger UI updates.
        DispatchQueue.main.async {
            self.dayDidChange.send(())
        }
    }
}
