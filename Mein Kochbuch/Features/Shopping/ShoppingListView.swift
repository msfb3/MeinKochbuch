import SwiftUI

struct ShoppingListView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Noch keine Einkäufe", systemImage: "cart", description: Text("Füge Zutaten aus Rezepten hinzu."))
                .navigationTitle("Einkäufe")
        }
    }
}

#Preview {
    ShoppingListView()
}
