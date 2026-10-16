import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingItem.name) private var items: [ShoppingItem]

    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var showAddItem = false
    @State private var showAddSaveError = false
    @State private var itemName = ""
    @State private var itemAmount: Double?
    @State private var itemUnit: Ingredient.Unit?

    private var sortedItems: [ShoppingItem] {
        items.sorted { first, second in
            if first.checked != second.checked {
                return !first.checked
            }
            return first.name.localizedCaseInsensitiveCompare(second.name)
                == .orderedAscending
        }
    }

    private var completedItems: [ShoppingItem] {
        items.filter(\.checked)
    }

    private var canAddItem: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (itemAmount.map { $0 > 0 } ?? true)
    }

    private func formattedAmount(for item: ShoppingItem) -> String? {
        guard let value = item.amount else { return nil }

        let amount = value.formatted(
            .number.precision(.fractionLength(0...2))
        )
        guard let unit = item.unit else { return amount }
        return "\(amount) \(unit.rawValue)"
    }

    private func cancelAddItem() {
        itemName = ""
        itemAmount = nil
        itemUnit = nil
        showAddItem = false
    }

    private func addItem() {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              itemAmount.map({ $0 > 0 }) ?? true else {
            return
        }

        do {
            try ShoppingListManager.add(
                [
                    ShoppingListEntry(
                        name: trimmedName,
                        amount: itemAmount,
                        unit: itemUnit
                    )
                ],
                to: modelContext
            )
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            showAddSaveError = true
            return
        }

        itemName = ""
        itemAmount = nil
        itemUnit = nil
        showAddItem = false
    }

    private func toggle(_ item: ShoppingItem) {
        item.checked.toggle()
        saveChanges()
    }

    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            modelContext.delete(sortedItems[offset])
        }
        saveChanges()
    }

    private func clearCompleted() {
        completedItems.forEach { modelContext.delete($0) }
        saveChanges()
    }

    @discardableResult
    private func saveChanges() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            showSaveError = true
            return false
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Einkäufe",
                        systemImage: "cart",
                        description: Text("Füge Zutaten aus Rezepten hinzu.")
                    )
                } else {
                    List {
                        ForEach(sortedItems) { item in
                            Button {
                                toggle(item)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(
                                        systemName: item.checked
                                            ? "checkmark.circle.fill"
                                            : "circle"
                                    )
                                    .foregroundStyle(
                                        item.checked ? Color.accentColor : .secondary
                                    )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .strikethrough(item.checked)
                                            .foregroundStyle(
                                                item.checked ? .secondary : .primary
                                            )
                                        if let amount = formattedAmount(for: item) {
                                            Text(amount)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.name)
                            .accessibilityValue(
                                item.checked ? "Erledigt" : "Nicht erledigt"
                            )
                            .accessibilityHint(
                                item.checked
                                    ? "Als nicht erledigt markieren"
                                    : "Als erledigt markieren"
                            )
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Einkäufe")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !completedItems.isEmpty {
                        Button("Erledigte löschen", systemImage: "trash") {
                            clearCompleted()
                        }
                    }

                    Button("Eintrag hinzufügen", systemImage: "plus") {
                        showAddItem = true
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                NavigationStack {
                    Form {
                        Section("Eintrag") {
                            TextField("Name", text: $itemName)
                                .textInputAutocapitalization(.sentences)

                            TextField(
                                "Menge (optional)",
                                value: $itemAmount,
                                format: .number
                            )
                            .keyboardType(.decimalPad)

                            Picker("Einheit", selection: $itemUnit) {
                                Text("Keine")
                                    .tag(nil as Ingredient.Unit?)
                                ForEach(Ingredient.Unit.allCases) { unit in
                                    Text(unit.rawValue)
                                        .tag(Optional(unit))
                                }
                            }
                        }
                    }
                    .navigationTitle("Neuer Einkauf")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") {
                                cancelAddItem()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Hinzufügen") {
                                addItem()
                            }
                            .disabled(!canAddItem)
                        }
                    }
                }
                .presentationDetents([.medium])
                .alert(
                    "Eintrag konnte nicht gespeichert werden",
                    isPresented: $showAddSaveError
                ) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(saveErrorMessage)
                }
                .interactiveDismissDisabled(
                    !itemName.isEmpty || itemAmount != nil || itemUnit != nil
                )
            }
            .alert(
                "Einkaufsliste konnte nicht gespeichert werden",
                isPresented: $showSaveError
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
        }
    }
}

#Preview {
    ShoppingListView()
}
