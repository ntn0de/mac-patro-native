import SwiftUI

public struct MainView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @StateObject private var menuBarViewModel = MenuBarViewModel()
    @State private var showAboutView = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            TodayView(viewModel: TodayViewModel(calendarViewModel: viewModel))
            MonthSwitcherView(viewModel: viewModel)
            CalendarGridView(viewModel: viewModel)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.05))
        .frame(maxWidth: 360)
        .preferredColorScheme(.dark)
        .contextMenu {
//            Button("About") {
//                showAboutView.toggle()
//            }
//            Button("Settings") {
//                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
//            }
            Button("Force update year data") {
                viewModel.forceRefresh()
            }
        }
        .sheet(isPresented: $showAboutView) {
            AboutView()
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
