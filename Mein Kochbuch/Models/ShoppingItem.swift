//
//  ShoppingItem.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftData
import Foundation

@Model
final class ShoppingItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Double
    var unit: Ingredient.Unit?
    var checked: Bool
    
    init(id: UUID, name: String, amount: Double, unit: Ingredient.Unit? = nil, checked: Bool) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.checked = checked
    }
}
