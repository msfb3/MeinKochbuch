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
    @Relationship(.cascade) var steps: [RecipeStep]
    
    init(
        id: UUID = UUID(),
        title: String,
        summary: String = "",
        servings: Int = 2,
        totalMinutes: Int = 30,
        tags: [String] = [],
        imageData: Data? = nil,
        ingredients: [Ingredient] = [],
        steps: [RecipeStep] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.servings = servings
        self.totalMinutes = totalMinutes
        self.tags = tags
        self.imageData = imageData
        self.ingredients = ingredients
        self.steps = steps
        
    }
}
