import SwiftUI

struct ExpenseEditorView: View {
    @StateObject private var viewModel: ExpenseEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFieldFocused: Bool
    @State private var showingDeleteConfirmation = false

    init(store: FinanceStore, expense: Expense?, defaultDate: Date = .now) {
        _viewModel = StateObject(wrappedValue: ExpenseEditorViewModel(store: store, expense: expense, defaultDate: defaultDate))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("BETRAG")
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.72))
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            TextField("0,00", text: $viewModel.amountText)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .focused($amountFieldFocused)
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
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
                    .background(
                        LinearGradient(colors: [.navy, Color.navy.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 24)
                    )

                    VStack(alignment: .leading, spacing: 0) {
                        Text("DETAILS")
                            .font(.caption.weight(.bold))
                            .tracking(1.1)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 18)
                            .padding(.top, 18)
                            .padding(.bottom, 8)

                        HStack {
                            Label("Kategorie", systemImage: "square.grid.2x2")
                                .foregroundStyle(.primary)
                            Spacer()
                            Picker("Kategorie", selection: $viewModel.category) {
                                ForEach(viewModel.categories, id: \.self) { category in
                                    Label(category, systemImage: ExpenseCategory.icon(for: category))
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .tint(.navy)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)

                        Divider().padding(.leading, 18)

                        HStack(spacing: 12) {
                            Image(systemName: "text.alignleft")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            TextField("Notiz (optional)", text: $viewModel.note)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)

                        Divider().padding(.leading, 18)

                        DatePicker("Datum", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))

                    if viewModel.original != nil {
                        Button("Ausgabe löschen", systemImage: "trash", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(viewModel.original == nil ? "Neue Ausgabe" : "Ausgabe bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                guard viewModel.shouldFocusAmount else { return }
                try? await Task.sleep(for: .milliseconds(300))
                amountFieldFocused = true
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if amountFieldFocused {
                    HStack {
                        Spacer()
                        Button("Fertig", systemImage: "keyboard.chevron.down") {
                            amountFieldFocused = false
                        }
                        .font(.body.weight(.semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.bar)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Abbrechen")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) { Image(systemName: "checkmark") }
                        .accessibilityLabel("Sichern")
                        .disabled(!viewModel.canSave)
                }
            }
            .confirmationDialog("Wirklich löschen?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Löschen", role: .destructive, action: delete)
                Button("Abbrechen", role: .cancel) { }
            }
        }
    }

    private func save() {
        guard viewModel.save() else { return }
        dismiss()
    }

    private func delete() {
        viewModel.delete()
        dismiss()
    }
}
