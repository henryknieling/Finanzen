import SwiftUI

struct MonthView: View {
    @StateObject private var viewModel: MonthViewModel
    @State private var showingHistory = false
    @FocusState private var budgetFieldFocused: Bool

    init(store: FinanceStore) {
        _viewModel = StateObject(wrappedValue: MonthViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Button { moveMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                            .accessibilityLabel("Vorheriger Monat")
                        Spacer()
                        Text(viewModel.title)
                            .font(.title2.bold())
                        Spacer()
                        Button { moveMonth(by: 1) } label: { Image(systemName: "chevron.right") }
                            .accessibilityLabel("Nächster Monat")
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.hasBudget ? "Monatsbudget" : "Monatsbudget festlegen")
                                .font(.title2.bold())
                            if !viewModel.hasBudget {
                                Text("Lege zuerst dein Budget fest. Danach siehst du hier die Aufteilung für den Monat.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        budgetInputCard

                        Button(action: saveBudget) {
                            Label("Budget speichern", systemImage: "checkmark")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.navy)

                        DatePicker(
                            "Aufteilung beginnt am",
                            selection: Binding(
                                get: { viewModel.budgetStartDate },
                                set: viewModel.setBudgetStartDate
                            ),
                            in: viewModel.budgetStartRange,
                            displayedComponents: .date
                        )
                        .environment(\.locale, Locale(identifier: "de_DE"))

                        if viewModel.hasBudget {
                            monthlyProgress

                            Divider()

                            HStack {
                                summaryItem("Ausgegeben", amount: viewModel.spent)
                                Spacer()
                                summaryItem("Übrig", amount: viewModel.remaining)
                            }

                            HStack(alignment: .firstTextBaseline) {
                                Text(viewModel.dailyBudgetTitle)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(viewModel.dailyAvailable, format: .currency(code: "EUR").locale(Locale(identifier: "de_DE")))
                                    .font(.title2.bold())
                                    .foregroundStyle(viewModel.dailyAvailable < 0 ? .red : .primary)
                            }
                            Text("Der Restbetrag wird ab dem gewählten Starttag gleichmäßig auf die verbleibenden Tage verteilt.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.navy.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if budgetFieldFocused {
                    HStack {
                        Spacer()
                        Button("Fertig", systemImage: "keyboard.chevron.down") {
                            budgetFieldFocused = false
                        }
                        .font(.body.weight(.semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.bar)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Monatsbudget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingHistory = true } label: { Image(systemName: "clock.arrow.circlepath") }
                        .accessibilityLabel("Verlauf anzeigen")
                }
            }
            .onAppear(perform: focusIfBudgetIsMissing)
            .sheet(isPresented: $showingHistory) {
                HistoryView(store: viewModel.store)
            }
        }
    }

    private var budgetInputCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("MONATSBUDGET IN €")
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.72))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("0,00", text: $viewModel.budgetInput)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .focused($budgetFieldFocused)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .tint(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("€")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.navy, Color.navy.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }

    private var monthlyProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: viewModel.spendingProgress)
                .tint(.navy)
            HStack {
                Text("Monatsfortschritt")
                Spacer()
                Text("\(viewModel.spendingPercentage) % ausgegeben")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text(viewModel.spent, format: .currency(code: "EUR").locale(Locale(identifier: "de_DE")))
                Text("von")
                Text(viewModel.budget, format: .currency(code: "EUR").locale(Locale(identifier: "de_DE")))
                Text("ausgegeben")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func summaryItem(_ title: String, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(amount, format: .currency(code: "EUR").locale(Locale(identifier: "de_DE")))
                .font(.headline)
                .foregroundStyle(amount < 0 ? .red : .primary)
        }
    }

    private func moveMonth(by offset: Int) {
        viewModel.moveMonth(by: offset)
        focusIfBudgetIsMissing()
    }

    private func focusIfBudgetIsMissing() {
        guard !viewModel.hasBudget else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            budgetFieldFocused = true
        }
    }

    private func saveBudget() {
        guard viewModel.saveBudget() else { return }
        budgetFieldFocused = false
    }
}
