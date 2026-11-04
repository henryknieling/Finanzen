import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") }
    }

    @Published var monthlyReminderEnabled: Bool {
        didSet { BudgetReminderScheduler.setEnabled(monthlyReminderEnabled) }
    }

    init() {
        theme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "system") ?? .system
        monthlyReminderEnabled = UserDefaults.standard.bool(forKey: BudgetReminderScheduler.enabledKey)
    }

    var colorScheme: ColorScheme? { theme.colorScheme }
}
