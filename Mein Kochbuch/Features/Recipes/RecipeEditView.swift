import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct RecipeEditView: View {
    private struct IngredientDraft: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
        let unit: Ingredient.Unit
    }

    private struct StepDraft: Identifiable {
        let id = UUID()
        let instructions: String
        let minutes: Int?
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let recipe: Recipe?

    @State private var title = ""
    @State private var summary = ""
    @State private var servings = 2
    @State private var totalMinutes = 30
    @State private var tagsText = ""
    @State private var ingredientName = ""
    @State private var ingredientAmount = 1.0
    @State private var ingredientUnit = Ingredient.Unit.g
    @State private var ingredientDrafts: [IngredientDraft] = []
    @State private var stepInstructions = ""
    @State private var stepMinutes = ""
    @State private var stepDrafts: [StepDraft] = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isLoadingImage = false
    @State private var showImageError = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""

    init(recipe: Recipe? = nil) {
        self.recipe = recipe
        _title = State(initialValue: recipe?.title ?? "")
        _summary = State(initialValue: recipe?.summary ?? "")
        _servings = State(initialValue: recipe?.servings ?? 2)
        _totalMinutes = State(initialValue: recipe?.totalMinutes ?? 30)
        _tagsText = State(initialValue: recipe?.tags.joined(separator: ", ") ?? "")
        _ingredientDrafts = State(
            initialValue: recipe?.ingredients.map {
                IngredientDraft(name: $0.name, amount: $0.amount, unit: $0.unit)
            } ?? []
        )
        _stepDrafts = State(
            initialValue: recipe?.steps
                .sorted { $0.index < $1.index }
                .map {
                    StepDraft(instructions: $0.text, minutes: $0.minutes)
                } ?? []
        )
        _imageData = State(initialValue: recipe?.imageData)
    }

    private var tags: [String] {
        RecipeInputNormalizer.tags(from: tagsText)
    }

    private var canAddIngredient: Bool {
        !ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && ingredientAmount > 0
    }

    private func addIngredient() {
        let trimmedName = ingredientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, ingredientAmount > 0 else { return }

        ingredientDrafts.append(
            IngredientDraft(
                name: trimmedName,
                amount: ingredientAmount,
                unit: ingredientUnit
            )
        )
        ingredientName = ""
        ingredientAmount = 1
    }

    private func deleteIngredients(at offsets: IndexSet) {
        ingredientDrafts.remove(atOffsets: offsets)
    }

    private var canAddStep: Bool {
        let trimmedInstructions = stepInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInstructions.isEmpty else { return false }
        guard !stepMinutes.isEmpty else { return true }
        return Int(stepMinutes).map { $0 > 0 } ?? false
    }

    private func addStep() {
        let trimmedInstructions = stepInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInstructions.isEmpty else { return }

        let minutes = stepMinutes.isEmpty ? nil : Int(stepMinutes)
        if let minutes, minutes <= 0 {
            return
        }

        stepDrafts.append(
            StepDraft(instructions: trimmedInstructions, minutes: minutes)
        )
        stepInstructions = ""
        stepMinutes = ""
    }

    private func deleteSteps(at offsets: IndexSet) {
        stepDrafts.remove(atOffsets: offsets)
    }

    private func moveSteps(from source: IndexSet, to destination: Int) {
        stepDrafts.move(fromOffsets: source, toOffset: destination)
    }

    @MainActor
    private func loadSelectedPhoto() async {
        guard let selectedPhoto else { return }

        isLoadingImage = true
        defer { isLoadingImage = false }

        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                  self.selectedPhoto == selectedPhoto,
                  let resizedData = resizedImageData(from: data) else {
                showImageError = true
                return
            }
            imageData = resizedData
        } catch {
            guard self.selectedPhoto == selectedPhoto else { return }
            showImageError = true
        }
    }

    private func resizedImageData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let maximumDimension = 1_600.0
        let longestDimension = max(image.size.width, image.size.height)
        let scale = min(1, maximumDimension / longestDimension)
        let targetSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resizedImage.jpegData(compressionQuality: 0.8)
    }

    private func removeImage() {
        selectedPhoto = nil
        imageData = nil
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let ingredients = ingredientDrafts.map { draft in
            Ingredient(name: draft.name, amount: draft.amount, unit: draft.unit)
        }
        let steps = stepDrafts.enumerated().map { offset, draft in
            RecipeStep(
                index: offset + 1,
                text: draft.instructions,
                minutes: draft.minutes
            )
        }
        if let recipe {
            recipe.title = trimmedTitle
            recipe.summary = trimmedSummary
            recipe.servings = servings
            recipe.totalMinutes = totalMinutes
            recipe.tags = tags
            recipe.imageData = imageData

            recipe.ingredients.forEach { modelContext.delete($0) }
            recipe.steps.forEach { modelContext.delete($0) }
            recipe.ingredients = ingredients
            recipe.steps = steps
        } else {
            let newRecipe = Recipe(
                title: trimmedTitle,
                summary: trimmedSummary,
                servings: servings,
                totalMinutes: totalMinutes,
                tags: tags,
                imageData: imageData,
                ingredients: ingredients,
                steps: steps
            )
            modelContext.insert(newRecipe)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    var body: some View {
        Form {
            Section("Rezept") {
                TextField("Titel", text: $title)
                TextField("Beschreibung", text: $summary, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Foto") {
                if let imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Ausgewähltes Rezeptfoto")
                }

                if isLoadingImage {
                    HStack {
                        ProgressView()
                        Text("Foto wird verarbeitet …")
                    }
                }

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    Label(
                        imageData == nil ? "Foto auswählen" : "Foto ersetzen",
                        systemImage: "photo"
                    )
                }

                if imageData != nil {
                    Button("Foto entfernen", systemImage: "trash", role: .destructive) {
                        removeImage()
                    }
                }
            }

            Section("Details") {
                Stepper("Portionen: \(servings)", value: $servings, in: 1...50)
                Stepper(
                    "Gesamtzeit: \(totalMinutes) Min",
                    value: $totalMinutes,
                    in: 5...1_440,
                    step: 5
                )
            }

            Section {
                TextField("z. B. Schnell, Vegetarisch", text: $tagsText)
                    .textInputAutocapitalization(.words)
            } header: {
                Text("Tags")
            } footer: {
                Text("Mehrere Tags mit Kommas trennen.")
            }

            Section("Zutat hinzufügen") {
                TextField("Name", text: $ingredientName)
                    .textInputAutocapitalization(.sentences)

                HStack {
                    TextField(
                        "Menge",
                        value: $ingredientAmount,
                        format: .number
                    )
                    .keyboardType(.decimalPad)

                    Picker("Einheit", selection: $ingredientUnit) {
                        ForEach(Ingredient.Unit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                }

                Button("Zutat hinzufügen", systemImage: "plus") {
                    addIngredient()
                }
                .disabled(!canAddIngredient)
            }

            if !ingredientDrafts.isEmpty {
                Section("Zutaten") {
                    ForEach(ingredientDrafts) { ingredient in
                        HStack {
                            Text(ingredient.name)
                            Spacer()
                            Text(
                                "\(ingredient.amount.formatted(.number.precision(.fractionLength(0...2)))) \(ingredient.unit.rawValue)"
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteIngredients)
                }
            }

            Section("Zubereitungsschritt hinzufügen") {
                TextField(
                    "Anweisungen",
                    text: $stepInstructions,
                    axis: .vertical
                )
                .lineLimit(2...5)

                TextField("Dauer in Minuten (optional)", text: $stepMinutes)
                    .keyboardType(.numberPad)

                Button("Schritt hinzufügen", systemImage: "plus") {
                    addStep()
                }
                .disabled(!canAddStep)
            }

            if !stepDrafts.isEmpty {
                Section {
                    ForEach(
                        Array(stepDrafts.enumerated()),
                        id: \.element.id
                    ) { offset, step in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Schritt \(offset + 1)")
                                .font(.headline)
                            Text(step.instructions)
                            if let minutes = step.minutes {
                                Label(
                                    "\(minutes) Min",
                                    systemImage: "clock"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteSteps)
                    .onMove(perform: moveSteps)
                } header: {
                    HStack {
                        Text("Zubereitung")
                        Spacer()
                        EditButton()
                            .textCase(nil)
                    }
                } footer: {
                    Text("Im Bearbeitungsmodus lassen sich Schritte neu anordnen.")
                }
            }
        }
        .navigationTitle(recipe == nil ? "Neues Rezept" : "Rezept bearbeiten")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { save() }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || isLoadingImage
                    )
            }
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
        .alert("Foto konnte nicht geladen werden", isPresented: $showImageError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Bitte wähle ein anderes Foto aus.")
        }
        .alert("Rezept konnte nicht gespeichert werden", isPresented: $showSaveError) {
            Button("Erneut versuchen") {
                save()
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Deine Eingaben bleiben erhalten.\n\n\(saveErrorMessage)")
        }
    }
}

#Preview {
    NavigationStack { RecipeEditView() }
}
