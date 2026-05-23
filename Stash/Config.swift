import CoreGraphics

enum Config {
    static let appURLScheme = "stash"

    // Single-label preview only. Physical validation uses the PDF sheet constants below.
    static let labelDPI: CGFloat = 203
    static let labelSizePixels = CGSize(width: 400, height: 240)
    static let qrSizePixels: CGFloat = 176
    static let labelPaddingPixels: CGFloat = 12

    // 10-up 2" x 4" US Letter label sheet at 72 pt/in. Avery 5163-compatible geometry.
    static let sheetPageSizePoints = CGSize(width: 612, height: 792)
    static let sheetLabelSizePoints = CGSize(width: 288, height: 144)
    static let sheetColumns = 2
    static let sheetRows = 5
    static let sheetLeftMarginPoints: CGFloat = 11.25
    static let sheetTopMarginPoints: CGFloat = 36
    static let sheetHorizontalPitchPoints: CGFloat = 301.5
    static let sheetVerticalPitchPoints: CGFloat = 144
    static let sheetQRSizePoints: CGFloat = 100
    static let sheetLabelPaddingPoints: CGFloat = 14
}
