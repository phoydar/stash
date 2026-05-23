import Foundation

struct ValidationContainer: Identifiable, Hashable {
    let id: UUID
    var name: String
    var location: String
    var tags: [String]

    var payload: String {
        QRPayload.makeURLString(for: id)
    }

    static let sample = ValidationContainer(
        id: UUID(uuidString: "A2E3F54D-58F1-49C6-A198-95D079CE82C3")!,
        name: "Phase 0 Test Bin",
        location: "Basement > Shelf 2",
        tags: ["phase0", "test"]
    )
}
