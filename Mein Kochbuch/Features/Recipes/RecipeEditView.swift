import SwiftUI
import SwiftData

struct RecipeEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title: String = ""
    @State private var servings: Int = 1

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let recipe = Recipe(title: trimmed, servings: servings)
        modelContext.insert(recipe)
        try? modelContext.save()
        dismiss()
    }

    var body: some View {
        Form {
            Section("Rezept") {
                TextField("Titel", text: $title)
                Stepper("Portionen: \(servings)" , value: $servings, in: 1...20)
            }
        }
        .navigationTitle("Neues Rezept")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { save() }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack { RecipeEditView() }
}
