//
//  Item.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
