import Foundation

extension Date {
    func isSaturday() -> Bool {
        return Calendar.current.component(.weekday, from: self) == 7
    }
}