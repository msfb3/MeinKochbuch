//
//  RecipeListView.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftUI
import SwiftData
import Observation

struct RecipeListView: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.title, order: .forward) private var recipes: [Recipe]
    
    enum SortOption: String, CaseIterable, Identifiable {
        case titleAsc = "Titel A–Z"
        case titleDesc = "Titel Z–A"
        case timeAsc = "Zeit ↑"
        case timeDesc = "Zeit ↓"
        var id: Self { self }
    }
    @State private var sort: SortOption = .titleAsc
    @State private var selectedTag: String? = nil

    private var allTags: [String] {
        let set = Set(recipes.flatMap { $0.tags })
        return Array(set).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func delete(_ recipe: Recipe) {
        modelContext.delete(recipe)
    }
    
    private var filtered: [Recipe] {
        var base = recipes
        if !app.searchText.isEmpty {
            base = base.filter { r in
                r.title.localizedCaseInsensitiveContains(app.searchText)
                || r.tags.contains(where: { $0.localizedCaseInsensitiveContains(app.searchText) })
            }
        }
        if let tag = selectedTag {
            base = base.filter { $0.tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame } }
        }
        switch sort {
        case .titleAsc:
            return base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDesc:
            return base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .timeAsc:
            return base.sorted { $0.totalMinutes < $1.totalMinutes }
        case .timeDesc:
            return base.sorted { $0.totalMinutes > $1.totalMinutes }
        }
    }
    var body: some View {
        @Bindable var app = app
        NavigationStack {
            List {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Rezepte",
                        systemImage: "book",
                        description: Text("Erstelle ein neues Rezept, indem du auf '+' klickst.") )
                }
                ForEach(filtered, id: \.id) { recipe in
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
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            delete(recipe)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let recipe = filtered[index]
                        delete(recipe)
                    }
                }
            }
            .navigationTitle("Rezepte")
            .searchable(text: $app.searchText, prompt: "Suche nach Rezepten")
            .searchSuggestions {
                if app.searchText.isEmpty {
                    ForEach(allTags, id: \.self) { tag in
                        Text(tag).searchCompletion(tag)
                    }
                } else {
                    let titleMatches = Array(recipes.map(\.title).filter { $0.localizedCaseInsensitiveContains(app.searchText) }.prefix(5))
                    ForEach(titleMatches, id: \.self) { title in
                        Text(title).searchCompletion(title)
                    }
                    let tagMatches = Array(allTags.filter { $0.localizedCaseInsensitiveContains(app.searchText) }.prefix(5))
                    ForEach(tagMatches, id: \.self) { tag in
                        Text(tag).searchCompletion(tag)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { RecipeEditView() } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Menu {
                        Picker("Sortierung", selection: $sort) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sortieren", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Menu {
                        Button("Alle Tags") { selectedTag = nil }
                        ForEach(allTags, id: \.self) { tag in
                            Button(tag) { selectedTag = tag }
                        }
                    } label: {
                        if let tag = selectedTag {
                            Label(tag, systemImage: "line.3.horizontal.decrease.circle")
                        } else {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
        }
    }
}
