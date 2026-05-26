import SwiftData
import SwiftUI

struct SearchView: View {
    @Binding var path: [AppRoute]

    @Query(sort: \StorageContainer.name) private var containers: [StorageContainer]
    @State private var query = ""

    private var results: [StorageContainer] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return containers
        }

        return containers.filter { container in
            container.matchesSearch(trimmed)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if containers.isEmpty {
                    ContentUnavailableView(
                        "No containers",
                        systemImage: "magnifyingglass",
                        description: Text("Create containers before searching inventory.")
                    )
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List(results) { container in
                        NavigationLink(value: AppRoute.container(container.qrID)) {
                            SearchResultRow(container: container)
                        }
                        .listRowBackground(Color.sbSurface)
                    }
                    .listStyle(.insetGrouped)
                    .sbGroupedBackground()
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search items, containers, tags")
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .container(let uuid):
                    ContainerDetailView(qrID: uuid)
                }
            }
        }
    }
}

private struct SearchResultRow: View {
    let container: StorageContainer

    var body: some View {
        HStack(spacing: SBSpacing.medium) {
            PhotoThumbnailView(
                filename: container.photoFilename,
                fallbackSystemImage: "shippingbox"
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(container.name)
                    .font(.headline)
                    .foregroundStyle(Color.sbTextPrimary)

                if let location = container.location, !location.isEmpty {
                    Text(location)
                        .font(.subheadline)
                        .foregroundStyle(Color.sbTextSecondary)
                }

                let itemPreview = container.items
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    .prefix(3)
                    .map(\.name)
                    .joined(separator: ", ")

                if !itemPreview.isEmpty {
                    Text(itemPreview)
                        .font(.caption)
                        .foregroundStyle(Color.sbTextTertiary)
                        .lineLimit(2)
                }

                TagChipsView(tags: container.tags)
            }
        }
        .padding(.vertical, 4)
    }
}

private extension StorageContainer {
    func matchesSearch(_ query: String) -> Bool {
        let needle = query.lowercased()

        if name.lowercased().contains(needle) {
            return true
        }

        if location?.lowercased().contains(needle) == true {
            return true
        }

        if details?.lowercased().contains(needle) == true {
            return true
        }

        if tags.contains(where: { $0.lowercased().contains(needle) }) {
            return true
        }

        return items.contains { item in
            item.name.lowercased().contains(needle)
                || item.notes?.lowercased().contains(needle) == true
                || item.tags.contains { $0.lowercased().contains(needle) }
        }
    }
}
