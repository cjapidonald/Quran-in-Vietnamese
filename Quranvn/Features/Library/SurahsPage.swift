import SwiftUI

struct SurahsPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (SurahPlaceholder) -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var surahList: [SurahPlaceholder] {
        SurahPlaceholder.examples.sorted { $0.index < $1.index }
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(surahList) { surah in
                surahButton(for: surah)
            }
        }
    }

    private func surahButton(for surah: SurahPlaceholder) -> some View {
        Button {
            onSelect(surah)
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(surah.vietnameseName)
                    .font(.headline)
                    .foregroundStyle(primaryText)

                Text("Chương \(surah.index) • \(surah.name)")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
        }
        .buttonStyle(.plain)
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: theme, colorScheme: colorScheme)
    }
}

#Preview {
    SurahsPage(theme: .dawn) { _ in }
}
