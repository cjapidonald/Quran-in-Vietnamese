import SwiftUI

struct ReaderToolbar: View {
    let theme: ThemeManager.ThemeGradient
    @Binding var activeLanguages: Set<ReaderLanguage>
    @Binding var layoutMode: ReaderLayoutMode
    @Binding var fontScale: CGFloat
    @Binding var isFullScreen: Bool

    @Environment(\.colorScheme) private var colorScheme

    private let fontScaleRange: ClosedRange<CGFloat> = 0.8...1.4
    private let fontScaleStep: CGFloat = 0.1

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            progressSection
            languageSection
            layoutSection
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Overall Progress")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)
                Spacer()
                Text("42%")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(primaryText)
            }

            ProgressView(value: 0.42)
                .progressViewStyle(.linear)
                .tint(accentColor)
                .frame(height: 6)
                .background(
                    Capsule()
                        .fill(primaryText.opacity(0.08))
                )
                .clipShape(Capsule())
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Languages")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)

            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(ReaderLanguage.allCases) { language in
                    SegmentPill(
                        title: language.displayTitle,
                        isSelected: activeLanguages.contains(language),
                        theme: theme
                    ) {
                        toggleLanguage(language)
                    }
                }
            }
        }
    }

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Layout & Display")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)

            HStack(spacing: DesignTokens.Spacing.sm) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    SegmentPill(
                        title: "Flow",
                        icon: "text.justify",
                        isSelected: layoutMode == .flow,
                        theme: theme
                    ) {
                        layoutMode = .flow
                    }

                    SegmentPill(
                        title: "Verse",
                        icon: "list.number",
                        isSelected: layoutMode == .verse,
                        theme: theme
                    ) {
                        layoutMode = .verse
                    }
                }

                Spacer()

                HStack(spacing: DesignTokens.Spacing.xs) {
                    adjustablePillButton(icon: "textformat.size.smaller", isEnabled: canDecreaseFont) {
                        fontScale = max(fontScaleRange.lowerBound, fontScale - fontScaleStep)
                    }

                    adjustablePillButton(icon: "textformat.size.larger", isEnabled: canIncreaseFont) {
                        fontScale = min(fontScaleRange.upperBound, fontScale + fontScaleStep)
                    }
                }

                pillButton(icon: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isFullScreen.toggle()
                    }
                }
            }
        }
    }

    private func pillButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .frame(width: 32, height: 32)
                .foregroundStyle(primaryText)
                .background(
                    Circle()
                        .fill(primaryText.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }

    private func adjustablePillButton(icon: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .frame(width: 32, height: 32)
                .foregroundStyle(primaryText.opacity(isEnabled ? 1 : 0.4))
                .background(
                    Circle()
                        .fill(primaryText.opacity(isEnabled ? 0.08 : 0.04))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
    }

    private func toggleLanguage(_ language: ReaderLanguage) {
        if activeLanguages.contains(language) {
            activeLanguages.remove(language)
            if activeLanguages.isEmpty {
                activeLanguages.insert(.arabic)
            }
        } else {
            activeLanguages.insert(language)
        }
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: theme, colorScheme: colorScheme)
    }

    private var canDecreaseFont: Bool {
        fontScale > fontScaleRange.lowerBound + 0.001
    }

    private var canIncreaseFont: Bool {
        fontScale < fontScaleRange.upperBound - 0.001
    }
}
