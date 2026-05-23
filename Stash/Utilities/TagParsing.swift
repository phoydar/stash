import Foundation

enum TagParsing {
    static func normalizeSingleTag(_ value: String) -> String? {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()

        return normalized.isEmpty ? nil : normalized
    }

    static func parse(_ value: String) -> [String] {
        var seen = Set<String>()
        return value
            .split { character in
                character == "," || character == "#" || character.isWhitespace || character.isNewline
            }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }

    static func appending(_ value: String, to tags: [String]) -> [String] {
        guard let tag = normalizeSingleTag(value), !tags.contains(tag) else {
            return tags
        }

        return tags + [tag]
    }

    static func display(_ tags: [String]) -> String {
        tags.joined(separator: ", ")
    }

    static func optionalText(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
