import Foundation

enum AppRoute: Hashable {
    case container(UUID)
}

enum AppTab: Hashable {
    case containers
    case items
    case search
    case scan
}
