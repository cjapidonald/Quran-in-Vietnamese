import SwiftUI
import Combine

@MainActor
final class ReaderStore: ObservableObject {
    enum TextColorStyle: Int, CaseIterable {
        case soft
        case strong
        case accent
    }

    enum ArabicFontOption: String, CaseIterable, Identifiable {
        case uthmani
        case naskh
        case diwani

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .uthmani: "Uthmani"
            case .naskh: "Naskh"
            case .diwani: "Diwani"
            }
        }
    }

    enum TranslationFontOption: String, CaseIterable, Identifiable {
        case serif
        case sans

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .serif: "Serif"
            case .sans: "Sans"
            }
        }
    }

    @Published var showArabic: Bool = true
    @Published var showVietnamese: Bool = true
    @Published var showEnglish: Bool = false

    @Published private(set) var lastLanguageEnforcementID: UUID?

    @Published var isFlowMode: Bool = true
    @Published var fontSize: CGFloat = 18

    @Published var gradientIndex: Int = 0
    @Published var textColorIndex: Int = 0

    @Published var arabicFontSelection: ArabicFontOption = .uthmani
    @Published var translationFontSelection: TranslationFontOption = .serif

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

    func selectGradient(_ gradient: ThemeManager.ThemeGradient) {
        if let index = gradientOptions.firstIndex(of: gradient) {
            gradientIndex = index
        }
    }

    func selectTextColorStyle(_ style: TextColorStyle) {
        if let index = textColorStyles.firstIndex(of: style) {
            textColorIndex = index
        }
    }

    @discardableResult
    func ensureNonEmptyLanguages() -> Bool {
        if !showArabic && !showVietnamese && !showEnglish {
            showArabic = true
            lastLanguageEnforcementID = UUID()
            return true
        }

        return false
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

    func translationTextColor(
        for style: TextColorStyle,
        colorScheme: ColorScheme,
        gradient: ThemeManager.ThemeGradient
    ) -> Color {
        switch style {
        case .soft:
            return ThemeManager.semanticColor(.secondary, for: gradient, colorScheme: colorScheme)
        case .strong:
            return ThemeManager.semanticColor(.primary, for: gradient, colorScheme: colorScheme)
        case .accent:
            return ThemeManager.accentColor(for: gradient, colorScheme: colorScheme)
        }
    }

    func arabicFont(for size: CGFloat) -> Font {
        switch arabicFontSelection {
        case .uthmani:
            return .system(size: size + 6, weight: .semibold, design: .default)
        case .naskh:
            return .system(size: size + 4, weight: .regular, design: .serif)
        case .diwani:
            return .system(size: size + 8, weight: .medium, design: .rounded)
        }
    }

    func translationFont(for size: CGFloat) -> Font {
        switch translationFontSelection {
        case .serif:
            return .system(size: size, weight: .regular, design: .serif)
        case .sans:
            return .system(size: size, weight: .regular, design: .default)
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
