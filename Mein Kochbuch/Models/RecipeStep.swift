//
//  RecipeStep.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftData
@Model
final class RecipeStep {
    var index: Int
    var text: String
    var minutes: Int?
    

    init(index: Int, text: String, minutes: Int? = nil) {
        self.index = index
        self.text = text
        self.minutes = minutes
    }
}
