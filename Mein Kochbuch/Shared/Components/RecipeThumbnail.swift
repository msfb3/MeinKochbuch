//
//  RecipeThumbnail.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import SwiftUI

struct RecipeThumbnail: View {
    let imageData: Data?
    
    var body: some View {
        Group {
            if let data = imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFit().padding(12)
            } else {
                Image(systemName: "photo").resizable().scaledToFit().padding(12)
            }
        }
        .frame(width: 64, height: 64)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("Rezeptbild")
    }
}
