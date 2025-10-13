import SwiftUI

struct SurahsPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (ReaderDestination) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var readingProgressStore: ReadingProgressStore
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
            let targetAyah = readingProgressStore.nextAyah(for: surah)
            onSelect(ReaderDestination(surah: surah, ayah: targetAyah))
        } label: {
            ZStack(alignment: .leading) {
                progressFill(for: surah)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(surah.vietnameseName)
                        .font(.headline)
                        .foregroundStyle(primaryText)

                    Text("Chương \(surah.index) • \(surah.name)")
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

    private func progressFill(for surah: SurahPlaceholder) -> some View {
        GeometryReader { geometry in
            let progress = readingProgressStore.progress(for: surah)
            let clamped = min(max(progress, 0), 1)
            let width = geometry.size.width * CGFloat(clamped)

            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge, style: .continuous)
                .fill(progressGradient)
                .frame(width: width, height: geometry.size.height)
                .frame(maxWidth: .infinity, alignment: .leading)
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
}
