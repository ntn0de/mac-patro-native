import Foundation

extension Date {
    func isSaturday() -> Bool {
        return Calendar.nepal.component(.weekday, from: self) == 7
    }
}