import SwiftUI

enum SBRadius {
    static let small: CGFloat = 4
    static let base: CGFloat = 6
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let xlarge: CGFloat = 16
}

enum SBSpacing {
    static let xsmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 24
}

extension Color {
    static let sbCanvas = Color(uiColor: .sbDynamic(light: 0xFAF8F4, dark: 0x1A1612))
    static let sbCanvasInset = Color(uiColor: .sbDynamic(light: 0xF0EBE3, dark: 0x100D0A))
    static let sbSurface = Color(uiColor: .sbDynamic(light: 0xFFFFFF, dark: 0x221E18))
    static let sbSurfaceHover = Color(uiColor: .sbDynamic(light: 0xF0EBE3, dark: 0x2C2620))
    static let sbSurfaceSelected = Color(uiColor: .sbDynamic(light: 0xE4DDD0, dark: 0x38312A))

    static let sbTextPrimary = Color(uiColor: .sbDynamic(light: 0x1F1B16, dark: 0xF5EFE6))
    static let sbTextSecondary = Color(uiColor: .sbDynamic(light: 0x524A3D, dark: 0xB5A993))
    static let sbTextTertiary = Color(uiColor: .sbDynamic(light: 0x7C7261, dark: 0x847A6A))
    static let sbTextPlaceholder = Color(uiColor: .sbDynamic(light: 0xADA290, dark: 0x5C5446))

    static let sbBorder = Color(uiColor: .sbDynamic(light: 0xE4DDD0, dark: 0x2C2620))
    static let sbBorderStrong = Color(uiColor: .sbDynamic(light: 0xC5BBA8, dark: 0x463E33))
    static let sbBorderSubtle = Color(uiColor: .sbDynamic(light: 0xEFE9DE, dark: 0x221E18))

    static let sbBuzz = Color(uiColor: .sbDynamic(light: 0xC2410C, dark: 0xFB923C))
    static let sbBuzzPressed = Color(uiColor: .sbDynamic(light: 0x7A2808, dark: 0xEA580C))
    static let sbBuzzSoft = Color(uiColor: .sbDynamic(light: 0xFBE4D5, dark: 0x2D1B0F))
    static let sbBuzzInk = Color(uiColor: .sbDynamic(light: 0xFFFFFF, dark: 0x1A1612))

    static let sbHoney = Color(uiColor: .sbDynamic(light: 0x0F766E, dark: 0x2DD4BF))
    static let sbHoneySoft = Color(uiColor: .sbDynamic(light: 0xCCFBF1, dark: 0x0E2926))
    static let sbMoss = Color(uiColor: .sbDynamic(light: 0x4D7C0F, dark: 0xA3E635))
    static let sbMossSoft = Color(uiColor: .sbDynamic(light: 0xE8F2D8, dark: 0x1A2A09))
}

extension UIColor {
    fileprivate static func sbDynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor.sbHex(dark) : UIColor.sbHex(light)
        }
    }

    private static func sbHex(_ value: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

struct SBCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let fill: Color
    let border: Color

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(border, lineWidth: 1)
            }
    }
}

struct SBPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.sbBuzzInk)
            .frame(minHeight: 44)
            .padding(.horizontal, SBSpacing.large)
            .background(configuration.isPressed ? Color.sbBuzzPressed : Color.sbBuzz)
            .clipShape(RoundedRectangle(cornerRadius: SBRadius.base, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
    }
}

struct SBSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.sbTextPrimary)
            .frame(minHeight: 44)
            .padding(.horizontal, SBSpacing.large)
            .background(configuration.isPressed ? Color.sbSurfaceSelected : Color.sbSurface)
            .clipShape(RoundedRectangle(cornerRadius: SBRadius.base, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SBRadius.base, style: .continuous)
                    .stroke(Color.sbBorderStrong, lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.4)
    }
}

extension View {
    func sbCard(
        cornerRadius: CGFloat = SBRadius.medium,
        fill: Color = .sbSurface,
        border: Color = .sbBorder
    ) -> some View {
        modifier(SBCardModifier(cornerRadius: cornerRadius, fill: fill, border: border))
    }

    func sbGroupedBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.sbCanvas.ignoresSafeArea())
    }
}
