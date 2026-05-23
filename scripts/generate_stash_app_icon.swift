import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct IconSlot {
    let idiom: String
    let size: String
    let scale: String
    let pixels: Int

    var filename: String {
        "AppIcon-\(size.replacingOccurrences(of: ".", with: "_"))@\(scale).png"
    }
}

let slots: [IconSlot] = [
    IconSlot(idiom: "iphone", size: "20x20", scale: "2x", pixels: 40),
    IconSlot(idiom: "iphone", size: "20x20", scale: "3x", pixels: 60),
    IconSlot(idiom: "iphone", size: "29x29", scale: "2x", pixels: 58),
    IconSlot(idiom: "iphone", size: "29x29", scale: "3x", pixels: 87),
    IconSlot(idiom: "iphone", size: "40x40", scale: "2x", pixels: 80),
    IconSlot(idiom: "iphone", size: "40x40", scale: "3x", pixels: 120),
    IconSlot(idiom: "iphone", size: "60x60", scale: "2x", pixels: 120),
    IconSlot(idiom: "iphone", size: "60x60", scale: "3x", pixels: 180),
    IconSlot(idiom: "ios-marketing", size: "1024x1024", scale: "1x", pixels: 1024),
]

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func mix(_ first: UInt32, _ second: UInt32, amount: CGFloat) -> UInt32 {
    let r1 = CGFloat((first >> 16) & 0xFF)
    let g1 = CGFloat((first >> 8) & 0xFF)
    let b1 = CGFloat(first & 0xFF)
    let r2 = CGFloat((second >> 16) & 0xFF)
    let g2 = CGFloat((second >> 8) & 0xFF)
    let b2 = CGFloat(second & 0xFF)
    let r = UInt32(round(r1 + (r2 - r1) * amount))
    let g = UInt32(round(g1 + (g2 - g1) * amount))
    let b = UInt32(round(b1 + (b2 - b1) * amount))
    return (r << 16) | (g << 8) | b
}

func roundedRect(_ rect: CGRect, radius: CGFloat, in context: CGContext, fill: CGColor) {
    context.setFillColor(fill)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.fillPath()
}

