import Foundation
import SwiftData

@Model
final class InventoryItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Int
    var notes: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    var container: StorageContainer?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        notes: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        container: StorageContainer? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = max(quantity, 1)
        self.notes = notes
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.container = container
    }

    func touch() {
        updatedAt = Date()
        container?.touch()
    }
}
