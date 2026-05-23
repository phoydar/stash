import Foundation

struct ActivityShareItem: Identifiable {
    let url: URL

    var id: String {
        url.absoluteString
    }
}
