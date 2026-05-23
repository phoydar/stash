import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .containers
    @State private var containerPath: [AppRoute] = []
    @State private var itemsPath: [AppRoute] = []
    @State private var searchPath: [AppRoute] = []
    @State private var scanPath: [AppRoute] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            ContainerListView(path: $containerPath)
                .tabItem {
                    Label("Containers", systemImage: "shippingbox")
                }
                .tag(AppTab.containers)

            InventoryItemsView(path: $itemsPath)
                .tabItem {
                    Label("Items", systemImage: "list.bullet.rectangle")
                }
                .tag(AppTab.items)

            SearchView(path: $searchPath)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppTab.search)

            ScanHomeView(path: $scanPath) { uuid in
                routeToContainer(uuid)
            }
            .tabItem {
                Label("Scan", systemImage: "qrcode.viewfinder")
            }
            .tag(AppTab.scan)
        }
        .onOpenURL { url in
            guard let uuid = QRPayload.parse(url.absoluteString) else {
                return
            }

            routeToContainer(uuid)
        }
        .tint(.sbBuzz)
    }

    private func routeToContainer(_ uuid: UUID) {
        selectedTab = .containers
        containerPath = [.container(uuid)]
    }
}
