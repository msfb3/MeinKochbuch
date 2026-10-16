import Foundation
import SwiftData
import Testing
@testable import Mein_Kochbuch

@MainActor
struct RecipePersistenceTests {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Recipe.self,
            Ingredient.self,
            RecipeStep.self,
            ShoppingItem.self,
            configurations: configuration
        )
    }

    @Test
    func `Complete recipe is persisted`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let recipe = Recipe(
            title: "Kartoffelsuppe",
            summary: "Einfach und cremig",
            servings: 4,
            totalMinutes: 45,
            tags: ["Schnell", "Vegetarisch"],
            imageData: Data([1, 2, 3]),
            ingredients: [
                Ingredient(name: "Kartoffeln", amount: 800, unit: .g)
            ],
            steps: [
                RecipeStep(index: 1, text: "Kartoffeln schneiden", minutes: 10)
            ]
        )

        context.insert(recipe)
        try context.save()

        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        let savedRecipe = try #require(recipes.first)

        #expect(recipes.count == 1)
        #expect(savedRecipe.title == "Kartoffelsuppe")
        #expect(savedRecipe.summary == "Einfach und cremig")
        #expect(savedRecipe.servings == 4)
        #expect(savedRecipe.totalMinutes == 45)
        #expect(savedRecipe.tags == ["Schnell", "Vegetarisch"])
        #expect(savedRecipe.imageData == Data([1, 2, 3]))
        #expect(savedRecipe.ingredients.count == 1)
        #expect(savedRecipe.steps.count == 1)
    }

    @Test
    func `Updating a recipe does not create a duplicate`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let recipe = Recipe(title: "Suppe")

        context.insert(recipe)
        try context.save()

        recipe.title = "Tomatensuppe"
        recipe.servings = 6
        try context.save()

        let recipes = try context.fetch(FetchDescriptor<Recipe>())

        #expect(recipes.count == 1)
        #expect(recipes.first?.title == "Tomatensuppe")
        #expect(recipes.first?.servings == 6)
    }

    @Test
    func `Ingredients and preparation order are persisted`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let recipe = Recipe(
            title: "Pfannkuchen",
            ingredients: [
                Ingredient(name: "Mehl", amount: 250, unit: .g),
                Ingredient(name: "Milch", amount: 500, unit: .ml)
            ],
            steps: [
                RecipeStep(index: 2, text: "Ausbacken"),
                RecipeStep(index: 1, text: "Teig verrühren")
            ]
        )

        context.insert(recipe)
        try context.save()

        let savedRecipe = try #require(
            try context.fetch(FetchDescriptor<Recipe>()).first
        )
        let orderedSteps = savedRecipe.steps.sorted { $0.index < $1.index }

        #expect(Set(savedRecipe.ingredients.map(\.name)) == ["Mehl", "Milch"])
        #expect(orderedSteps.map(\.text) == ["Teig verrühren", "Ausbacken"])
        #expect(orderedSteps.map(\.index) == [1, 2])
    }

    @Test
    func `Deleting a recipe cascades to ingredients and steps`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let recipe = Recipe(
            title: "Pasta",
            ingredients: [
                Ingredient(name: "Nudeln", amount: 500, unit: .g)
            ],
            steps: [
                RecipeStep(index: 1, text: "Nudeln kochen")
            ]
        )

        context.insert(recipe)
        try context.save()
        context.delete(recipe)
        try context.save()

        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        let ingredients = try context.fetch(FetchDescriptor<Ingredient>())
        let steps = try context.fetch(FetchDescriptor<RecipeStep>())

        #expect(recipes.isEmpty)
        #expect(ingredients.isEmpty)
        #expect(steps.isEmpty)
    }

    @Test
    func `Tags are trimmed and deduplicated case insensitively`() {
        let tags = RecipeInputNormalizer.tags(
            from: " Schnell, Vegetarisch, schnell, , Dessert "
        )

        #expect(tags == ["Schnell", "Vegetarisch", "Dessert"])
    }

    @Test
    func `Manual shopping item without quantity is persisted`() throws {
        let container = try makeContainer()
        let context = container.mainContext

        try ShoppingListManager.add(
            [ShoppingListEntry(name: "Äpfel", amount: nil, unit: nil)],
            to: context
        )

        let items = try context.fetch(FetchDescriptor<ShoppingItem>())
        let item = try #require(items.first)

        #expect(items.count == 1)
        #expect(item.name == "Äpfel")
        #expect(item.amount == nil)
        #expect(item.unit == nil)
        #expect(!item.checked)
    }

    @Test
    func `Matching shopping items merge and become active`() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let existingItem = ShoppingItem(
            name: "Mehl",
            amount: 250,
            unit: .g,
            checked: true
        )
        context.insert(existingItem)
        try context.save()

        try ShoppingListManager.add(
            [ShoppingListEntry(name: " mehl ", amount: 150, unit: .g)],
            to: context
        )

        let items = try context.fetch(FetchDescriptor<ShoppingItem>())
        let item = try #require(items.first)

        #expect(items.count == 1)
        #expect(item.amount == 400)
        #expect(!item.checked)
    }

    @Test
    func `Shopping items with different units remain separate`() throws {
        let container = try makeContainer()
        let context = container.mainContext

        try ShoppingListManager.add(
            [
                ShoppingListEntry(name: "Milch", amount: 1, unit: .l),
                ShoppingListEntry(name: "Milch", amount: 500, unit: .ml)
            ],
            to: context
        )

        let items = try context.fetch(FetchDescriptor<ShoppingItem>())

        #expect(items.count == 2)
        #expect(Set(items.compactMap(\.unit)) == [.l, .ml])
    }
}
