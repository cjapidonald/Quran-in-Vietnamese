import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SegmentPill: View {
    let title: String
    var icon: String?
    var isSelected: Bool
    var theme: ThemeManager.ThemeGradient
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        ThemeManager.accentColor(for: theme, colorScheme: colorScheme)
    }

    private var textColor: Color {
        isSelected
            ? Color.white.opacity(colorScheme == .dark ? 0.95 : 1.0)
            : ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme)
    }

    var body: some View {
        Button {
            triggerHaptics()
            action()
        } label: {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.footnote.weight(.semibold))
                }

                Text(title)
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(textColor)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(background)
            .overlay(border)
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var gradientColors: [Color] {
        if isSelected {
            return [accentColor.opacity(0.95), accentColor.opacity(0.75)]
        } else {
            let base = colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6)
            return [base, base.opacity(0.85)]
        }
    }

    private var border: some View {
        Capsule()
            .strokeBorder(
                isSelected
                    ? Color.white.opacity(colorScheme == .dark ? 0.8 : 0.6)
                    : ThemeManager.semanticColor(.secondary, for: theme, colorScheme: colorScheme).opacity(0.2),
                lineWidth: isSelected ? 1.5 : 1
            )
    }

    private func triggerHaptics() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}
