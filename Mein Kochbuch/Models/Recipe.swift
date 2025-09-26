//
//  Recipe.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftData
import Foundation

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var title: String
    var summary: String
    var servings: Int
    var totalMinutes: Int
    var tags: [String]
    var imageData: Data?
    @Relationship(.cascade) var ingredients: [Ingredient]
    @Relationship(.cascade) var instructions: [RepiceStep]
    
    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        servings: Int,
        totalMinutes: Int,
        tags: [String] = [],
        imageData: Data? = nil,
        ingredients: [Ingredient] = [],
        instructions: [RepiceStep] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.servings = servings
        self.totalMinutes = totalMinutes
        self.tags = tags
        self.imageData = imageData
        self.ingredients = ingredients
        self.steps steps
        
    }
    
}
@Model
final class Ingredient {
    var name: String
    var amount: Double
    var unit: Unit
    
    enum Unit: String, Codable, CaseIterable, Identifiable {
    case g, kg, mi, l,tsp,tbsp, pcs
    var id: String { rawValue }
    }
    init(name: String, amount: Double, unit: Unit) {
        self.name = name
        self.amount = amount
        self.unit = unit
    }
}

@Model
final class RepiceStep {
    var index : Int
    var text: String
    var minutes: Int?
    
    init(index: Int, text: String, minutes: Int? = nil) {
        self.index = index
        self.text = text
        self.minutes = minutes
    }
    
}

@Model
final class ShoppingItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Double?
    var unit: Ingredient.Unit?
    var Checked: Bool
    
    init(id: UUID, name: String, amount: Double? = nil, unit: Ingredient.Unit? = nil, Checked: Bool) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.Checked = Checked
    }
}
