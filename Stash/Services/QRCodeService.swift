import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

final class QRCodeService {
    private let context = CIContext()

    func generateQRCode(from string: String, size: CGSize) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "Q"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let scaleX = size.width / outputImage.extent.width
        let scaleY = size.height / outputImage.extent.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
