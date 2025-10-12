import SwiftUI

private struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    let padding: CGFloat
    let shadowStyle: DesignTokens.ShadowStyle

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ThemeManager.glassCard(cornerRadius: cornerRadius, colorScheme: colorScheme)
            )
            .shadow(
                color: shadowStyle.color(for: colorScheme),
                radius: shadowStyle.radius,
                x: shadowStyle.x,
                y: shadowStyle.y
            )
    }
}

extension View {
    func glassCard(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.extraLarge,
        padding: CGFloat = DesignTokens.Spacing.pad,
        shadowStyle: DesignTokens.ShadowStyle = DesignTokens.Shadow.glass
    ) -> some View {
        modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius,
                padding: padding,
                shadowStyle: shadowStyle
            )
        )
    }
}
