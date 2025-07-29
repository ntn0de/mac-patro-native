import SwiftUI
import MacPatroKit

@main
struct MacPatroNativeApp: App {
    @StateObject private var menuBarViewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra {
            MainView()
                .frame(width: 360)
        } label: {
            Text(menuBarViewModel.menuBarIconText)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
        }
    }
}
