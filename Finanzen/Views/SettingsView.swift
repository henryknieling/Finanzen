import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Darstellung") {
                    Picker("Erscheinungsbild", selection: $viewModel.theme) {
                        ForEach(AppTheme.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }
                Section("Erinnerungen") {
                    Toggle("Monatsbudget erinnern", isOn: $viewModel.monthlyReminderEnabled)
                    Text("Erinnert dich am Monatsersten um 9 Uhr daran, dein Budget festzulegen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Allgemein") {
                    LabeledContent("Währung", value: "Euro (€)")
                    LabeledContent("Sprache", value: "Deutsch")
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