func strokeRoundedRect(_ rect: CGRect, radius: CGFloat, in context: CGContext, color strokeColor: CGColor, width: CGFloat) {
    context.setStrokeColor(strokeColor)
    context.setLineWidth(width)
    context.addPath(CGPath(roundedRect: rect.insetBy(dx: width / 2, dy: width / 2), cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.strokePath()
}

func drawModuleGrid(in rect: CGRect, scale: CGFloat, context: CGContext) {
    let units: [(Int, Int)] = [
        (0, 0), (1, 0), (2, 0), (4, 0), (5, 0),
        (0, 1), (2, 1), (5, 1),
        (0, 2), (1, 2), (2, 2), (4, 2),
        (1, 3), (3, 3), (5, 3),
        (0, 4), (2, 4), (3, 4), (4, 4),
        (0, 5), (3, 5), (5, 5),
    ]
    let gap = 10 * scale
    let module = (rect.width - gap * 5) / 6

    for (x, y) in units {
        let origin = CGPoint(
            x: rect.minX + CGFloat(x) * (module + gap),
            y: rect.minY + CGFloat(y) * (module + gap)
        )
        roundedRect(
            CGRect(origin: origin, size: CGSize(width: module, height: module)),
            radius: 8 * scale,
            in: context,
            fill: color(0x111113)
        )
    }
}

func drawIcon(pixels: Int) throws -> Data {
    let scale = CGFloat(pixels) / 1024
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGImageByteOrderInfo.order32Big.rawValue

    guard let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: pixels * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        throw NSError(domain: "StashIcon", code: 1)
    }

    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    context.translateBy(x: 0, y: CGFloat(pixels))
    context.scaleBy(x: 1, y: -1)

    let background = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(0x0A0A0B), color(0x18181B), color(0x101015)] as CFArray,
        locations: [0, 0.58, 1]
    )!
    context.drawLinearGradient(
        background,
        start: CGPoint(x: 0, y: pixels),
        end: CGPoint(x: pixels, y: 0),
        options: []
    )

    let buzzGlow = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(0xEC4080, alpha: 0.30), color(0xEC4080, alpha: 0)] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        buzzGlow,
        startCenter: CGPoint(x: 542 * scale, y: 528 * scale),
        startRadius: 16 * scale,
        endCenter: CGPoint(x: 542 * scale, y: 528 * scale),
        endRadius: 430 * scale,
        options: []
    )

    let honeyGlow = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(0xF59E0B, alpha: 0.26), color(0xF59E0B, alpha: 0)] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        honeyGlow,
        startCenter: CGPoint(x: 374 * scale, y: 620 * scale),
        startRadius: 12 * scale,
        endCenter: CGPoint(x: 374 * scale, y: 620 * scale),
        endRadius: 360 * scale,
        options: []
    )

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 22 * scale), blur: 44 * scale, color: color(0x000000, alpha: 0.34))

    let box = CGRect(x: 234 * scale, y: 324 * scale, width: 556 * scale, height: 440 * scale)
    roundedRect(box, radius: 46 * scale, in: context, fill: color(0xC8DCE5))

    let boxGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(0xF2F8FA), color(0xBBD1DC)] as CFArray,
        locations: [0, 1]
    )!
    context.saveGState()
    context.addPath(CGPath(roundedRect: box, cornerWidth: 46 * scale, cornerHeight: 46 * scale, transform: nil))
    context.clip()
    context.drawLinearGradient(
        boxGradient,
        start: CGPoint(x: box.minX, y: box.minY),
        end: CGPoint(x: box.maxX, y: box.maxY),
        options: []
    )
    context.restoreGState()

    roundedRect(CGRect(x: 206 * scale, y: 254 * scale, width: 612 * scale, height: 110 * scale), radius: 42 * scale, in: context, fill: color(0xF7F7F8))
    roundedRect(CGRect(x: 244 * scale, y: 346 * scale, width: 536 * scale, height: 30 * scale), radius: 15 * scale, in: context, fill: color(0xAFC8D2))
    strokeRoundedRect(box, radius: 46 * scale, in: context, color: color(0xFFFFFF, alpha: 0.72), width: 8 * scale)

    roundedRect(CGRect(x: 318 * scale, y: 392 * scale, width: 388 * scale, height: 304 * scale), radius: 34 * scale, in: context, fill: color(0xFFFFFF, alpha: 0.18))

    let label = CGRect(x: 386 * scale, y: 434 * scale, width: 252 * scale, height: 222 * scale)
    roundedRect(label, radius: 28 * scale, in: context, fill: color(0xFFFFFF))
    strokeRoundedRect(label, radius: 28 * scale, in: context, color: color(0xD4D4D8), width: 7 * scale)
    drawModuleGrid(in: label.insetBy(dx: 38 * scale, dy: 32 * scale), scale: scale, context: context)

    let scanLine = CGRect(x: 362 * scale, y: 528 * scale, width: 300 * scale, height: 20 * scale)
    roundedRect(scanLine, radius: 10 * scale, in: context, fill: color(0xEC4080, alpha: 0.94))

    context.setShadow(offset: .zero, blur: 0, color: nil)
    context.restoreGState()

    let vignette = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(0x000000, alpha: 0), color(0x000000, alpha: 0.26)] as CFArray,
        locations: [0.55, 1]
    )!
    context.drawRadialGradient(
        vignette,
        startCenter: CGPoint(x: 512 * scale, y: 512 * scale),
        startRadius: 140 * scale,
        endCenter: CGPoint(x: 512 * scale, y: 512 * scale),
        endRadius: 720 * scale,
        options: []
    )

    guard let image = context.makeImage() else {
        throw NSError(domain: "StashIcon", code: 2)
    }

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "StashIcon", code: 3)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "StashIcon", code: 4)
    }
    return data as Data
}

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Stash/Assets.xcassets")
let appIconSet = output.appendingPathComponent("AppIcon.appiconset")

if FileManager.default.fileExists(atPath: appIconSet.path) {
    try FileManager.default.removeItem(at: appIconSet)
}

try FileManager.default.createDirectory(at: appIconSet, withIntermediateDirectories: true)

for slot in slots {
    try drawIcon(pixels: slot.pixels).write(to: appIconSet.appendingPathComponent(slot.filename))
}

let images = slots.map { slot in
    [
        "filename": slot.filename,
        "idiom": slot.idiom,
        "scale": slot.scale,
        "size": slot.size,
    ]
}

let appIconContents: [String: Any] = [
    "images": images,
    "info": [
        "author": "xcode",
        "version": 1,
    ],
]

let catalogContents: [String: Any] = [
    "info": [
        "author": "xcode",
        "version": 1,
    ],
]

let jsonOptions: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
try JSONSerialization.data(withJSONObject: appIconContents, options: jsonOptions)
    .write(to: appIconSet.appendingPathComponent("Contents.json"))
try JSONSerialization.data(withJSONObject: catalogContents, options: jsonOptions)
    .write(to: output.appendingPathComponent("Contents.json"))

print("Generated \(slots.count) Stash app icon assets at \(appIconSet.path)")
