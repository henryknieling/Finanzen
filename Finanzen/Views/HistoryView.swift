import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExpense: Expense?

    init(store: FinanceStore) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Monate") {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.availableMonths, id: \.self) { month in
                                let isSelected = Calendar.current.isDate(month, equalTo: viewModel.selectedMonth, toGranularity: .month)
                                Button {
                                    viewModel.selectMonth(month)
                                } label: {
                                    Text(month.formatted(.dateTime.month(.abbreviated).year().locale(Locale(identifier: "de_DE"))).capitalized)
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .foregroundStyle(isSelected ? .white : .primary)
                                        .background(isSelected ? Color.navy : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(viewModel.monthTitle)
                                .font(.headline)
                            Text(viewModel.expensesForSelectedMonth.count == 1 ? "1 Ausgabe" : "\(viewModel.expensesForSelectedMonth.count) Ausgaben")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(viewModel.selectedMonthTotal, format: .currency(code: "EUR").locale(Locale(identifier: "de_DE")))
                            .font(.title3.bold())
                            .foregroundStyle(Color.navy)
                    }
                    .padding(.vertical, 5)
                }

                if viewModel.groupedExpenses.isEmpty {
                    ContentUnavailableView(
                        viewModel.isCurrentMonth(viewModel.selectedMonth) ? "Noch keine Ausgaben diesen Monat" : "Keine Ausgaben in diesem Monat",
                        systemImage: "clock",
                        description: Text("Wähle einen anderen Monat aus, um dessen Ausgaben anzusehen.")
                    )
                } else {
                    ForEach(viewModel.groupedExpenses, id: \.date) { group in
                        Section {
                            ForEach(group.expenses) { expense in
                                ExpenseEntry(store: viewModel.store, expense: expense) {
                                    selectedExpense = expense
                                }
                            }
                        } header: {
                            HStack {
                                Text(group.date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE"))).capitalized)
                                Spacer()
                                Text(viewModel.total(for: group.expenses), format: .currency(code: "EUR").locale(Locale(identifier: "de_DE")))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ausgaben")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedExpense) { expense in
                ExpenseEditorView(store: viewModel.store, expense: expense)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Schließen")
                }
            }
        }
    }
}
