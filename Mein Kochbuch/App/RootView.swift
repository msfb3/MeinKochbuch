//
//  RootView.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            RecipeListView()
                .tabItem {
                    Label("Rezepte", systemImage: "book.closed")
                }
            ShoppingListView()
                .tabItem {
                    Label("Einkäufe", systemImage: "cart")
                }
            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
        }
    }
}
