import SwiftUI

struct ExpenseEntry: View {
    @Environment(\.undoManager) private var undoManager
    @State private var showingDeleteConfirmation = false

    let store: FinanceStore
    let expense: Expense
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ExpenseRow(expense: expense)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                showingDeleteConfirmation = true
            } label: {
                Label("Löschen", systemImage: "trash")
            }
            .tint(.red)
        }
        .popover(isPresented: $showingDeleteConfirmation, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Wirklich löschen?")
                    .font(.headline)
                Text("Möchtest du diese Ausgabe löschen?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Button("Abbrechen") {
                        showingDeleteConfirmation = false
                    }
                    .buttonStyle(.bordered)

                    Button("Löschen", systemImage: "trash", role: .destructive) {
                        store.delete(expense, using: undoManager)
                        showingDeleteConfirmation = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding(20)
            .frame(width: 300)
            .presentationCompactAdaptation(.popover)
        }
    }
}
