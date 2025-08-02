
import Foundation

extension CalendarViewModel {
    func isHolidayOrSaturday(date: Date) -> Bool {
        if date.isSaturday() {
            return true
        }
        
        guard let nepaliDate = DateConverter.toNepaliDate(from: date) else {
            return false
        }
        
        return isTodayHoliday(date: nepaliDate)
    }

    func event(for date: Date) -> String? {
        guard let nepaliDate = DateConverter.toNepaliDate(from: date) else {
            return nil
        }
        return getTodayEvent(date: nepaliDate)
    }

    func tithi(for date: Date) -> String? {
        guard let nepaliDate = DateConverter.toNepaliDate(from: date) else {
            return nil
        }
        return getTodayTithi(date: nepaliDate)
    }
}
