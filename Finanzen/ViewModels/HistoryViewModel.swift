import Combine
import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    let store: FinanceStore
    @Published private(set) var selectedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    private var storeSubscription: AnyCancellable?

    init(store: FinanceStore) {
        self.store = store
        storeSubscription = store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var availableMonths: [Date] {
        let calendar = Calendar.current
        let months = store.expenses.map { calendar.dateInterval(of: .month, for: $0.date)?.start }
        return Set(months.compactMap { $0 } + [calendar.dateInterval(of: .month, for: .now)?.start ?? .now])
            .sorted(by: >)
    }

    var monthTitle: String {
        store.monthTitle(for: selectedMonth).capitalized
    }

    var expensesForSelectedMonth: [Expense] {
        store.expenses(in: selectedMonth)
    }

    var selectedMonthTotal: Double {
        total(for: expensesForSelectedMonth)
    }

    var groupedExpenses: [(date: Date, expenses: [Expense])] {
        let groups = Dictionary(grouping: expensesForSelectedMonth) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            (day, groups[day, default: []].sorted { $0.date > $1.date })
        }
    }

    func selectMonth(_ month: Date) {
        selectedMonth = Calendar.current.dateInterval(of: .month, for: month)?.start ?? month
    }

    func isCurrentMonth(_ month: Date) -> Bool {
        Calendar.current.isDate(month, equalTo: .now, toGranularity: .month)
    }

    func total(for expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
}
