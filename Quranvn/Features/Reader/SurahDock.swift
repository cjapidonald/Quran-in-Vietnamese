import SwiftUI

struct SurahDock: View {
    let surahs: [Surah]
    @Binding var selectedSurahNumber: Int
    var onSelection: (Surah) -> Void

    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(surahs) { surah in
                    SegmentPill(
                        title: surah.transliteration,
                        isSelected: surah.number == selectedSurahNumber,
                        theme: readerStore.selectedGradient
                    ) {
                        guard selectedSurahNumber != surah.number else { return }
                        selectedSurahNumber = surah.number
                        onSelection(surah)
                    }
                    .lineLimit(1)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
            .padding(.horizontal, DesignTokens.Spacing.sm)
        }
        .background(
            ThemeManager.glassCard(
                cornerRadius: DesignTokens.CornerRadius.large,
                colorScheme: colorScheme
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous))
    }
}
