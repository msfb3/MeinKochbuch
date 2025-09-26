//
//  RecipeListView.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(AppState.self) private var app
    @Query(sort: \Recipe.title, order: .forward) private var recipes: [Recipe]
    
    private var filtered: [Recipe] {
        guard !app.searchText.isEmpty else { return recipes }
        return recipes.filter { r in
            r.title.localizedCaseInsensitiveContains(app.searchText)
            || r.tags.contains(where: { $0.localizedCaseInsensitiveContains(app.searchText) })
        }
    }
    var body: some View {
        NavigationStack {
            List {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Rezepte",
                        systemImage: "book",
                        description: Text("Erstelle ein neues Rezept, indem du auf '+' klickst.") )
                }
                ForEach(filtered, id: \ .id) { recipe in
                    NavigationLink(value: recipe) {
                        HStack(spacing: 12) {
                            RecipeThumbnail(imageData: recipe.imageData)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title).font(.headline)
                                Text("\(recipe.totalMinutes)• Min \(recipe.servings) Portionen.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                if !recipe.tags.isEmpty {
                                    Text(recipe.tags.joined(separator: ", "))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rezepte")
            .searchable(text: $app.searchText, prompt: "Suche nach Rezepten")
            .toolbar {
                NavigationLink { RecipeEditView() } label: {
                Image(systemName: "plus")
                        
                }
                .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0)}
            }
        }
    }
}
