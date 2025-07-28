
import Foundation

// MARK: - NumberFormatter Extension
extension NumberFormatter {
    static let nepaliFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ne_NP")
        return formatter
    }()
    
    static func nepaliString(from number: Int) -> String {
        return nepaliFormatter.string(from: NSNumber(value: number)) ?? ""
    }
}

