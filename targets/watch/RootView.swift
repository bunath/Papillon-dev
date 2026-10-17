import SwiftUI

/// Two pages side by side: swipe sideways to go from the timetable to the
/// homework. Each page is its own scrolling list, driven by the Digital Crown.
struct RootView: View {
    var body: some View {
        TabView {
            TimetableView()
            HomeworkView()
        }
        .tabViewStyle(.page)
    }
}
