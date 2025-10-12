import SwiftUI

enum ThemeManager {
    enum ThemeGradient: String, CaseIterable, Identifiable {
        case dawn
        case oasis
        case twilight

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .dawn: return "Dawn"
            case .oasis: return "Oasis"
            case .twilight: return "Twilight"
            }
        }
    }

    enum SemanticColorRole {
        case primary
        case secondary
        case accent
    }

    static func backgroundGradient(style: ThemeGradient, for colorScheme: ColorScheme) -> LinearGradient {
        let colors: [Color]
        switch (style, colorScheme) {
        case (.dawn, .dark):
            colors = [Color(red: 0.06, green: 0.08, blue: 0.16), Color(red: 0.11, green: 0.17, blue: 0.27)]
        case (.dawn, _):
            colors = [Color(red: 0.93, green: 0.96, blue: 1.0), Color(red: 0.99, green: 0.99, blue: 1.0)]
        case (.oasis, .dark):
            colors = [Color(red: 0.03, green: 0.15, blue: 0.17), Color(red: 0.04, green: 0.32, blue: 0.34)]
        case (.oasis, _):
            colors = [Color(red: 0.9, green: 0.98, blue: 0.95), Color(red: 0.76, green: 0.91, blue: 0.86)]
        case (.twilight, .dark):
            colors = [Color(red: 0.14, green: 0.08, blue: 0.24), Color(red: 0.06, green: 0.07, blue: 0.16)]
        case (.twilight, _):
            colors = [Color(red: 0.98, green: 0.93, blue: 0.99), Color(red: 0.94, green: 0.96, blue: 1.0)]
        }

        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func accentColor(for style: ThemeGradient, colorScheme: ColorScheme) -> Color {
        switch (style, colorScheme) {
        case (.dawn, .dark):
            return Color(red: 0.46, green: 0.71, blue: 0.98)
        case (.dawn, _):
            return Color(red: 0.18, green: 0.4, blue: 0.85)
        case (.oasis, .dark):
            return Color(red: 0.31, green: 0.75, blue: 0.68)
        case (.oasis, _):
            return Color(red: 0.0, green: 0.58, blue: 0.51)
        case (.twilight, .dark):
            return Color(red: 0.81, green: 0.58, blue: 0.96)
        case (.twilight, _):
            return Color(red: 0.62, green: 0.33, blue: 0.87)
        }
    }

    static func semanticColor(_ role: SemanticColorRole, for style: ThemeGradient, colorScheme: ColorScheme) -> Color {
        switch role {
        case .primary:
            return colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.9)
        case .secondary:
            return colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
        case .accent:
            return accentColor(for: style, colorScheme: colorScheme)
        }
    }

    static func glassCard(cornerRadius: CGFloat, colorScheme: ColorScheme) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.35), lineWidth: 1)
                    .blendMode(.overlay)
            )
    }
}
