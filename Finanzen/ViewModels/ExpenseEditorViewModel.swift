import Combine
import Foundation

@MainActor
final class ExpenseEditorViewModel: ObservableObject {
    @Published var amountText: String
    @Published var category: String
    @Published var note: String
    @Published var date: Date

    let original: Expense?
    let categories = ["Sonstiges", "Lebensmittel", "Transport", "Wohnen", "Freizeit", "Gesundheit"]

    private let store: FinanceStore

    init(store: FinanceStore, expense: Expense?, defaultDate: Date = .now) {
        self.store = store
        original = expense
        amountText = expense.map { String(format: "%.2f", $0.amount) } ?? ""
        category = expense?.category.isEmpty == false ? expense!.category : "Sonstiges"
        note = expense?.note ?? ""
        date = expense?.date ?? defaultDate
    }

    var shouldFocusAmount: Bool { original == nil }
    var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }
    var canSave: Bool { (parsedAmount ?? 0) > 0 }

    func save() -> Bool {
        guard let amount = parsedAmount, amount > 0 else { return false }
        let expense = Expense(
            id: original?.id ?? UUID(),
            amount: amount,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date
        )
        if original == nil {
            store.add(expense)
        } else {
            store.update(expense)
        }
        return true
    }

    func delete() {
        guard let original else { return }
        store.delete(original)
    }
}
