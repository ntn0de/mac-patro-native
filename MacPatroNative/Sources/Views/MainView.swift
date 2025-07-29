import SwiftUI

public struct MainView: View {
    @StateObject public var viewModel = CalendarViewModel()
    @StateObject private var menuBarViewModel = MenuBarViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            TodayView(viewModel: TodayViewModel(calendarViewModel: viewModel))
            MonthSwitcherView(viewModel: viewModel)
            CalendarGridView(viewModel: viewModel)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
        .frame(maxWidth: 360)
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
