import SwiftUI

@MainActor
final class ReaderStore: ObservableObject {
    enum TextColorStyle: Int, CaseIterable {
        case soft
        case strong
        case accent
    }

    @Published var showArabic: Bool = true
    @Published var showVietnamese: Bool = true
    @Published var showEnglish: Bool = false

    @Published var isFlowMode: Bool = true
    @Published var fontSize: CGFloat = 18

    @Published var gradientIndex: Int = 0
    @Published var textColorIndex: Int = 0

    @Published var isFullScreen: Bool = false

    private let minimumFontSize: CGFloat = 14
    private let maximumFontSize: CGFloat = 26
    private let fontStep: CGFloat = 1

    private var gradientOptions: [ThemeManager.ThemeGradient] {
        ThemeManager.ThemeGradient.allCases
    }

    private var textColorStyles: [TextColorStyle] {
        TextColorStyle.allCases
    }

    func ensureNonEmptyLanguages() {
        if !showArabic && !showVietnamese && !showEnglish {
            showArabic = true
        }
    }

    func toggleLanguage(_ language: ReaderLanguage) {
        switch language {
        case .arabic:
            showArabic.toggle()
        case .vietnamese:
            showVietnamese.toggle()
        case .english:
            showEnglish.toggle()
        }

        ensureNonEmptyLanguages()
    }

    func isLanguageEnabled(_ language: ReaderLanguage) -> Bool {
        switch language {
        case .arabic:
            return showArabic
        case .vietnamese:
            return showVietnamese
        case .english:
            return showEnglish
        }
    }

    func selectLayoutMode(_ mode: ReaderLayoutMode) {
        isFlowMode = (mode == .flow)
    }

    func toggleFullScreen() {
        isFullScreen.toggle()
    }

    func increaseFontSize() {
        fontSize = min(fontSize + fontStep, maximumFontSize)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - fontStep, minimumFontSize)
    }

    var canIncreaseFontSize: Bool {
        fontSize < maximumFontSize - 0.001
    }

    var canDecreaseFontSize: Bool {
        fontSize > minimumFontSize + 0.001
    }

    func cycleGradient(forward: Bool = true) {
        guard !gradientOptions.isEmpty else { return }
        let count = gradientOptions.count
        let nextIndex = (gradientIndex + (forward ? 1 : count - 1)) % count
        gradientIndex = nextIndex
    }

    func cycleTextColor(forward: Bool = true) {
        guard !textColorStyles.isEmpty else { return }
        let count = textColorStyles.count
        let nextIndex = (textColorIndex + (forward ? 1 : count - 1)) % count
        textColorIndex = nextIndex
    }

    var selectedGradient: ThemeManager.ThemeGradient {
        guard gradientIndex >= 0, gradientIndex < gradientOptions.count else {
            return gradientOptions.first ?? .dawn
        }
        return gradientOptions[gradientIndex]
    }

    var selectedTextColorStyle: TextColorStyle {
        guard textColorIndex >= 0, textColorIndex < textColorStyles.count else {
            return textColorStyles.first ?? .soft
        }
        return textColorStyles[textColorIndex]
    }

    func translationTextColor(for colorScheme: ColorScheme) -> Color {
        switch selectedTextColorStyle {
        case .soft:
            return ThemeManager.semanticColor(.secondary, for: selectedGradient, colorScheme: colorScheme)
        case .strong:
            return ThemeManager.semanticColor(.primary, for: selectedGradient, colorScheme: colorScheme)
        case .accent:
            return ThemeManager.accentColor(for: selectedGradient, colorScheme: colorScheme)
        }
    }
}

enum ReaderLanguage: String, CaseIterable, Identifiable {
    case arabic = "AR"
    case vietnamese = "VI"
    case english = "EN"

    var id: String { rawValue }
    var displayTitle: String { rawValue }
}

enum ReaderLayoutMode: String, CaseIterable {
    case flow
    case verse
}
