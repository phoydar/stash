import SwiftUI
import SwiftData

@main
struct StashApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: StorageContainer.self,
                InventoryItem.self,
                StorageLocation.self
            )
        } catch {
            fatalError("Failed to initialize Stash data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
