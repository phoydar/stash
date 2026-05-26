import SwiftData
import SwiftUI

struct AddEditContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StorageLocation.name) private var managedLocations: [StorageLocation]

    private let container: StorageContainer?

    @State private var name: String
    @State private var location: String
    @State private var details: String
    @State private var tags: [String]
    @State private var initialItems: [InitialItemDraft]
    @State private var selectedLocationID: UUID?
    @State private var newLocationName = ""
    @State private var isAddingLocation = false
    @State private var selectedPhotoData: Data?
    @State private var shouldRemovePhoto = false
    @State private var errorMessage: String?

    init(container: StorageContainer? = nil) {
        self.container = container
        _name = State(initialValue: container?.name ?? "")
        _location = State(initialValue: container?.location ?? "")
        _details = State(initialValue: container?.details ?? "")
        _tags = State(initialValue: container?.tags ?? [])
        _initialItems = State(initialValue: [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Container") {
                    TextField("Container name (optional)", text: $name)
                    TagEditorView(tags: $tags)
                    Text("Leave the name blank if you want to write it on the printed QR label by hand.")
                        .font(.caption)
                        .foregroundStyle(Color.sbTextSecondary)
                }

                PhotoPickerSection(
                    title: "Bin photo",
                    existingFilename: container?.photoFilename,
                    emptyTitle: "No bin photo",
                    emptySystemImage: "shippingbox",
                    selectedPhotoData: $selectedPhotoData,
                    shouldRemoveExistingPhoto: $shouldRemovePhoto
                )

                Section("Location") {
                    if managedLocations.isEmpty {
                        Text("No saved locations yet.")
                            .foregroundStyle(Color.sbTextSecondary)
                    } else {
                        Picker("Saved location", selection: locationSelection) {
                            Text("None").tag(UUID?.none)
                            ForEach(managedLocations) { managedLocation in
                                Text(managedLocation.name).tag(Optional(managedLocation.id))
                            }
                        }
                    }

                    if let displayLocation = LocationName.displayName(from: location) {
                        Label(displayLocation, systemImage: "mappin.and.ellipse")
                            .foregroundStyle(Color.sbTextSecondary)
                    }

                    if isAddingLocation {
                        HStack {
                            TextField("New location", text: $newLocationName)
                                .textInputAutocapitalization(.words)

                            Button("Use") {
                                useTypedLocation()
                            }
                            .disabled(LocationName.displayName(from: newLocationName) == nil)
                        }
                    }

                    HStack {
                        Button {
                            if isAddingLocation {
                                newLocationName = ""
                            }
                            isAddingLocation.toggle()
                        } label: {
                            Label(
                                isAddingLocation ? "Cancel new location" : "Add new location",
                                systemImage: isAddingLocation ? "xmark" : "plus"
                            )
                        }

                        if LocationName.displayName(from: location) != nil {
                            Spacer()

                            Button("Clear", role: .destructive) {
                                selectedLocationID = nil
                                location = ""
                                newLocationName = ""
                                isAddingLocation = false
                            }
                        }
                    }
                }

                if container == nil {
                    Section("Items") {
                        if initialItems.isEmpty {
                            Text("No items added yet.")
                                .foregroundStyle(Color.sbTextSecondary)
                        } else {
                            ForEach($initialItems) { $item in
                                InitialItemDraftRow(item: $item) {
                                    removeInitialItem(item.id)
                                }
                            }
                        }

                        Button {
                            initialItems.append(InitialItemDraft())
                        } label: {
                            Label("Add item", systemImage: "plus")
                        }
                    }
                } else {
                    Section("Items") {
                        Text("Add, edit, and remove items from the container detail screen.")
                            .foregroundStyle(Color.sbTextSecondary)
                    }
                }

                Section("Details") {
                    TextEditor(text: $details)
                        .frame(minHeight: 120)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.sbCanvas.ignoresSafeArea())
            .tint(.sbBuzz)
            .navigationTitle(container == nil ? "New container" : "Edit container")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                reconcileSelectedLocation()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
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
    }

    private func save() {
        let storedName = ContainerName.storedName(from: name)

        do {
            if let container {
                container.name = storedName
                container.location = resolvedLocationForSave()
                container.details = TagParsing.optionalText(details)
                container.photoFilename = try resolvedPhotoFilename(existingFilename: container.photoFilename)
                container.tags = tags
                container.touch()
            } else {
                let container = StorageContainer(
                    name: storedName,
                    location: resolvedLocationForSave(),
                    details: TagParsing.optionalText(details),
                    photoFilename: try resolvedPhotoFilename(existingFilename: nil),
                    tags: tags
                )
                modelContext.insert(container)
                for draft in initialItems {
                    let itemName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !itemName.isEmpty else {
                        continue
                    }

                    let item = InventoryItem(
                        name: itemName,
                        quantity: draft.quantity,
                        container: container
                    )
                    modelContext.insert(item)
                    container.items.append(item)
                }
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolvedPhotoFilename(existingFilename: String?) throws -> String? {
        if let selectedPhotoData {
            return try PhotoStore.shared.saveImageData(selectedPhotoData, replacing: existingFilename)
        }

        if shouldRemovePhoto {
            PhotoStore.shared.deletePhoto(filename: existingFilename)
            return nil
        }

        return existingFilename
    }

    private var locationSelection: Binding<UUID?> {
        Binding(
            get: { selectedLocationID },
            set: { newValue in
                selectedLocationID = newValue

                guard let newValue else {
                    location = ""
                    newLocationName = ""
                    isAddingLocation = false
                    return
                }

                applySelectedLocation(newValue)
            }
        )
    }

    private func applySelectedLocation(_ selectedLocationID: UUID) {
        guard let managedLocation = managedLocations.first(where: { $0.id == selectedLocationID }) else {
            return
        }

        location = managedLocation.name
        newLocationName = ""
        isAddingLocation = false
    }

    private func reconcileSelectedLocation() {
        guard let locationKey = LocationName.deduplicationKey(for: location) else {
            selectedLocationID = nil
            return
        }

        selectedLocationID = managedLocations.first { managedLocation in
            LocationName.deduplicationKey(for: managedLocation.name) == locationKey
        }?.id
    }

    private func useTypedLocation() {
        guard let displayName = LocationName.displayName(from: newLocationName) else {
            return
        }

        if let existingLocation = existingLocation(matching: displayName) {
            selectedLocationID = existingLocation.id
            location = existingLocation.name
        } else {
            selectedLocationID = nil
            location = displayName
        }

        newLocationName = ""
        isAddingLocation = false
    }

    private func resolvedLocationForSave() -> String? {
        if let pendingLocation = LocationName.displayName(from: newLocationName) {
            return existingOrInsertedLocation(named: pendingLocation).name
        }

        if let selectedLocationID,
           let selectedLocation = managedLocations.first(where: { $0.id == selectedLocationID }) {
            return selectedLocation.name
        }

        guard let displayName = LocationName.displayName(from: location) else {
            return nil
        }

        return existingOrInsertedLocation(named: displayName).name
    }

    private func existingLocation(matching name: String) -> StorageLocation? {
        managedLocations.first { managedLocation in
            LocationName.matches(managedLocation.name, name)
        }
    }

    private func existingOrInsertedLocation(named name: String) -> StorageLocation {
        if let existingLocation = existingLocation(matching: name) {
            return existingLocation
        }

        let location = StorageLocation(name: name)
        modelContext.insert(location)
        return location
    }

    private func removeInitialItem(_ id: UUID) {
        initialItems.removeAll { $0.id == id }
    }
}

private struct InitialItemDraft: Identifiable, Equatable {
    let id = UUID()
    var name = ""
    var quantity = 1
}

private struct InitialItemDraftRow: View {
    @Binding var item: InitialItemDraft
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                TextField("Item name", text: $item.name)

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove item")
            }

            Stepper(value: $item.quantity, in: 1...999) {
                HStack {
                    Text("Quantity")
                    Spacer()
                    Text("\(item.quantity)")
                        .foregroundStyle(Color.sbTextSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
