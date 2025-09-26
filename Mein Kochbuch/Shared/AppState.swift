//
//  AppState.swift
//  Mein Kochbuch
//
//  Created by Fabian Breitling on 26.09.25.
//

import Observation

@Observable
final class AppState {
    var searchText: String = ""
    var selectedTags: String? = nil
}
