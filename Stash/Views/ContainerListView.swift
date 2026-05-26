import SwiftData
import SwiftUI

struct ContainerListView: View {
    @Binding var path: [AppRoute]

    @Environment(\.modelContext) private var modelContext
    @Query private var containers: [StorageContainer]

    @State private var isAddingContainer = false
    @State private var isComposingLabels = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if containers.isEmpty {
                    ContentUnavailableView(
                        "No containers",
                        systemImage: "shippingbox",
                        description: Text("Tap + to create your first storage container.")
                    )
                } else {
                    List {
                        ForEach(sortedContainers) { container in
                            NavigationLink(value: AppRoute.container(container.qrID)) {
                                ContainerRow(container: container)
                            }
                            .listRowBackground(Color.sbSurface)
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    ReviewReminderService.shared.cancelReminders(for: container)
                                    PhotoStore.shared.deletePhotos(for: container)
                                    modelContext.delete(container)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .sbGroupedBackground()
                }
            }
            .navigationTitle("Containers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isComposingLabels = true
                    } label: {
                        Label("Label sheet", systemImage: "tag")
                    }
                    .disabled(containers.isEmpty)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingContainer = true
                    } label: {
                        Label("Add container", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingContainer) {
                AddEditContainerView()
            }
            .sheet(isPresented: $isComposingLabels) {
                LabelSheetComposerView()
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .container(let uuid):
                    ContainerDetailView(qrID: uuid)
                }
            }
        }
    }

    private var sortedContainers: [StorageContainer] {
        containers.sorted {
            $0.sortName.localizedCaseInsensitiveCompare($1.sortName) == .orderedAscending
        }
    }
}

private struct ContainerRow: View {
    let container: StorageContainer

    var body: some View {
        HStack(spacing: SBSpacing.medium) {
            PhotoThumbnailView(
                filename: container.photoFilename,
                fallbackSystemImage: "shippingbox"
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(container.displayName)
                    .font(.headline)
                    .foregroundStyle(Color.sbTextPrimary)

                if let location = container.location, !location.isEmpty {
                    Text(location)
                        .font(.subheadline)
                        .foregroundStyle(Color.sbTextSecondary)
                }

                HStack(spacing: 8) {
                    Label("\(container.items.count)", systemImage: "list.bullet")
                    Text(container.qrID.uuidString.prefix(8))
                        .font(.caption.monospaced())
                }
                .font(.caption)
                .foregroundStyle(Color.sbTextTertiary)

                TagChipsView(tags: container.tags)
            }
        }
        .padding(.vertical, 4)
    }
}
