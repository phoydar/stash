import Foundation
import SwiftData

enum LocationName {
    static func displayName(from value: String) -> String? {
        let collapsed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return collapsed.isEmpty ? nil : collapsed
    }

    static func deduplicationKey(for value: String) -> String? {
        guard let displayName = displayName(from: value) else {
            return nil
        }

        return displayName.lowercased()
    }

    static func matches(_ lhs: String, _ rhs: String) -> Bool {
        guard let lhsKey = deduplicationKey(for: lhs),
              let rhsKey = deduplicationKey(for: rhs) else {
            return false
        }

        return lhsKey == rhsKey
    }
}

@Model
final class StorageLocation: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = LocationName.displayName(from: name) ?? name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func touch() {
        updatedAt = Date()
    }
}

@Model
final class StorageContainer: Identifiable {
    @Attribute(.unique) var qrID: UUID
    var name: String
    var location: String?
    var details: String?
    var photoFilename: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \InventoryItem.container)
    var items: [InventoryItem]

    init(
        qrID: UUID = UUID(),
        name: String,
        location: String? = nil,
        details: String? = nil,
        photoFilename: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        items: [InventoryItem] = []
    ) {
        self.qrID = qrID
        self.name = name
        self.location = location
        self.details = details
        self.photoFilename = photoFilename
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
    }

    var payload: String {
        QRPayload.makeURLString(for: qrID)
    }

    var id: UUID {
        qrID
    }

    func touch() {
        updatedAt = Date()
    }
}
