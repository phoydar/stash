import Foundation

enum QRPayload {
    static let scheme = Config.appURLScheme
    static let containerHost = "container"

    static func makeURL(for id: UUID) -> URL {
        URL(string: "\(scheme)://\(containerHost)/\(id.uuidString)")!
    }

    static func makeURLString(for id: UUID) -> String {
        makeURL(for: id).absoluteString
    }

    static func parse(_ value: String) -> UUID? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if let uuid = UUID(uuidString: trimmed) {
            return uuid
        }

        guard
            let url = URL(string: trimmed),
            url.scheme?.lowercased() == scheme,
            url.host?.lowercased() == containerHost,
            let candidate = url.pathComponents.dropFirst().first
        else {
            return nil
        }

        return UUID(uuidString: candidate)
    }
}
