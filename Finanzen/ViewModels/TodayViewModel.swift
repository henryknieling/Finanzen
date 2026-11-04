import Combine
import Foundation

@MainActor
final class TodayViewModel: ObservableObject {
    let store: FinanceStore
    private var storeSubscription: AnyCancellable?

    init(store: FinanceStore) {
        self.store = store
        storeSubscription = store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var expenses: [Expense] {
        store.expenses.filter { Calendar.current.isDateInToday($0.date) }.sorted { $0.date > $1.date }
    }

    var dailyLimit: Double { store.dailyLimit(on: .now) }
    var dailyAvailable: Double { store.dailyAvailable(on: .now) }
    var spentToday: Double { store.spent(on: .now) }

    var tomorrowLimit: Double {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        return store.dailyLimit(on: tomorrow)
    }

    func delete(_ expense: Expense, using undoManager: UndoManager?) {
        store.delete(expense, using: undoManager)
    }
}
