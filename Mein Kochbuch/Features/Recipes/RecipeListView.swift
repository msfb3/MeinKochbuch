//
//  RecipeListView.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {
    @State private var searchText = ""
    @Query(sort: \Recipe.title, order: .forward) private var recipes: [Recipe]
    
    private var filteredRecipes: [Recipe] {
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter {r in
            r.title.localizedCaseInsensitiveContains(searchText)
            || r.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
}
