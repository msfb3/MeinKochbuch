import Foundation

enum RecipeInputNormalizer {
    static func tags(from text: String) -> [String] {
        var seenTags: Set<String> = []

        return text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { tag in
                guard !tag.isEmpty else { return false }
                return seenTags.insert(tag.lowercased()).inserted
            }
    }
}
