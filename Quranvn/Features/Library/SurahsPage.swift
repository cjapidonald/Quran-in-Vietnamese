import SwiftUI

struct SurahsPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (ReaderDestination) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var readingProgressStore: ReadingProgressStore
    @EnvironmentObject private var quranStore: QuranDataStore

    private var surahList: [Surah] {
        quranStore.surahs.sorted { $0.index < $1.index }
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(surahList) { surah in
                surahButton(for: surah)
            }
        }
    }

    private func surahButton(for surah: Surah) -> some View {
        Button {
            let targetAyah = readingProgressStore.nextAyah(for: surah)
            onSelect(ReaderDestination(surahNumber: surah.number, ayah: targetAyah))
        } label: {
            ZStack(alignment: .leading) {
                progressFill(for: surah)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(surah.vietnameseName)
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    Text("Chương \(surah.number) • \(surah.transliteration)")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
        }
        .buttonStyle(.plain)
    }

    private func progressFill(for surah: Surah) -> some View {
        GeometryReader { geometry in
            let progress = readingProgressStore.progress(for: surah)
            let clamped = min(max(progress, 0), 1)
            let fillWidth = geometry.size.width * CGFloat(clamped)

            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge, style: .continuous)
                .fill(progressGradient)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .mask {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge, style: .continuous)
                        .frame(width: fillWidth, height: geometry.size.height)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .opacity(clamped > 0 ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: clamped)
        }
        .allowsHitTesting(false)
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: theme, colorScheme: colorScheme)
    }

    private var progressGradient: LinearGradient {
        let startOpacity = colorScheme == .dark ? 0.35 : 0.25
        let endOpacity = colorScheme == .dark ? 0.6 : 0.45
        return LinearGradient(
            colors: [
                Color.green.opacity(startOpacity),
                Color.green.opacity(endOpacity)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

#Preview {
    SurahsPage(theme: .dawn) { _ in }
        .environmentObject(ReadingProgressStore())
        .environmentObject(QuranDataStore())
}
