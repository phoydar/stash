import Foundation
import UIKit

struct QRLabelContent: Equatable {
    let qrID: UUID
    var name: String
    var location: String
    var tags: [String]

    var payload: String {
        QRPayload.makeURLString(for: qrID)
    }

    var printableName: String? {
        ContainerName.displayName(from: name)
    }

    init(qrID: UUID, name: String, location: String? = nil, tags: [String] = []) {
        self.qrID = qrID
        self.name = ContainerName.storedName(from: name)
        self.location = location ?? ""
        self.tags = tags
    }

    init(container: StorageContainer) {
        self.init(
            qrID: container.qrID,
            name: container.name,
            location: container.location,
            tags: container.tags
        )
    }

    init(container: ValidationContainer) {
        self.init(
            qrID: container.id,
            name: container.name,
            location: container.location,
            tags: container.tags
        )
    }
}

struct QRLabelSheetAssignment: Equatable, Identifiable {
    let slotIndex: Int
    let content: QRLabelContent

    var id: Int {
        slotIndex
    }
}

enum QRLabelServiceError: Error, LocalizedError {
    case failedToGenerateQRCode
    case failedToEncodePNG
    case failedToEncodePDF

    var errorDescription: String? {
        switch self {
        case .failedToGenerateQRCode:
            return "Could not generate a QR code for this container."
        case .failedToEncodePNG:
            return "Could not encode the label as a PNG file."
        case .failedToEncodePDF:
            return "Could not encode the label sheet as a PDF file."
        }
    }
}

struct QRLabelConfiguration: Equatable {
    var canvasSize: CGSize = Config.labelSizePixels
    var qrSize: CGFloat = Config.qrSizePixels
    var padding: CGFloat = Config.labelPaddingPixels
    var textGap: CGFloat = 18

    static let phaseZero = QRLabelConfiguration()
}

struct QRLabelSheetConfiguration: Equatable {
    var pageSize: CGSize = Config.sheetPageSizePoints
    var labelSize: CGSize = Config.sheetLabelSizePoints
    var columns: Int = Config.sheetColumns
    var rows: Int = Config.sheetRows
    var leftMargin: CGFloat = Config.sheetLeftMarginPoints
    var topMargin: CGFloat = Config.sheetTopMarginPoints
    var horizontalPitch: CGFloat = Config.sheetHorizontalPitchPoints
    var verticalPitch: CGFloat = Config.sheetVerticalPitchPoints
    var qrSize: CGFloat = Config.sheetQRSizePoints
    var padding: CGFloat = Config.sheetLabelPaddingPoints

    var labelsPerSheet: Int {
        columns * rows
    }

    static let phaseZero = QRLabelSheetConfiguration()
}

final class QRLabelService {
    private let qrCodeService: QRCodeService

    init(qrCodeService: QRCodeService = QRCodeService()) {
        self.qrCodeService = qrCodeService
    }

    func renderLabelImage(
        for container: QRLabelContent,
        configuration: QRLabelConfiguration = .phaseZero
    ) throws -> UIImage {
        guard let qrImage = qrCodeService.generateQRCode(
            from: container.payload,
            size: CGSize(width: configuration.qrSize, height: configuration.qrSize)
        ) else {
            throw QRLabelServiceError.failedToGenerateQRCode
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: configuration.canvasSize, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: configuration.canvasSize))

            let qrOriginY = (configuration.canvasSize.height - configuration.qrSize) / 2
            let qrRect = CGRect(
                x: configuration.padding,
                y: qrOriginY,
                width: configuration.qrSize,
                height: configuration.qrSize
            )
            qrImage.draw(in: qrRect)

            let textX = qrRect.maxX + configuration.textGap
            let textWidth = configuration.canvasSize.width - textX - configuration.padding
            let textRect = CGRect(
                x: textX,
                y: configuration.padding + 18,
                width: textWidth,
                height: configuration.canvasSize.height - (configuration.padding * 2)
            )

