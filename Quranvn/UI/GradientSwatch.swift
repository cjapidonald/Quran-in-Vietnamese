import SwiftUI

struct GradientSwatch: View {
    let gradient: ThemeManager.ThemeGradient
    var isSelected: Bool
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(ThemeManager.backgroundGradient(style: gradient, for: colorScheme))
                .frame(width: 60, height: 60)
                .overlay(selectionRing)
                .shadow(
                    color: DesignTokens.Shadow.subtle.color(for: colorScheme),
                    radius: 8,
                    x: 0,
                    y: 6
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(gradient.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var selectionRing: some View {
        Circle()
            .strokeBorder(
                isSelected
                    ? ThemeManager.accentColor(for: gradient, colorScheme: colorScheme)
                    : Color.white.opacity(colorScheme == .dark ? 0.4 : 0.6),
                lineWidth: isSelected ? 4 : 1
            )
            .padding(isSelected ? -4 : -2)
    }
}
