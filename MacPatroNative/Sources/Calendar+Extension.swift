
import Foundation

extension CalendarViewModel {
    func isHolidayOrSaturday(date: Date) -> Bool {
        if date.isSaturday() {
            return true
        }
        
        guard let nepaliDate = DateConverter.toNepaliDate(from: date) else {
            return false
        }
        
        return isHoliday(date: nepaliDate)
    }

    func event(for date: Date) -> String? {
        guard let nepaliDate = DateConverter.toNepaliDate(from: date) else {
            return nil
        }
        return getEvent(date: nepaliDate)
    }
}
