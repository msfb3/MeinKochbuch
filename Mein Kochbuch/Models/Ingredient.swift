//
//  Ingredient.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftData

@Model
final class Ingredient {
    var name: String
    var amount: Double
    var unit: Unit
    
    enum Unit: String, Codable, CaseIterable, Identifiable {
        case g, kg, ml, l, tsp, tbsp, pcs
        var id: String { rawValue }
    }
    
    init(name: String, amount: Double, unit: Unit) {
        self.name = name
        self.amount = amount
        self.unit = unit
    }
}
