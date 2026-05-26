import SwiftData
import SwiftUI

struct LabelSheetComposerView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \StorageContainer.name) private var containers: [StorageContainer]

    private let labelService = QRLabelService()
    private let configuration = QRLabelSheetConfiguration.phaseZero

    @State private var slotAssignments: [Int: UUID]
    @State private var selectedSlot: SheetSlot?
    @State private var shareItem: ActivityShareItem?
    @State private var errorMessage: String?

    init(initialContainerID: UUID? = nil) {
        if let initialContainerID {
            _slotAssignments = State(initialValue: [0: initialContainerID])
        } else {
            _slotAssignments = State(initialValue: [:])
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: configuration.columns),
                        spacing: 8
                    ) {
                        ForEach(0..<configuration.labelsPerSheet, id: \.self) { index in
                            SheetSlotButton(
                                number: index + 1,
                                container: container(for: index)
                            ) {
                                selectedSlot = SheetSlot(index: index)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Sheet")
                } footer: {
                    Text("Tap a label position to choose what prints there. Empty positions stay blank.")
                }

                Section("Selected labels") {
                    if slotAssignments.isEmpty {
                        Text("No labels selected.")
                            .foregroundStyle(Color.sbTextSecondary)
                    } else {
                        ForEach(sortedAssignedSlots, id: \.self) { index in
                            HStack {
                                Text("Label \(index + 1)")
                                Spacer()
                                Text(containerName(for: index) ?? "Unknown")
                                    .foregroundStyle(Color.sbTextSecondary)
                            }
                        }
                        .onDelete { offsets in
                            for offset in offsets {
                                slotAssignments.removeValue(forKey: sortedAssignedSlots[offset])
                            }
                        }
                    }
                }

                Section {
                    Button {
                        exportLabelSheet()
                    } label: {
                        Label("Export label sheet PDF", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SBPrimaryButtonStyle())
                    .disabled(slotAssignments.isEmpty)
                }
            }
            .listStyle(.insetGrouped)
            .sbGroupedBackground()
            .tint(.sbBuzz)
            .navigationTitle("Label sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedSlot) { slot in
                LabelSlotPickerView(
                    slotNumber: slot.index + 1,
                    containers: containers,
                    selectedContainerID: slotAssignments[slot.index]
                ) { containerID in
                    if let containerID {
                        slotAssignments[slot.index] = containerID
                    } else {
                        slotAssignments.removeValue(forKey: slot.index)
                    }
                    selectedSlot = nil
                }
            }
            .sheet(item: $shareItem) { item in
                ActivityView(activityItems: [item.url])
            }
            .alert("Label sheet error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var sortedAssignedSlots: [Int] {
        slotAssignments.keys.sorted()
    }

    private func containerName(for slotIndex: Int) -> String? {
        container(for: slotIndex)?.name
    }

    private func container(for slotIndex: Int) -> StorageContainer? {
        guard let id = slotAssignments[slotIndex] else {
            return nil
        }

        return containers.first { $0.qrID == id }
    }

    private func exportLabelSheet() {
        let assignments = sortedAssignedSlots.compactMap { slotIndex -> QRLabelSheetAssignment? in
            guard
                let containerID = slotAssignments[slotIndex],
                let container = containers.first(where: { $0.qrID == containerID })
            else {
                return nil
            }

            return QRLabelSheetAssignment(
                slotIndex: slotIndex,
                content: QRLabelContent(container: container)
            )
        }

        guard !assignments.isEmpty else {
            errorMessage = "Choose at least one label to print."
            return
        }

        do {
            shareItem = ActivityShareItem(url: try labelService.writeLabelSheetPDF(assignments: assignments))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SheetSlot: Identifiable {
    let index: Int

    var id: Int {
        index
    }
}

private struct SheetSlotButton: View {
    let number: Int
    let container: StorageContainer?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(container == nil ? Color.sbTextTertiary : Color.sbBuzz)

                HStack(alignment: .top, spacing: 6) {
                    if let container, container.photoFilename != nil {
                        PhotoThumbnailView(
                            filename: container.photoFilename,
                            size: 28,
                            cornerRadius: SBRadius.base
                        )
                    }

                    Text(container?.name ?? "Empty")
                        .font(.caption)
                        .fontWeight(container == nil ? .regular : .semibold)
                        .foregroundStyle(container == nil ? Color.sbTextSecondary : Color.sbTextPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                }
            }
            .padding(8)
            .frame(minHeight: 72)
            .sbCard(
                cornerRadius: SBRadius.medium,
                fill: container == nil ? .sbSurface : .sbBuzzSoft,
                border: container == nil ? .sbBorder : .sbBuzz
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LabelSlotPickerView: View {
    let slotNumber: Int
    let containers: [StorageContainer]
    let selectedContainerID: UUID?
    let onSelect: (UUID?) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(containers) { container in
                        Button {
                            onSelect(container.qrID)
                        } label: {
                            HStack(spacing: SBSpacing.medium) {
                                PhotoThumbnailView(
                                    filename: container.photoFilename,
                                    fallbackSystemImage: "shippingbox"
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(container.name)
                                        .foregroundStyle(Color.sbTextPrimary)

                                    if let location = container.location, !location.isEmpty {
                                        Text(location)
                                            .font(.caption)
                                            .foregroundStyle(Color.sbTextSecondary)
                                    }
                                }

                                Spacer()

                                if selectedContainerID == container.qrID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }

                if selectedContainerID != nil {
                    Section {
                        Button(role: .destructive) {
                            onSelect(nil)
                        } label: {
                            Label("Clear label \(slotNumber)", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .sbGroupedBackground()
            .tint(.sbBuzz)
            .navigationTitle("Label \(slotNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSelect(selectedContainerID)
                    }
                }
            }
        }
    }
}
