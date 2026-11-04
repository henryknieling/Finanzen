import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ExpenseCategory.icon(for: expense.category))
                .font(.headline)
                .foregroundStyle(Color.navy)
                .frame(width: 38, height: 38)
                .background(Color.navy.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.category.isEmpty ? "Sonstiges" : expense.category)
                    .font(.body.weight(.medium))
                if !expense.note.isEmpty {
                    Text(expense.note).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                } else {
                    Text(expense.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(expense.amount, format: .currency(code: "EUR").locale(Locale(identifier: "de_DE")))
                .fontWeight(.semibold)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

}
