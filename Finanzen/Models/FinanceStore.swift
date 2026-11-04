import Foundation
import Combine

@MainActor
final class FinanceStore: ObservableObject {
    @Published private(set) var expenses: [Expense] = []
    @Published private(set) var monthlyBudgets: [String: Double] = [:]
    @Published private(set) var budgetStartDates: [String: Date] = [:]
    let undoManager = UndoManager()

    private let defaults = UserDefaults.standard
    private let expensesKey = "finanzen.expenses"
    private let budgetsKey = "finanzen.monthlyBudgets"
    private let budgetStartDatesKey = "finanzen.budgetStartDates"
    private let calendar = Calendar.current

    init() {
        if let data = defaults.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
        if let data = defaults.data(forKey: budgetsKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            monthlyBudgets = decoded
        }
        if let data = defaults.data(forKey: budgetStartDatesKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            budgetStartDates = decoded
        }
    }

    func monthKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "de_DE")))
    }

    func budget(for month: Date) -> Double {
        monthlyBudgets[monthKey(for: month)] ?? 0
    }

    func hasBudget(for month: Date) -> Bool {
        monthlyBudgets[monthKey(for: month)] != nil
    }

    func setBudget(_ amount: Double, for month: Date) {
        monthlyBudgets[monthKey(for: month)] = max(0, amount)
        saveBudgets()
    }

    func budgetStartDate(for month: Date) -> Date {
        budgetStartDates[monthKey(for: month)] ?? calendar.dateInterval(of: .month, for: month)?.start ?? month
    }

    func setBudgetStartDate(_ date: Date, for month: Date) {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return }
        let lastDay = interval.end.addingTimeInterval(-1)
        let clampedDate = min(max(calendar.startOfDay(for: date), interval.start), lastDay)
        budgetStartDates[monthKey(for: month)] = clampedDate
        saveBudgetStartDates()
    }

    func expenses(in month: Date) -> [Expense] {
        expenses
            .filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            .sorted { $0.date > $1.date }
    }

    func spent(in month: Date) -> Double {
        expenses(in: month).reduce(0) { $0 + $1.amount }
    }

    func spent(on day: Date) -> Double {
        expenses
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .reduce(0) { $0 + $1.amount }
    }

    /// The amount allocated to the selected day before that day's spending.
    func dailyLimit(on date: Date, startingFrom selectedStartDate: Date? = nil) -> Double {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return 0 }
        let configuredStart = calendar.startOfDay(for: selectedStartDate ?? budgetStartDate(for: date))
        let isCurrentMonth = calendar.isDate(date, equalTo: .now, toGranularity: .month)
        let dayStart = calendar.startOfDay(for: date)

        if isCurrentMonth && dayStart >= configuredStart {
            let effectiveStart = max(configuredStart, dayStart)
            let spentBeforeToday = expenses(in: date)
                .filter { $0.date < dayStart }
                .reduce(0) { $0 + $1.amount }
            let balanceAtStartOfDay = budget(for: date) - spentBeforeToday
            let days = calendar.dateComponents([.day], from: effectiveStart, to: interval.end).day ?? 1
            return balanceAtStartOfDay / Double(max(days, 1))
        }

        let remaining = budget(for: date) - spent(in: date)
        let days = calendar.dateComponents([.day], from: configuredStart, to: interval.end).day ?? 1
        return remaining / Double(max(days, 1))
    }

    /// Today's unspent allocation; spending above the limit produces a negative value.
    func dailyAvailable(on date: Date, startingFrom selectedStartDate: Date? = nil) -> Double {
        let configuredStart = calendar.startOfDay(for: selectedStartDate ?? budgetStartDate(for: date))
        let dayStart = calendar.startOfDay(for: date)
        guard calendar.isDate(date, equalTo: .now, toGranularity: .month), dayStart >= configuredStart else {
            return dailyLimit(on: date, startingFrom: selectedStartDate)
        }
        return dailyLimit(on: date, startingFrom: selectedStartDate) - spent(on: date)
    }

    func add(_ expense: Expense) {
        expenses.append(expense)
        saveExpenses()
    }

    func update(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        saveExpenses()
    }

    func delete(_ expense: Expense, using manager: UndoManager? = nil) {
        remove(expense, using: manager ?? undoManager)
    }

    private func remove(_ expense: Expense, using manager: UndoManager) {
        guard expenses.contains(where: { $0.id == expense.id }) else { return }
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
        manager.registerUndo(withTarget: self) { store in
            store.restore(expense, using: manager)
        }
        manager.setActionName("Ausgabe löschen")
    }

    private func restore(_ expense: Expense, using manager: UndoManager) {
        guard !expenses.contains(where: { $0.id == expense.id }) else { return }
        expenses.append(expense)
        saveExpenses()
        manager.registerUndo(withTarget: self) { store in
            store.remove(expense, using: manager)
        }
        manager.setActionName("Ausgabe wiederherstellen")
    }

    private func saveExpenses() {
        guard let data = try? JSONEncoder().encode(expenses) else { return }
        defaults.set(data, forKey: expensesKey)
    }

    private func saveBudgets() {
        guard let data = try? JSONEncoder().encode(monthlyBudgets) else { return }
        defaults.set(data, forKey: budgetsKey)
    }

    private func saveBudgetStartDates() {
        guard let data = try? JSONEncoder().encode(budgetStartDates) else { return }
        defaults.set(data, forKey: budgetStartDatesKey)
    }
}
