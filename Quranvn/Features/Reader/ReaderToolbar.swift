import SwiftUI

struct ReaderToolbar: View {
    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        layoutSection
            .padding(.vertical, DesignTokens.Spacing.lg)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private var layoutSection: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                adjustablePillButton(icon: "textformat.size.smaller", isEnabled: readerStore.canDecreaseFontSize) {
                    readerStore.decreaseFontSize()
                }

                adjustablePillButton(icon: "textformat.size.larger", isEnabled: readerStore.canIncreaseFontSize) {
                    readerStore.increaseFontSize()
                }

                languageToggleButton(
                    title: "AR",
                    isSelected: readerStore.showArabic
                ) {
                    withAnimation(.easeInOut) {
                        readerStore.toggleLanguage(.arabic)
                    }
                }

                languageToggleButton(
                    title: "VN",
                    isSelected: readerStore.showVietnamese
                ) {
                    withAnimation(.easeInOut) {
                        readerStore.toggleLanguage(.vietnamese)
                    }
                }
            }

            Spacer()

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

    private func pillButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 40, height: 40)
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
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 40, height: 40)
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

    private func languageToggleButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 40, height: 40)
                .foregroundStyle(primaryText.opacity(isSelected ? 1 : 0.4))
                .background(
                    Circle()
                        .fill(primaryText.opacity(isSelected ? 0.12 : 0.04))
                )
        }
        .buttonStyle(.plain)
        .opacity(isSelected ? 1 : 0.8)
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme)
    }

    private var theme: ThemeManager.ThemeGradient {
        readerStore.selectedGradient
    }
}
