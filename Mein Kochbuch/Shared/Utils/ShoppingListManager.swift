import Foundation
import SwiftData

struct ShoppingListEntry {
    let name: String
    let amount: Double?
    let unit: Ingredient.Unit?
}

@MainActor
enum ShoppingListManager {
    static func add(
        _ entries: [ShoppingListEntry],
        to modelContext: ModelContext
    ) throws {
        var shoppingItems = try modelContext.fetch(
            FetchDescriptor<ShoppingItem>()
        )

        for entry in entries {
            let trimmedName = entry.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !trimmedName.isEmpty else { continue }

            if let existingItem = shoppingItems.first(where: {
                $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
                    && $0.unit == entry.unit
            }) {
                if let amount = entry.amount {
                    existingItem.amount = (existingItem.amount ?? 0) + amount
                }
                existingItem.checked = false
            } else {
                let item = ShoppingItem(
                    name: trimmedName,
                    amount: entry.amount,
                    unit: entry.unit
                )
                modelContext.insert(item)
                shoppingItems.append(item)
            }
        }

        try modelContext.save()
    }
}
