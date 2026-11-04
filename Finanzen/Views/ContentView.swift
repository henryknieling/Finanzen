import SwiftUI

struct ContentView: View {
    @StateObject private var store = FinanceStore()
    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some View {
        TabView {
            TodayView(store: store)
                .tabItem { Label("Heute", systemImage: "sun.max") }

            MonthView(store: store)
                .tabItem { Label("Monat", systemImage: "calendar") }

            SettingsView(viewModel: settingsViewModel)
                .tabItem { Label("Einstellungen", systemImage: "gearshape") }
        }
        .preferredColorScheme(settingsViewModel.colorScheme)
        .task {
            BudgetReminderScheduler.refreshIfEnabled()
        }
    }
}