            drawLabelText(for: container, in: textRect)
        }
    }

    func writeLabelPNG(
        for container: QRLabelContent,
        configuration: QRLabelConfiguration = .phaseZero
    ) throws -> URL {
        let image = try renderLabelImage(for: container, configuration: configuration)

        guard let pngData = image.pngData() else {
            throw QRLabelServiceError.failedToEncodePNG
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("stash-label-\(container.qrID.uuidString).png")
        try pngData.write(to: fileURL, options: .atomic)
        return fileURL
    }

    func writeLabelSheetPDF(
        for container: QRLabelContent,
        configuration: QRLabelSheetConfiguration = .phaseZero
    ) throws -> URL {
        let pdfData = try renderLabelSheetPDFData(for: container, configuration: configuration)
        guard !pdfData.isEmpty else {
            throw QRLabelServiceError.failedToEncodePDF
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("stash-label-sheet-\(container.qrID.uuidString).pdf")
        try pdfData.write(to: fileURL, options: .atomic)
        return fileURL
    }

    func writeLabelSheetPDF(
        assignments: [QRLabelSheetAssignment],
        configuration: QRLabelSheetConfiguration = .phaseZero
    ) throws -> URL {
        let pdfData = try renderLabelSheetPDFData(assignments: assignments, configuration: configuration)
        guard !pdfData.isEmpty else {
            throw QRLabelServiceError.failedToEncodePDF
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("stash-label-sheet-selected.pdf")
        try pdfData.write(to: fileURL, options: .atomic)
        return fileURL
    }

    func renderLabelImage(
        for container: StorageContainer,
        configuration: QRLabelConfiguration = .phaseZero
    ) throws -> UIImage {
        try renderLabelImage(for: QRLabelContent(container: container), configuration: configuration)
    }

    func renderLabelImage(
        for container: ValidationContainer,
        configuration: QRLabelConfiguration = .phaseZero
    ) throws -> UIImage {
        try renderLabelImage(for: QRLabelContent(container: container), configuration: configuration)
    }

    func writeLabelSheetPDF(
        for container: StorageContainer,
        configuration: QRLabelSheetConfiguration = .phaseZero
    ) throws -> URL {
        try writeLabelSheetPDF(for: QRLabelContent(container: container), configuration: configuration)
    }

    func writeLabelSheetPDF(
        for container: ValidationContainer,
        configuration: QRLabelSheetConfiguration = .phaseZero
    ) throws -> URL {
        try writeLabelSheetPDF(for: QRLabelContent(container: container), configuration: configuration)
    }

    private func renderLabelSheetPDFData(
        for container: QRLabelContent,
        configuration: QRLabelSheetConfiguration
    ) throws -> Data {
        guard let qrImage = qrCodeService.generateQRCode(
            from: container.payload,
            size: CGSize(width: configuration.qrSize * 4, height: configuration.qrSize * 4)
        ) else {
            throw QRLabelServiceError.failedToGenerateQRCode
        }

        let bounds = CGRect(origin: .zero, size: configuration.pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)

        return renderer.pdfData { context in
            context.beginPage()

            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(bounds)
            context.cgContext.interpolationQuality = .none

            for row in 0..<configuration.rows {
                for column in 0..<configuration.columns {
                    let origin = CGPoint(
                        x: configuration.leftMargin + (CGFloat(column) * configuration.horizontalPitch),
                        y: configuration.topMargin + (CGFloat(row) * configuration.verticalPitch)
                    )
                    let labelRect = CGRect(origin: origin, size: configuration.labelSize)
                    drawSheetLabel(
                        for: container,
                        qrImage: qrImage,
                        in: labelRect,
                        configuration: configuration
                    )
                }
            }
        }
    }

    private func renderLabelSheetPDFData(
        assignments: [QRLabelSheetAssignment],
        configuration: QRLabelSheetConfiguration
    ) throws -> Data {
        let validAssignments = assignments
            .filter { 0..<configuration.labelsPerSheet ~= $0.slotIndex }
            .sorted { $0.slotIndex < $1.slotIndex }

        let bounds = CGRect(origin: .zero, size: configuration.pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)

        return renderer.pdfData { context in
            context.beginPage()

            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(bounds)
            context.cgContext.interpolationQuality = .none

            for assignment in validAssignments {
                guard let qrImage = qrCodeService.generateQRCode(
                    from: assignment.content.payload,
                    size: CGSize(width: configuration.qrSize * 4, height: configuration.qrSize * 4)
                ) else {
                    continue
                }

                let row = assignment.slotIndex / configuration.columns
                let column = assignment.slotIndex % configuration.columns
                let origin = CGPoint(
                    x: configuration.leftMargin + (CGFloat(column) * configuration.horizontalPitch),
                    y: configuration.topMargin + (CGFloat(row) * configuration.verticalPitch)
                )
                let labelRect = CGRect(origin: origin, size: configuration.labelSize)
                drawSheetLabel(
                    for: assignment.content,
                    qrImage: qrImage,
                    in: labelRect,
                    configuration: configuration
                )
            }
        }
    }

    private func drawLabelText(for container: QRLabelContent, in rect: CGRect) {
        let titleStyle = NSMutableParagraphStyle()
        titleStyle.lineBreakMode = .byTruncatingTail
        titleStyle.alignment = .left

        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.lineBreakMode = .byTruncatingTail
        bodyStyle.alignment = .left

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black,
            .paragraphStyle: titleStyle
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.black,
            .paragraphStyle: bodyStyle
        ]

        let captionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.black,
            .paragraphStyle: bodyStyle
        ]

        drawLabelName(
            container.printableName,
            in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 62),
            attributes: titleAttributes
        )

        NSAttributedString(string: container.location, attributes: bodyAttributes)
            .draw(with: CGRect(x: rect.minX, y: rect.minY + 72, width: rect.width, height: 42), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)

        let tags = container.tags.map { "#\($0)" }.joined(separator: " ")
        NSAttributedString(string: tags, attributes: captionAttributes)
            .draw(with: CGRect(x: rect.minX, y: rect.minY + 122, width: rect.width, height: 32), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
    }

    private func drawSheetLabel(
        for container: QRLabelContent,
        qrImage: UIImage,
        in rect: CGRect,
        configuration: QRLabelSheetConfiguration
    ) {
        let qrRect = CGRect(
            x: rect.minX + configuration.padding,
            y: rect.minY + configuration.padding,
            width: configuration.qrSize,
            height: configuration.qrSize
        )
        qrImage.draw(in: qrRect)

        let textX = qrRect.maxX + configuration.padding
        let textWidth = rect.maxX - textX - configuration.padding
        let textY = rect.minY + configuration.padding
        let textRect = CGRect(
            x: textX,
            y: textY,
            width: textWidth,
            height: rect.maxY - textY - configuration.padding
        )

        drawSheetLabelText(for: container, in: textRect)
    }

    private func drawSheetLabelText(for container: QRLabelContent, in rect: CGRect) {
        let titleStyle = NSMutableParagraphStyle()
        titleStyle.lineBreakMode = .byTruncatingTail
        titleStyle.alignment = .left

        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.lineBreakMode = .byTruncatingTail
        bodyStyle.alignment = .left

        let largeLabel = rect.height >= 100
        let titleFontSize: CGFloat = largeLabel ? 18 : 10.5
        let bodyFontSize: CGFloat = largeLabel ? 12 : 7.5
        let captionFontSize: CGFloat = largeLabel ? 9.5 : 6.5
        let titleHeight: CGFloat = largeLabel ? 40 : 18
        let bodyY: CGFloat = largeLabel ? 46 : 22
        let bodyHeight: CGFloat = largeLabel ? 24 : 12
        let captionY: CGFloat = largeLabel ? 76 : 39
        let captionHeight: CGFloat = largeLabel ? 18 : 10

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: titleFontSize, weight: .bold),
            .foregroundColor: UIColor.black,
            .paragraphStyle: titleStyle
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: bodyFontSize, weight: .medium),
            .foregroundColor: UIColor.black,
            .paragraphStyle: bodyStyle
        ]

        let captionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: captionFontSize, weight: .regular),
            .foregroundColor: UIColor.black,
            .paragraphStyle: bodyStyle
        ]

        drawLabelName(
            container.printableName,
            in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: titleHeight),
            attributes: titleAttributes
        )

        NSAttributedString(string: container.location, attributes: bodyAttributes)
            .draw(with: CGRect(x: rect.minX, y: rect.minY + bodyY, width: rect.width, height: bodyHeight), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)

        let tags = container.tags.map { "#\($0)" }.joined(separator: " ")
        NSAttributedString(string: tags, attributes: captionAttributes)
            .draw(with: CGRect(x: rect.minX, y: rect.minY + captionY, width: rect.width, height: captionHeight), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
    }

    private func drawLabelName(
        _ name: String?,
        in rect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) {
        guard let name else {
            return
        }

        NSAttributedString(string: name, attributes: attributes)
            .draw(with: rect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
    }
}
