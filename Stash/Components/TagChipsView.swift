import SwiftUI

struct TagChipsView: View {
    let tags: [String]

    var body: some View {
        if !tags.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.sbBuzz)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.sbBuzzSoft)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let rows = rows(for: subviews, proposal: proposal)
        return CGSize(
            width: proposal.width ?? rows.map(\.width).max() ?? 0,
            height: rows.last.map { $0.y + $0.height } ?? 0
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        for row in rows(for: subviews, proposal: ProposedViewSize(width: bounds.width, height: proposal.height)) {
            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private func rows(for subviews: Subviews, proposal: ProposedViewSize) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if current.width > 0, current.width + spacing + size.width > maxWidth {
                rows.append(current)
                current = Row(y: current.y + current.height + spacing)
            }

            let x = current.width == 0 ? 0 : current.width + spacing
            current.items.append(RowItem(subview: subview, x: x, size: size))
            current.width = x + size.width
            current.height = max(current.height, size.height)
        }

        if !current.items.isEmpty {
            rows.append(current)
        }

        return rows
    }

    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
        var y: CGFloat = 0
    }

    private struct RowItem {
        let subview: LayoutSubview
        let x: CGFloat
        let size: CGSize
    }
}
