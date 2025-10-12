import SwiftUI

struct SurahDock: View {
    let surahs: [SurahPlaceholder]
    @Binding var selectedSurah: SurahPlaceholder
    var onSelection: (SurahPlaceholder) -> Void

    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(surahs) { surah in
                    SegmentPill(
                        title: surah.name,
                        isSelected: surah == selectedSurah,
                        theme: readerStore.selectedGradient
                    ) {
                        guard selectedSurah != surah else { return }
                        selectedSurah = surah
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
