import SwiftData
import SwiftUI

struct ContainerDetailView: View {
    let qrID: UUID

    @Environment(\.modelContext) private var modelContext
    @Query private var containers: [StorageContainer]

    init(qrID: UUID) {
        self.qrID = qrID
        _containers = Query(filter: #Predicate<StorageContainer> { container in
            container.qrID == qrID
        })
    }

    var body: some View {
        Group {
            if let container = containers.first {
                ContainerDetailContent(container: container)
            } else {
                ContentUnavailableView(
                    "Unknown container",
                    systemImage: "questionmark.app",
                    description: Text("This QR code is valid, but it does not match a saved Stash container on this device.")
                )
            }
        }
        .navigationTitle(containers.first?.name ?? "Container")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ContainerDetailContent: View {
    @Environment(\.modelContext) private var modelContext

    let container: StorageContainer
    private let labelService = QRLabelService()

    @State private var labelImage: UIImage?
    @State private var errorMessage: String?
    @State private var isEditingContainer = false
    @State private var isAddingItem = false
    @State private var isComposingLabels = false
    @State private var itemToEdit: InventoryItem?

    private var sortedItems: [InventoryItem] {
        container.items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    if let location = container.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .foregroundStyle(Color.sbTextSecondary)
                    }

                    if let details = container.details, !details.isEmpty {
                        Text(details)
                            .foregroundStyle(Color.sbTextSecondary)
                    }

                    TagChipsView(tags: container.tags)

                    Text(container.payload)
                        .font(.caption.monospaced())
                        .foregroundStyle(Color.sbTextTertiary)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.sbSurface)

            Section {
                if sortedItems.isEmpty {
                    ContentUnavailableView(
                        "No items",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Tap + to add what is stored here.")
                    )
                } else {
                    ForEach(sortedItems) { item in
                        Button {
                            itemToEdit = item
                        } label: {
                            ItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                modelContext.delete(item)
                                container.touch()
                            }
                        }
                        .listRowBackground(Color.sbSurface)
                    }
                }
            } header: {
                Text("Items")
            }

            Section("QR label") {
                if let labelImage {
                    Image(uiImage: labelImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 120)
                }

                Button {
                    isComposingLabels = true
                } label: {
                    Label("Choose label sheet position", systemImage: "tag")
                }
            }
            .listRowBackground(Color.sbSurface)
        }
        .listStyle(.insetGrouped)
        .sbGroupedBackground()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isAddingItem = true
                } label: {
                    Label("Add item", systemImage: "plus")
                }

                Button {
                    isEditingContainer = true
                } label: {
                    Label("Edit container", systemImage: "square.and.pencil")
                }
            }
        }
        .onAppear(perform: refreshLabelPreview)
        .onChange(of: container.updatedAt) {
            refreshLabelPreview()
        }
        .sheet(isPresented: $isEditingContainer) {
            AddEditContainerView(container: container)
        }
        .sheet(isPresented: $isAddingItem) {
            AddEditItemView(container: container)
        }
        .sheet(isPresented: $isComposingLabels) {
            LabelSheetComposerView(initialContainerID: container.qrID)
        }
        .sheet(item: $itemToEdit) { item in
            AddEditItemView(container: container, item: item)
        }
        .alert("Container error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func refreshLabelPreview() {
        do {
            labelImage = try labelService.renderLabelImage(for: container)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}

private struct ItemRow: View {
    let item: InventoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(Color.sbTextPrimary)
                Spacer()
                Text("x\(item.quantity)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.sbTextSecondary)
            }

            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(Color.sbTextSecondary)
            }

            TagChipsView(tags: item.tags)
        }
        .padding(.vertical, 4)
    }
}
