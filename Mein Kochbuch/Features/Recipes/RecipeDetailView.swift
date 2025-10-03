//
//  RecipeDetailView.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let recipe: Recipe

    @State private var targetServings: Int
    @State private var showDeleteAlert = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _targetServings = State(initialValue: recipe.servings)
    }

    private var factor: Double {
        guard recipe.servings > 0 else { return 1 }
        return Double(targetServings) / Double(recipe.servings)
    }

    private func formattedAmount(_ amount: Double) -> String {
        let value = amount * factor
        if abs(value.rounded() - value) < 0.001 {
            return String(Int(value.rounded()))
        } else {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        }
    }

    private var sortedIngredients: [Ingredient] {
        recipe.ingredients
    }

    private var sortedSteps: [RecipeStep] {
        recipe.steps.sorted { $0.index < $1.index }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header image
                if let data = recipe.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                        .cornerRadius(12)
                        .accessibilityLabel("Rezeptbild")
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                            .frame(height: 160)
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityHidden(true)
                }

                // Title & summary
                Text(recipe.title)
                    .font(.largeTitle)
                    .bold()
                if !recipe.summary.isEmpty {
                    Text(recipe.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                // Tags
                if !recipe.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recipe.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(.ultraThinMaterial))
                            }
                        }
                    }
                    .accessibilityLabel("Tags")
                }

                // Info and servings control
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("\(recipe.totalMinutes) Min", systemImage: "clock")
                        Spacer()
                        Label("\(recipe.servings) Portionen", systemImage: "person.2")
                    }
                    Stepper("Portionen: \(targetServings)", value: $targetServings, in: 1...50)
                }

                // Ingredients
                if !sortedIngredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Zutaten")
                            .font(.title2).bold()
                        ForEach(sortedIngredients) { ing in
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(formattedAmount(ing.amount)) \(ing.unit.rawValue)")
                                    .monospacedDigit()
                                    .frame(minWidth: 100, alignment: .leading)
                                Text(ing.name)
                                Spacer()
                            }
                        }
                    }
                }

                // Steps
                if !sortedSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Zubereitung")
                            .font(.title2).bold()
                        ForEach(sortedSteps) { step in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("Schritt \(step.index)")
                                        .font(.headline)
                                    Spacer()
                                    if let m = step.minutes {
                                        Label("\(m) Min", systemImage: "clock")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(step.text)
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Rezept")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Rezept löschen")
            }
        }
        .alert("Rezept löschen?", isPresented: $showDeleteAlert) {
            Button("Löschen", role: .destructive) {
                modelContext.delete(recipe)
                try? modelContext.save()
                dismiss()
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Dies kann nicht rückgängig gemacht werden.")
        }
    }
}
