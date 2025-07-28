
import Foundation
import SwiftUI

public class MenuBarViewModel: ObservableObject {
    @Published public var menuBarText: String = "MacPatro"
    @Published public var iconName: String = "1"
    @Published public var menuBarIconText: String = ""

    public init() {
        updateMenuBarText()
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateMenuBarText()
        }
    }

    private func updateMenuBarText() {
        menuBarText = DateFormattingService.shared.formattedDate(for: Date())
        
        let nepaliDate = DateConverter.toNepaliDate(from: Date())!
        let day = nepaliDate.bsDay
        let month = NepaliMonth(rawValue: nepaliDate.bsMonth)!.name
        let nepaliDay = NumberFormatter.nepaliString(from: day)
        menuBarIconText = "\(nepaliDay)-\(month)"
        
        iconName = nepaliDay
    }
}
