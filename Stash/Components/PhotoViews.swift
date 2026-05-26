import PhotosUI
import SwiftUI

struct PhotoThumbnailView: View {
    let filename: String?
    var size: CGFloat = 54
    var fallbackSystemImage: String? = nil
    var cornerRadius: CGFloat = SBRadius.medium

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let fallbackSystemImage {
                Image(systemName: fallbackSystemImage)
                    .font(.system(size: size * 0.38, weight: .medium))
                    .foregroundStyle(Color.sbTextTertiary)
            }
        }
        .frame(width: size, height: size)
        .background(Color.sbSurfaceSelected)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.sbBorder, lineWidth: 1)
        }
        .task(id: filename) {
            image = PhotoStore.shared.loadImage(filename: filename)
        }
        .accessibilityHidden(image == nil && fallbackSystemImage == nil)
    }
}

struct PhotoPickerSection: View {
    let title: String
    let existingFilename: String?
    let emptyTitle: String
    let emptySystemImage: String

    @Binding var selectedPhotoData: Data?
    @Binding var shouldRemoveExistingPhoto: Bool

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var storedImage: UIImage?
    @State private var selectedPreviewImage: UIImage?
    @State private var errorMessage: String?

    private var previewImage: UIImage? {
        selectedPreviewImage ?? (shouldRemoveExistingPhoto ? nil : storedImage)
    }

    var body: some View {
        Section(title) {
            VStack(alignment: .leading, spacing: SBSpacing.medium) {
                ZStack {
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: SBSpacing.small) {
                            Image(systemName: emptySystemImage)
                                .font(.title2)
                            Text(emptyTitle)
                                .font(.subheadline)
                        }
                        .foregroundStyle(Color.sbTextTertiary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 220)
                .background(Color.sbSurfaceSelected)
                .clipShape(RoundedRectangle(cornerRadius: SBRadius.medium, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: SBRadius.medium, style: .continuous)
                        .stroke(Color.sbBorder, lineWidth: 1)
                }
                .clipped()

                HStack {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(previewImage == nil ? "Choose photo" : "Replace photo", systemImage: "photo")
                    }

                    if previewImage != nil {
                        Spacer()

                        Button("Remove", role: .destructive) {
                            removePhoto()
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.vertical, 4)
            .task(id: existingFilename) {
                storedImage = PhotoStore.shared.loadImage(filename: existingFilename)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadSelectedPhoto(newItem)
            }
        }
    }

    private func removePhoto() {
        selectedPhotoItem = nil
        selectedPhotoData = nil
        selectedPreviewImage = nil
        shouldRemoveExistingPhoto = true
        errorMessage = nil
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }

        Task {
            do {
                guard
                    let data = try await item.loadTransferable(type: Data.self),
                    let previewImage = UIImage(data: data)
                else {
                    throw PhotoStoreError.unsupportedImageData
                }

                await MainActor.run {
                    selectedPhotoData = data
                    selectedPreviewImage = previewImage
                    shouldRemoveExistingPhoto = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
