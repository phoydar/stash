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
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let item {
            item.name = trimmedName
            item.quantity = quantity
            item.notes = TagParsing.optionalText(notes)
            item.tags = tags
            item.touch()
        } else {
            let item = InventoryItem(
                name: trimmedName,
                quantity: quantity,
                notes: TagParsing.optionalText(notes),
                tags: tags,
                container: container
            )
            modelContext.insert(item)
            container.items.append(item)
            container.touch()
        }

        dismiss()
    }
}
