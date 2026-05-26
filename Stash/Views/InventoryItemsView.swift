import SwiftData
import SwiftUI

struct InventoryItemsView: View {
    @Binding var path: [AppRoute]

    @Query(sort: \StorageContainer.name) private var containers: [StorageContainer]

    @State private var selectedTag: String?
    @State private var selectedLocation: String?

    private var allItems: [InventoryItemEntry] {
        containers.flatMap { container in
            container.items.map { item in
                InventoryItemEntry(item: item, container: container)
            }
        }
        .sorted { lhs, rhs in
            let itemComparison = lhs.item.name.localizedCaseInsensitiveCompare(rhs.item.name)
            if itemComparison != .orderedSame {
                return itemComparison == .orderedAscending
            }

            return lhs.container.name.localizedCaseInsensitiveCompare(rhs.container.name) == .orderedAscending
        }
    }

    private var filteredItems: [InventoryItemEntry] {
        allItems.filter { entry in
            let matchesTag = selectedTag.map { selectedTag in
                entry.item.tags.contains { tag in
                    tag.localizedCaseInsensitiveCompare(selectedTag) == .orderedSame
                }
            } ?? true

            let matchesLocation = selectedLocation.map { selectedLocation in
                entry.container.normalizedLocation?.localizedCaseInsensitiveCompare(selectedLocation) == .orderedSame
            } ?? true

            return matchesTag && matchesLocation
        }
    }

    private var availableTags: [String] {
        uniqueSorted(allItems.flatMap(\.item.tags))
    }

    private var availableLocations: [String] {
        uniqueSorted(allItems.compactMap(\.container.normalizedLocation))
    }

    private var hasActiveFilters: Bool {
        selectedTag != nil || selectedLocation != nil
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if allItems.isEmpty {
                    ContentUnavailableView(
                        "No inventory",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Add items inside a container.")
                    )
                } else if filteredItems.isEmpty {
                    ContentUnavailableView {
                        Label("No matching items", systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text("Clear filters to show all inventory.")
                    } actions: {
                        Button("Clear Filters", action: clearFilters)
                    }
                } else {
                    List {
                        if hasActiveFilters {
                            Section {
                                InventoryFilterChips(
                                    selectedTag: selectedTag,
                                    selectedLocation: selectedLocation,
                                    clearTag: { selectedTag = nil },
                                    clearLocation: { selectedLocation = nil },
                                    clearAll: clearFilters
                                )
                            }
                            .listRowBackground(Color.sbSurface)
                        }

                        Section {
                            ForEach(filteredItems) { entry in
                                NavigationLink(value: AppRoute.container(entry.container.qrID)) {
                                    InventoryItemRow(entry: entry)
                                }
                                .listRowBackground(Color.sbSurface)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .sbGroupedBackground()
                }
            }
            .navigationTitle("Items")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            selectedTag = nil
                        } label: {
                            CheckmarkMenuLabel(title: "All Tags", isSelected: selectedTag == nil)
                        }

                        ForEach(availableTags, id: \.self) { tag in
                            Button {
                                selectedTag = tag
                            } label: {
                                CheckmarkMenuLabel(title: tag, isSelected: selectedTag == tag)
                            }
                        }
                    } label: {
                        Label("Tag Filter", systemImage: "tag")
                    }
                    .disabled(availableTags.isEmpty)

                    Menu {
                        Button {
                            selectedLocation = nil
                        } label: {
                            CheckmarkMenuLabel(title: "All Locations", isSelected: selectedLocation == nil)
                        }

                        ForEach(availableLocations, id: \.self) { location in
                            Button {
                                selectedLocation = location
                            } label: {
                                CheckmarkMenuLabel(title: location, isSelected: selectedLocation == location)
                            }
                        }
                    } label: {
                        Label("Location Filter", systemImage: "mappin.and.ellipse")
                    }
                    .disabled(availableLocations.isEmpty)
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .container(let uuid):
                    ContainerDetailView(qrID: uuid)
                }
            }
        }
    }

    private func clearFilters() {
        selectedTag = nil
        selectedLocation = nil
    }

    private func uniqueSorted(_ values: [String]) -> [String] {
        let trimmedValues = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(Set(trimmedValues)).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }
}

private struct InventoryItemEntry: Identifiable {
    let item: InventoryItem
    let container: StorageContainer

    var id: UUID {
        item.id
    }
}

private struct InventoryItemRow: View {
    let entry: InventoryItemEntry

    var body: some View {
        HStack(spacing: SBSpacing.medium) {
            PhotoThumbnailView(
                filename: entry.item.photoFilename,
                fallbackSystemImage: "photo"
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.item.name)
                        .font(.headline)
                        .foregroundStyle(Color.sbTextPrimary)
                        .lineLimit(2)

                    Spacer(minLength: SBSpacing.small)

                    Text("x\(entry.item.quantity)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sbTextSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.container.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.sbTextSecondary)

                    if let location = entry.container.normalizedLocation {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(Color.sbTextTertiary)
                    }
                }

                TagChipsView(tags: entry.item.tags)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CheckmarkMenuLabel: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }
}

private struct InventoryFilterChips: View {
    let selectedTag: String?
    let selectedLocation: String?
    let clearTag: () -> Void
    let clearLocation: () -> Void
    let clearAll: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: SBSpacing.small) {
            FlowLayout(spacing: 6) {
                if let selectedTag {
                    FilterChip(title: "#\(selectedTag)", systemImage: "tag", action: clearTag)
                }

                if let selectedLocation {
                    FilterChip(title: selectedLocation, systemImage: "mappin.and.ellipse", action: clearLocation)
                }
            }

            Spacer(minLength: SBSpacing.small)

            Button("Clear", action: clearAll)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.sbBuzz)
        }
        .padding(.vertical, 2)
    }
}

private struct FilterChip: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.sbBuzzSoft)
                .foregroundStyle(Color.sbBuzz)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension StorageContainer {
    var normalizedLocation: String? {
        let trimmed = location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
