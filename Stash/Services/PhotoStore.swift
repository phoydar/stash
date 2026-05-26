import Foundation
import UIKit

enum PhotoStoreError: Error, LocalizedError {
    case unsupportedImageData
    case failedToEncodeImage

    var errorDescription: String? {
        switch self {
        case .unsupportedImageData:
            return "Choose a valid image file."
        case .failedToEncodeImage:
            return "Could not prepare the photo for storage."
        }
    }
}

final class PhotoStore {
    static let shared = PhotoStore()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager: FileManager
    private let directoryName = "Photos"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func saveImageData(_ data: Data, replacing existingFilename: String? = nil) throws -> String {
        guard let sourceImage = UIImage(data: data) else {
            throw PhotoStoreError.unsupportedImageData
        }

        let storedImage = sourceImage.stashPreparedPhoto(maxPixelDimension: 1_600)
        guard let jpegData = storedImage.jpegData(compressionQuality: 0.82) else {
            throw PhotoStoreError.failedToEncodeImage
        }

        let filename = "\(UUID().uuidString).jpg"
        let url = try photoURL(for: filename)
        try jpegData.write(to: url, options: .atomic)
        cache.setObject(storedImage, forKey: filename as NSString)

        if let existingFilename {
            deletePhoto(filename: existingFilename)
        }

        return filename
    }

    func loadImage(filename: String?) -> UIImage? {
        guard let filename else {
            return nil
        }

        let cacheKey = sanitizedFilename(filename) as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        guard
            let url = try? photoURL(for: filename),
            let image = UIImage(contentsOfFile: url.path)
        else {
            return nil
        }

        cache.setObject(image, forKey: cacheKey)
        return image
    }

    func deletePhoto(filename: String?) {
        guard let filename else {
            return
        }

        let sanitizedFilename = sanitizedFilename(filename)
        cache.removeObject(forKey: sanitizedFilename as NSString)

        guard let url = try? photoURL(for: sanitizedFilename) else {
            return
        }

        try? fileManager.removeItem(at: url)
    }

    func deletePhotos(for container: StorageContainer) {
        deletePhoto(filename: container.photoFilename)
        for item in container.items {
            deletePhoto(filename: item.photoFilename)
        }
    }

    private func photoURL(for filename: String) throws -> URL {
        try photosDirectory()
            .appendingPathComponent(sanitizedFilename(filename), isDirectory: false)
    }

    private func photosDirectory() throws -> URL {
        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        let directoryURL = applicationSupportURL
            .appendingPathComponent("Stash", isDirectory: true)
            .appendingPathComponent(directoryName, isDirectory: true)

        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        return directoryURL
    }

    private func sanitizedFilename(_ filename: String) -> String {
        URL(fileURLWithPath: filename).lastPathComponent
    }
}

private extension UIImage {
    func stashPreparedPhoto(maxPixelDimension: CGFloat) -> UIImage {
        let largestDimension = max(size.width, size.height)
        let scale = largestDimension > maxPixelDimension ? maxPixelDimension / largestDimension : 1
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
