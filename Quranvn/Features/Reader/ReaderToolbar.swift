import SwiftUI

struct ReaderToolbar: View {
    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme

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
                Text("Tiến độ tổng quan")
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
            Text("Ngôn ngữ")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)

            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(ReaderLanguage.allCases) { language in
                    SegmentPill(
                        title: language.displayTitle,
                        isSelected: readerStore.isLanguageEnabled(language),
                        theme: theme
                    ) {
                        withAnimation(.easeInOut) {
                            readerStore.toggleLanguage(language)
                        }
                    }
                }
            }
        }
    }

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Bố cục & hiển thị")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)

            HStack(spacing: DesignTokens.Spacing.sm) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    SegmentPill(
                        title: "Liên tục",
                        icon: "text.justify",
                        isSelected: readerStore.isFlowMode,
                        theme: theme
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            readerStore.selectLayoutMode(.flow)
                        }
                    }

                    SegmentPill(
                        title: "Theo câu",
                        icon: "list.number",
                        isSelected: !readerStore.isFlowMode,
                        theme: theme
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            readerStore.selectLayoutMode(.verse)
                        }
                    }
                }

                Spacer()

                HStack(spacing: DesignTokens.Spacing.xs) {
                    adjustablePillButton(icon: "textformat.size.smaller", isEnabled: readerStore.canDecreaseFontSize) {
                        readerStore.decreaseFontSize()
                    }

                    adjustablePillButton(icon: "textformat.size.larger", isEnabled: readerStore.canIncreaseFontSize) {
                        readerStore.increaseFontSize()
                    }
                }

                HStack(spacing: DesignTokens.Spacing.xs) {
                    pillButton(icon: "paintpalette") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            readerStore.cycleGradient()
                        }
                    }

                    pillButton(icon: "eyedropper") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            readerStore.cycleTextColor()
                        }
                    }

                    pillButton(icon: readerStore.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            readerStore.toggleFullScreen()
                        }
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

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: theme, colorScheme: colorScheme)
    }

    private var theme: ThemeManager.ThemeGradient {
        readerStore.selectedGradient
    }
}
