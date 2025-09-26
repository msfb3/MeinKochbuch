//
//  RecipeDetailView.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftUI

struct RecipeDetailView: View {
    @State private var scaleServing = 0
    let recipe: Recipe
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let data = recipe.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable().scaledToFill()
                        .frame(height: 220).clipped().cornerRadius(12)
                }
            }
        }
    }
}
