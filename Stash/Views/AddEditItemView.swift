import SwiftData
import SwiftUI

struct AddEditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let container: StorageContainer
    private let item: InventoryItem?

    @State private var name: String
    @State private var quantity: Int
    @State private var notes: String
    @State private var tags: [String]
    @State private var selectedPhotoData: Data?
    @State private var shouldRemovePhoto = false
    @State private var errorMessage: String?

    init(container: StorageContainer, item: InventoryItem? = nil) {
        self.container = container
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _quantity = State(initialValue: item?.quantity ?? 1)
        _notes = State(initialValue: item?.notes ?? "")
        _tags = State(initialValue: item?.tags ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)

                    Stepper(value: $quantity, in: 1...999) {
                        HStack {
                            Text("Quantity")
                            Spacer()
                            Text("\(quantity)")
                                .foregroundStyle(Color.sbTextSecondary)
                        }
                    }

                    TagEditorView(tags: $tags)
                }

                PhotoPickerSection(
                    title: "Item photo",
                    existingFilename: item?.photoFilename,
                    emptyTitle: "No item photo",
                    emptySystemImage: "photo",
                    selectedPhotoData: $selectedPhotoData,
                    shouldRemoveExistingPhoto: $shouldRemovePhoto
                )

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.sbCanvas.ignoresSafeArea())
            .tint(.sbBuzz)
            .navigationTitle(item == nil ? "New item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Item error", isPresented: Binding(
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
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let item {
                item.name = trimmedName
                item.quantity = quantity
                item.notes = TagParsing.optionalText(notes)
                item.photoFilename = try resolvedPhotoFilename(existingFilename: item.photoFilename)
                item.tags = tags
                item.touch()
            } else {
                let item = InventoryItem(
                    name: trimmedName,
                    quantity: quantity,
                    notes: TagParsing.optionalText(notes),
                    photoFilename: try resolvedPhotoFilename(existingFilename: nil),
                    tags: tags,
                    container: container
                )
                modelContext.insert(item)
                container.items.append(item)
                container.touch()
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
}
