import Combine
import Foundation

@MainActor
final class MonthViewModel: ObservableObject {
    @Published private(set) var month = Calendar.current.startOfMonth(for: .now)
    @Published var budgetInput = ""

    let store: FinanceStore
    private var storeSubscription: AnyCancellable?

    init(store: FinanceStore) {
        self.store = store
        storeSubscription = store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        loadBudgetInput()
    }

    var hasBudget: Bool { store.hasBudget(for: month) }
    var budget: Double { store.budget(for: month) }
    var spent: Double { store.spent(in: month) }
    var remaining: Double { budget - spent }
    var spendingProgress: Double {
        guard budget > 0 else { return 0 }
        return min(max(spent / budget, 0), 1)
    }
    var spendingPercentage: Int {
        guard budget > 0 else { return 0 }
        return Int((spent / budget * 100).rounded())
    }
    var title: String { store.monthTitle(for: month).capitalized }
    var budgetStartDate: Date { store.budgetStartDate(for: month) }
    var budgetStartRange: ClosedRange<Date> {
        let interval = Calendar.current.dateInterval(of: .month, for: month)!
        return interval.start...interval.end.addingTimeInterval(-1)
    }
    var displayDateForBudget: Date {
        Calendar.current.isDate(month, equalTo: .now, toGranularity: .month) ? .now : month
    }
    var dailyBudgetTitle: String {
        let calendar = Calendar.current
        let effectiveStart = calendar.isDate(month, equalTo: .now, toGranularity: .month)
            ? max(budgetStartDate, calendar.startOfDay(for: .now))
            : budgetStartDate
        guard effectiveStart > calendar.startOfDay(for: .now) else { return "Pro Tag verfügbar" }
        let date = effectiveStart.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "de_DE")))
        return "Pro Tag ab \(date)"
    }

    var dailyAvailable: Double {
        store.dailyAvailable(on: displayDateForBudget, startingFrom: budgetStartDate)
    }

    func moveMonth(by offset: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: offset, to: month) else { return }
        month = Calendar.current.startOfMonth(for: next)
        loadBudgetInput()
    }

    func setBudgetStartDate(_ date: Date) {
        store.setBudgetStartDate(date, for: month)
    }

    @discardableResult
    func saveBudget() -> Bool {
        let normalized = budgetInput.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalized), amount >= 0 else { return false }
        store.setBudget(amount, for: month)
        loadBudgetInput()
        return true
    }

    func loadBudgetInput() {
        budgetInput = store.hasBudget(for: month) ? String(format: "%.2f", store.budget(for: month)) : ""
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        dateInterval(of: .month, for: date)?.start ?? date
    }
}
