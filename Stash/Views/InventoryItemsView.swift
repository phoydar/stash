import SwiftData
import SwiftUI

struct InventoryItemsView: View {
    @Binding var path: [AppRoute]

    @Query private var containers: [StorageContainer]

    @State private var selectedTag: String?
    @State private var selectedLocation: String?
    @State private var selectedUsageFilter: UsageFilter = .all
    @State private var selectedReviewStatus: InventoryReviewStatus?
    @State private var sortMode: ItemSortMode = .name

    private var allItems: [InventoryItemEntry] {
        containers.flatMap { container in
            container.items.map { item in
                InventoryItemEntry(item: item, container: container)
            }
        }
        .sorted(by: sortEntries)
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

            let matchesUsage = selectedUsageFilter.matches(entry.item)

            let matchesReviewStatus = selectedReviewStatus.map { status in
                entry.item.reviewStatus == status
            } ?? true

            return matchesTag && matchesLocation && matchesUsage && matchesReviewStatus
        }
    }

    private var availableTags: [String] {
        uniqueSorted(allItems.flatMap(\.item.tags))
    }

    private var availableLocations: [String] {
        uniqueSorted(allItems.compactMap(\.container.normalizedLocation))
    }

    private var hasActiveFilters: Bool {
        selectedTag != nil
            || selectedLocation != nil
            || selectedUsageFilter != .all
            || selectedReviewStatus != nil
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
                                    selectedUsageFilter: selectedUsageFilter,
                                    selectedReviewStatus: selectedReviewStatus,
                                    clearTag: { selectedTag = nil },
                                    clearLocation: { selectedLocation = nil },
                                    clearUsage: { selectedUsageFilter = .all },
                                    clearReviewStatus: { selectedReviewStatus = nil },
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
                                .contextMenu {
                                    Button {
                                        entry.item.markUsed()
                                    } label: {
                                        Label("Used today", systemImage: "hand.tap")
                                    }

                                    Divider()

                                    ForEach(InventoryReviewStatus.allCases) { status in
                                        Button {
                                            entry.item.setReviewStatus(status)
                                        } label: {
                                            Label(status.displayName, systemImage: status.systemImage)
                                        }
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        entry.item.markUsed()
                                    } label: {
                                        Label("Used", systemImage: "hand.tap")
                                    }
                                    .tint(.sbMoss)
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
                        ForEach(UsageFilter.allCases) { usageFilter in
                            Button {
                                selectedUsageFilter = usageFilter
                            } label: {
                                CheckmarkMenuLabel(
                                    title: usageFilter.displayName,
                                    isSelected: selectedUsageFilter == usageFilter
                                )
                            }
                        }
                    } label: {
                        Label("Usage Filter", systemImage: "clock.arrow.circlepath")
                    }

                    Menu {
                        Button {
                            selectedReviewStatus = nil
                        } label: {
                            CheckmarkMenuLabel(title: "All Review Statuses", isSelected: selectedReviewStatus == nil)
                        }

                        ForEach(InventoryReviewStatus.allCases) { status in
                            Button {
                                selectedReviewStatus = status
                            } label: {
                                CheckmarkMenuLabel(
                                    title: status.displayName,
                                    isSelected: selectedReviewStatus == status
                                )
                            }
                        }
                    } label: {
                        Label("Review Filter", systemImage: "checklist")
                    }

                    Menu {
                        ForEach(ItemSortMode.allCases) { mode in
                            Button {
                                sortMode = mode
                            } label: {
                                CheckmarkMenuLabel(title: mode.displayName, isSelected: sortMode == mode)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }

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
        selectedUsageFilter = .all
        selectedReviewStatus = nil
    }

    private func sortEntries(_ lhs: InventoryItemEntry, _ rhs: InventoryItemEntry) -> Bool {
        switch sortMode {
        case .name:
            let itemComparison = lhs.item.name.localizedCaseInsensitiveCompare(rhs.item.name)
            if itemComparison != .orderedSame {
                return itemComparison == .orderedAscending
            }

            return lhs.container.sortName.localizedCaseInsensitiveCompare(rhs.container.sortName) == .orderedAscending
        case .longestUnused:
            return lhs.item.lastUseReferenceDate < rhs.item.lastUseReferenceDate
        case .recentlyUsed:
            return lhs.item.lastUseReferenceDate > rhs.item.lastUseReferenceDate
        case .dateAdded:
            return lhs.item.createdAt > rhs.item.createdAt
        }
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
                    Text(entry.container.displayName)
                        .font(.subheadline)
                        .foregroundStyle(Color.sbTextSecondary)

                    if let location = entry.container.normalizedLocation {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(Color.sbTextTertiary)
                    }
                }

                ItemUsageChipsView(item: entry.item)
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
    let selectedUsageFilter: UsageFilter
    let selectedReviewStatus: InventoryReviewStatus?
    let clearTag: () -> Void
    let clearLocation: () -> Void
    let clearUsage: () -> Void
    let clearReviewStatus: () -> Void
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

                if selectedUsageFilter != .all {
                    FilterChip(
                        title: selectedUsageFilter.displayName,
                        systemImage: selectedUsageFilter.systemImage,
                        action: clearUsage
                    )
                }

                if let selectedReviewStatus {
                    FilterChip(
                        title: selectedReviewStatus.displayName,
                        systemImage: selectedReviewStatus.systemImage,
                        action: clearReviewStatus
                    )
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
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .imageScale(.small)

                Text(title)
                    .lineLimit(1)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.sbBuzzSoft)
            .foregroundStyle(Color.sbBuzz)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear \(title) filter")
    }
}

private enum UsageFilter: String, CaseIterable, Identifiable {
    case all
    case neverUsed
    case unusedSixMonths
    case unusedTwelveMonths

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .all:
            return "All Usage"
        case .neverUsed:
            return "Never Used"
        case .unusedSixMonths:
            return "Unused 6+ Months"
        case .unusedTwelveMonths:
            return "Unused 12+ Months"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "line.3.horizontal.decrease.circle"
        case .neverUsed:
            return "clock"
        case .unusedSixMonths:
            return "clock.badge.questionmark"
        case .unusedTwelveMonths:
            return "exclamationmark.circle"
        }
    }

    func matches(_ item: InventoryItem) -> Bool {
        switch self {
        case .all:
            return true
        case .neverUsed:
            return item.lastUsedAt == nil
        case .unusedSixMonths:
            return item.hasNoUse(sinceMonths: 6)
        case .unusedTwelveMonths:
            return item.hasNoUse(sinceMonths: 12)
        }
    }
}

private enum ItemSortMode: String, CaseIterable, Identifiable {
    case name
    case longestUnused
    case recentlyUsed
    case dateAdded

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .name:
            return "Name"
        case .longestUnused:
            return "Longest Unused"
        case .recentlyUsed:
            return "Recently Used"
        case .dateAdded:
            return "Date Added"
        }
    }
}

private extension StorageContainer {
    var normalizedLocation: String? {
        let trimmed = location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
