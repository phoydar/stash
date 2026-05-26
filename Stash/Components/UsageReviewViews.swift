import SwiftUI

struct LifecycleDateRow: View {
    let title: String
    let date: Date?
    var emptyValue = "Never"

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let date {
                Text(date, format: .dateTime.month(.abbreviated).day().year())
                    .foregroundStyle(Color.sbTextSecondary)
            } else {
                Text(emptyValue)
                    .foregroundStyle(Color.sbTextTertiary)
            }
        }
    }
}

struct LifecycleCountRow: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(max(count, 0))")
                .foregroundStyle(Color.sbTextSecondary)
        }
    }
}

struct ReviewStatusChip: View {
    let status: InventoryReviewStatus

    var body: some View {
        UsageBadgeContent(
            title: status.displayName,
            systemImage: status.systemImage,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor
        )
    }

    private var foregroundColor: Color {
        switch status {
        case .unreviewed:
            return .sbTextTertiary
        case .keep:
            return .sbMoss
        case .considerRemoving:
            return .sbHoney
        case .donateSell:
            return .sbBuzz
        case .discarded:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .unreviewed:
            return .sbSurfaceSelected
        case .keep:
            return .sbMossSoft
        case .considerRemoving:
            return .sbHoneySoft
        case .donateSell:
            return .sbBuzzSoft
        case .discarded:
            return .red.opacity(0.12)
        }
    }
}

struct ItemUsageChipsView: View {
    let item: InventoryItem

    var body: some View {
        FlowLayout(spacing: 6) {
            if item.reviewStatus != .unreviewed {
                ReviewStatusChip(status: item.reviewStatus)
            }

            if let lastUsedAt = item.lastUsedAt {
                UsageChip(
                    title: "Used \(lastUsedAt.formatted(.dateTime.month(.abbreviated).day().year()))",
                    systemImage: "hand.tap"
                )
            } else {
                UsageChip(title: "Never used", systemImage: "clock")
            }

            if item.useCount > 0 {
                UsageChip(title: "\(item.useCount) uses", systemImage: "number")
            }

            if item.hasNoUse(sinceMonths: 12) {
                UsageChip(title: "Unused 12+ months", systemImage: "exclamationmark.circle", tone: .stale)
            } else if item.hasNoUse(sinceMonths: 6) {
                UsageChip(title: "Unused 6+ months", systemImage: "clock.badge.questionmark", tone: .review)
            }

            if let reviewReminderAt = item.reviewReminderAt {
                UsageChip(
                    title: "Reminder \(reviewReminderAt.formatted(.dateTime.month(.abbreviated).day().year()))",
                    systemImage: "bell",
                    tone: .reminder
                )
            }
        }
    }
}

private struct UsageChip: View {
    enum Tone {
        case neutral
        case review
        case stale
        case reminder
    }

    let title: String
    let systemImage: String
    var tone: Tone = .neutral

    var body: some View {
        UsageBadgeContent(
            title: title,
            systemImage: systemImage,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor
        )
    }

    private var foregroundColor: Color {
        switch tone {
        case .neutral:
            return .sbTextTertiary
        case .review:
            return .sbHoney
        case .stale:
            return .red
        case .reminder:
            return .sbBuzz
        }
    }

    private var backgroundColor: Color {
        switch tone {
        case .neutral:
            return .sbSurfaceSelected
        case .review:
            return .sbHoneySoft
        case .stale:
            return .red.opacity(0.12)
        case .reminder:
            return .sbBuzzSoft
        }
    }
}

private struct UsageBadgeContent: View {
    let title: String
    let systemImage: String
    let foregroundColor: Color
    let backgroundColor: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .imageScale(.small)

            Text(title)
                .lineLimit(1)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(backgroundColor)
        .clipShape(Capsule())
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}
