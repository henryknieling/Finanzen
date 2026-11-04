import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?

    init(store: FinanceStore) {
        _viewModel = StateObject(wrappedValue: TodayViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 22) {
                        VStack(spacing: 8) {
                            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE"))).capitalized)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(viewModel.dailyAvailable, format: .currency(code: "EUR").locale(Locale(identifier: "de_DE")))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.dailyAvailable < 0 ? .red : .primary)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                            Text("Heute verfügbar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color.navy.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))

                        VStack(spacing: 14) {
                            VStack(spacing: 12) {
                                budgetDetailRow("Tageslimit", amount: viewModel.dailyLimit)
                                Divider()
                                budgetDetailRow("Heute ausgegeben", amount: viewModel.spentToday)
                                Divider()
                                budgetDetailRow("Morgen verfügbar", amount: viewModel.tomorrowLimit)
                            }
                            .padding(16)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))

                            Button { showingAddExpense = true } label: {
                                Label("Ausgabe", systemImage: "plus")
                                    .font(.headline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .foregroundStyle(.white)
                                    .background(Color.navy, in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section("Heutige Ausgaben") {
                    if viewModel.expenses.isEmpty {
                        ContentUnavailableView("Keine Ausgaben", systemImage: "eurosign.circle", description: Text("Füge deine erste Ausgabe hinzu."))
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.expenses) { expense in
                            ExpenseEntry(store: viewModel.store, expense: expense) {
                                selectedExpense = expense
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Mein Budget")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddExpense) {
                ExpenseEditorView(store: viewModel.store, expense: nil)
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseEditorView(store: viewModel.store, expense: expense)
            }
        }
    }

    private func budgetDetailRow(_ title: String, amount: Double) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(amount, format: .currency(code: "EUR").locale(Locale(identifier: "de_DE")))
                .fontWeight(.semibold)
                .foregroundStyle(amount < 0 ? .red : .primary)
        }
    }
}
