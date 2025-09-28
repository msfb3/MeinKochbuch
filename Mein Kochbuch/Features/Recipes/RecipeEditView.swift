import SwiftUI

struct RecipeEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var servings: Int = 2

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
                Button("Speichern") { dismiss() }
            }
        }
    }
}

#Preview {
    NavigationStack { RecipeEditView() }
}
