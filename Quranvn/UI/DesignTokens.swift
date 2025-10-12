import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32

        /// Shared padding value used by glass cards and large controls.
        static let pad: CGFloat = 16
        /// Default vertical spacing between major sections.
        static let stack: CGFloat = 20
    }

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 20
    }

    enum Shadow {
        static let subtle = ShadowStyle(radius: 6, x: 0, y: 3, opacity: 0.08)
        static let medium = ShadowStyle(radius: 12, x: 0, y: 6, opacity: 0.12)
        static let glass = ShadowStyle(radius: 24, x: 0, y: 14, opacity: 0.15)
    }

    struct ShadowStyle {
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        let opacity: Double

        func color(for colorScheme: ColorScheme, baseColor: Color = .black) -> Color {
            let adjustedOpacity = colorScheme == .dark ? opacity * 0.75 : opacity
            return baseColor.opacity(adjustedOpacity)
        }
    }
}
