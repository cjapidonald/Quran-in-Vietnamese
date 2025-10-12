import SwiftUI

enum ThemeManager {
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let colors: [Color]
        switch colorScheme {
        case .dark:
            colors = [Color(red: 0.05, green: 0.07, blue: 0.1), Color(red: 0.1, green: 0.15, blue: 0.2)]
        default:
            colors = [Color(red: 0.96, green: 0.97, blue: 0.99), Color.white]
        }

        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom)
    }

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.14, green: 0.16, blue: 0.2)
        default:
            return Color.white
        }
    }

    static func accentColor(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.44, green: 0.75, blue: 0.82)
        default:
            return Color(red: 0.0, green: 0.52, blue: 0.52)
        }
    }
}
