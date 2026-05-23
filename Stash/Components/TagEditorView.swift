import SwiftUI

struct TagEditorView: View {
    @Binding var tags: [String]

    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if tags.isEmpty {
                Text("No tags added.")
                    .font(.subheadline)
                    .foregroundStyle(Color.sbTextSecondary)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        RemovableTagChip(tag: tag) {
                            tags.removeAll { $0 == tag }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                TextField("Add tag", text: $draft, prompt: Text("christmas ornaments"))
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit(addTag)

                Button(action: addTag) {
                    Label("Add tag", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .disabled(TagParsing.normalizeSingleTag(draft) == nil)
                .accessibilityLabel("Add tag")
            }
        }
        .padding(.vertical, 4)
    }

    private func addTag() {
        let updatedTags = TagParsing.appending(draft, to: tags)
        guard updatedTags != tags else {
            return
        }

        tags = updatedTags
        draft = ""
    }
}

private struct RemovableTagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text("#\(tag)")

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(tag)")
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(Color.sbBuzz)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.sbBuzzSoft)
        .clipShape(Capsule())
    }
}
