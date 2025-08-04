import SwiftUI
import AppKit

public struct MainView: View {
    @StateObject public var viewModel = CalendarViewModel()
    @StateObject private var menuBarViewModel = MenuBarViewModel()
    @ObservedObject private var updateService = UpdateService.shared
    @State private var showUpdateBadge = false
    
    private let settingsWindowController = SettingsWindowController()
    private let updateDismissedKey = "updateDismissed"
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            if showUpdateBadge {
                UpdateBadgeView(onDismiss: {
                    UserDefaults.standard.set(Date(), forKey: updateDismissedKey)
                    showUpdateBadge = false
                })
                .onTapGesture {
                    settingsWindowController.openSettings()
                }
            }
            TodayView(viewModel: TodayViewModel(calendarViewModel: viewModel))
            MonthSwitcherView(viewModel: viewModel)
            CalendarGridView(viewModel: viewModel)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
        .frame(maxWidth: 360)
        .onAppear {
            updateService.checkForUpdates()
        }
        .onReceive(updateService.$updateAvailable) { updateAvailable in
            if updateAvailable {
                let lastDismissed = UserDefaults.standard.object(forKey: updateDismissedKey) as? Date
                if let lastDismissed = lastDismissed {
                    if Date().timeIntervalSince(lastDismissed) > 24 * 60 * 60 {
                        self.showUpdateBadge = true
                    }
                } else {
                    self.showUpdateBadge = true
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
//            Color.black.ignoresSafeArea()
            MainView()
        }
    }
}
