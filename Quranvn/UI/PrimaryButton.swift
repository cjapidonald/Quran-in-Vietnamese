import SwiftUI
#if os(iOS)
import UIKit
#endif

struct PrimaryButton: View {
    let title: String
    let subtitle: String
    var icon: String?
    var trailingIcon: String?
    var theme: ThemeManager.ThemeGradient
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        subtitle: String,
        icon: String? = nil,
        trailingIcon: String? = "chevron.right",
        theme: ThemeManager.ThemeGradient = .emerald,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.trailingIcon = trailingIcon
        self.theme = theme
        self.action = action
    }

    var body: some View {
        Button {
            triggerHaptics()
            action()
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                if let icon {
                    ZStack {
                        Circle()
                            .fill(ThemeManager.accentColor(for: theme, colorScheme: colorScheme).opacity(0.2))
                        Image(systemName: icon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(ThemeManager.accentColor(for: theme, colorScheme: colorScheme))
                    }
                    .frame(width: 42, height: 42)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ThemeManager.semanticColor(.secondary, for: theme, colorScheme: colorScheme))
                }

                Spacer(minLength: DesignTokens.Spacing.md)

                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(ThemeManager.accentColor(for: theme, colorScheme: colorScheme).opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
        }
        .buttonStyle(.plain)
    }

    private func triggerHaptics() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}
