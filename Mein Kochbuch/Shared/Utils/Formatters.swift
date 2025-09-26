//
//  Formatters.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import Foundation

enum Formatters {
    static func number(_ value: Double, maxFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = maxFractionDigits
        return formatter.string(from: value as NSNumber) ?? String(value)
    }
}
