import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    enum Shadow {
        static let subtle = ShadowStyle(radius: 6, x: 0, y: 3, opacity: 0.08)
        static let medium = ShadowStyle(radius: 12, x: 0, y: 6, opacity: 0.12)
    }

    struct ShadowStyle {
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        let opacity: Double

        func apply(to color: Color = .black) -> some View {
            color.opacity(opacity)
        }
    }
}
