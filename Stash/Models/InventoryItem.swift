import Foundation
import SwiftData

enum InventoryReviewStatus: String, CaseIterable, Identifiable {
    case unreviewed
    case keep
    case considerRemoving
    case donateSell
    case discarded

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .unreviewed:
            return "Unreviewed"
        case .keep:
            return "Keep"
        case .considerRemoving:
            return "Consider removing"
        case .donateSell:
            return "Donate/Sell"
        case .discarded:
            return "Discarded"
        }
    }

    var systemImage: String {
        switch self {
        case .unreviewed:
            return "circle"
        case .keep:
            return "checkmark.circle"
        case .considerRemoving:
            return "questionmark.circle"
        case .donateSell:
            return "arrow.up.heart"
        case .discarded:
            return "trash"
        }
    }
}

@Model
final class InventoryItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Int
    var notes: String?
    var photoFilename: String?
    var lastUsedAt: Date?
    var useCount: Int = 0
    var reviewStatusRawValue: String?
    var reviewedAt: Date?
    var reviewReminderAt: Date?
    var reviewNotificationID: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    var container: StorageContainer?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        notes: String? = nil,
        photoFilename: String? = nil,
        lastUsedAt: Date? = nil,
        useCount: Int = 0,
        reviewStatus: InventoryReviewStatus = .unreviewed,
        reviewedAt: Date? = nil,
        reviewReminderAt: Date? = nil,
        reviewNotificationID: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        container: StorageContainer? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = max(quantity, 1)
        self.notes = notes
        self.photoFilename = photoFilename
        self.lastUsedAt = lastUsedAt
        self.useCount = max(useCount, 0)
        self.reviewStatusRawValue = reviewStatus.rawValue
        self.reviewedAt = reviewedAt
        self.reviewReminderAt = reviewReminderAt
        self.reviewNotificationID = reviewNotificationID
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.container = container
    }

    func touch() {
        updatedAt = Date()
        container?.touch()
    }

    var reviewStatus: InventoryReviewStatus {
        get {
            guard let reviewStatusRawValue,
                  let status = InventoryReviewStatus(rawValue: reviewStatusRawValue) else {
                return .unreviewed
            }

            return status
        }
        set {
            reviewStatusRawValue = newValue.rawValue
        }
    }

    var lastUseReferenceDate: Date {
        lastUsedAt ?? createdAt
    }

    func markUsed(at date: Date = Date()) {
        lastUsedAt = date
        useCount += 1
        touch()
    }

    func setReviewStatus(_ status: InventoryReviewStatus, at date: Date = Date()) {
        let previousStatus = reviewStatus
        reviewStatus = status

        if status == .unreviewed {
            reviewedAt = nil
        } else if previousStatus != status || reviewedAt == nil {
            reviewedAt = date
        }

        touch()
    }

    func hasNoUse(sinceMonths months: Int, now: Date = Date()) -> Bool {
        guard let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: now) else {
            return false
        }

        return lastUseReferenceDate <= cutoff
    }
}
