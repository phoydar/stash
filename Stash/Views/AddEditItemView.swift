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
    @State private var hasLastUsedDate: Bool
    @State private var lastUsedAt: Date
    @State private var reviewStatus: InventoryReviewStatus
    @State private var hasReminder: Bool
    @State private var reviewReminderAt: Date
    @State private var errorMessage: String?
    @State private var isSaving = false

    init(container: StorageContainer, item: InventoryItem? = nil) {
        self.container = container
        self.item = item
        let reminderDate = item?.reviewReminderAt
        let fallbackReminderDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        _name = State(initialValue: item?.name ?? "")
        _quantity = State(initialValue: item?.quantity ?? 1)
        _notes = State(initialValue: item?.notes ?? "")
        _tags = State(initialValue: item?.tags ?? [])
        _hasLastUsedDate = State(initialValue: item?.lastUsedAt != nil)
        _lastUsedAt = State(initialValue: item?.lastUsedAt ?? Date())
        _reviewStatus = State(initialValue: item?.reviewStatus ?? .unreviewed)
        _hasReminder = State(initialValue: reminderDate.map { $0 > Date() } ?? false)
        _reviewReminderAt = State(initialValue: reminderDate.map { max($0, Date()) } ?? fallbackReminderDate)
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

                Section("Usage & review") {
                    Picker("Review status", selection: $reviewStatus) {
                        ForEach(InventoryReviewStatus.allCases) { status in
                            Label(status.displayName, systemImage: status.systemImage)
                                .tag(status)
                        }
                    }

                    Toggle("Set last used date", isOn: $hasLastUsedDate)

                    if hasLastUsedDate {
                        DatePicker(
                            "Last used",
                            selection: $lastUsedAt,
                            displayedComponents: [.date]
                        )
                    }

                    Toggle("Review reminder", isOn: $hasReminder)

                    if hasReminder {
                        DatePicker(
                            "Remind me",
                            selection: $reviewReminderAt,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
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
                        Task {
                            await save()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
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

    @MainActor
    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        defer { isSaving = false }

        do {
            let savedItem: InventoryItem

            if let item {
                item.name = trimmedName
                item.quantity = quantity
                item.notes = TagParsing.optionalText(notes)
                item.photoFilename = try resolvedPhotoFilename(existingFilename: item.photoFilename)
                item.tags = tags
                item.touch()
                applyUsageAndReview(to: item)
                savedItem = item
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
                applyUsageAndReview(to: item)
                savedItem = item
            }

            try await ReviewReminderService.shared.updateReminder(
                for: savedItem,
                at: hasReminder ? reviewReminderAt : nil
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyUsageAndReview(to item: InventoryItem) {
        item.lastUsedAt = hasLastUsedDate ? lastUsedAt : nil
        item.setReviewStatus(reviewStatus)
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
