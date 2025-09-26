//
//  MeinKochbuchApp.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//
import SwiftUI
import SwiftData


@main
struct MeinKochbuchApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .modelContainer(for: [Recipe.self, Ingredient.self, RepiceStep.self, ShoppingItem.self])
    }
}
