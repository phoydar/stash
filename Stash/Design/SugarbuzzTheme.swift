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
    static let sbCanvas = Color(uiColor: .sbDynamic(light: 0xFAFAFA, dark: 0x0A0A0B))
    static let sbCanvasInset = Color(uiColor: .sbDynamic(light: 0xF4F4F5, dark: 0x060607))
    static let sbSurface = Color(uiColor: .sbDynamic(light: 0xFFFFFF, dark: 0x131316))
    static let sbSurfaceHover = Color(uiColor: .sbDynamic(light: 0xF4F4F5, dark: 0x1C1C20))
    static let sbSurfaceSelected = Color(uiColor: .sbDynamic(light: 0xE4E4E7, dark: 0x26262B))

    static let sbTextPrimary = Color(uiColor: .sbDynamic(light: 0x09090B, dark: 0xFAFAFA))
    static let sbTextSecondary = Color(uiColor: .sbDynamic(light: 0x52525B, dark: 0xA1A1AA))
    static let sbTextTertiary = Color(uiColor: .sbDynamic(light: 0x71717A, dark: 0x71717A))
    static let sbTextPlaceholder = Color(uiColor: .sbDynamic(light: 0xA1A1AA, dark: 0x52525B))

    static let sbBorder = Color(uiColor: .sbDynamic(light: 0xE4E4E7, dark: 0x26262B))
    static let sbBorderStrong = Color(uiColor: .sbDynamic(light: 0xD4D4D8, dark: 0x3F3F46))
    static let sbBorderSubtle = Color(uiColor: .sbDynamic(light: 0xF0F0F2, dark: 0x1C1C20))

    static let sbBuzz = Color(uiColor: .sbDynamic(light: 0xEC4080, dark: 0xF472B6))
    static let sbBuzzPressed = Color(uiColor: .sbDynamic(light: 0xBE2362, dark: 0xEC4080))
    static let sbBuzzSoft = Color(uiColor: .sbDynamic(light: 0xFCE7F0, dark: 0x2A1320))
    static let sbBuzzInk = Color(uiColor: .sbDynamic(light: 0xFFFFFF, dark: 0x0A0A0B))

    static let sbHoney = Color(uiColor: .sbDynamic(light: 0xF59E0B, dark: 0xFBBF24))
    static let sbHoneySoft = Color(uiColor: .sbDynamic(light: 0xFEF3C7, dark: 0x2A2010))
    static let sbMoss = Color(uiColor: .sbDynamic(light: 0x16A34A, dark: 0x34D399))
    static let sbMossSoft = Color(uiColor: .sbDynamic(light: 0xDCFCE7, dark: 0x0E2A1C))
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
