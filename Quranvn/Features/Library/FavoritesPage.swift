import SwiftUI

struct FavoritesPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (FavoriteItem) -> Void

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var quranStore: QuranDataStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedFavorites: Set<UUID> = []

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(currentFavorites) { item in
                favoriteCard(for: item, isExpanded: expandedFavorites.contains(item.id))
                    .highPriorityGesture(
                        TapGesture(count: 2).onEnded {
                            toggleExpansion(for: item)
                        }
                    )
                    .onTapGesture {
                        onSelect(item)
                    }
            }
        }
    }

    private func favoriteCard(for item: FavoriteItem, isExpanded: Bool) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(item.surah.transliteration)
                        .font(.headline)
                        .foregroundStyle(primaryText)
                    Text("Câu số \(item.ayah)")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                }

                Spacer(minLength: DesignTokens.Spacing.md)

                Image(systemName: isExpanded ? "text.quote" : "heart.fill")
                    .font(.title3)
                    .foregroundStyle(accentColor)
            }

            if isExpanded {
                Divider()
                    .background(primaryText.opacity(0.1))

                Text(item.ayahText)
                    .font(.body)
                    .foregroundStyle(primaryText)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
    }

    private func toggleExpansion(for item: FavoriteItem) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            if expandedFavorites.contains(item.id) {
                expandedFavorites.remove(item.id)
            } else {
                expandedFavorites.insert(item.id)
            }
        }
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: theme, colorScheme: colorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: theme, colorScheme: colorScheme)
    }

    private var currentFavorites: [FavoriteItem] {
#if DEBUG
        if let override = appState.debugLibraryFavoritesOverride {
            return override
        }
#endif
        return FavoriteItem.samples(using: quranStore.surahs)
    }
}

struct FavoriteItem: Identifiable {
    let id = UUID()
    let surah: Surah
    let ayah: Int
    let ayahText: String

    static func samples(using surahs: [Surah]) -> [FavoriteItem] {
        let entries = surahs.prefix(5)
        return entries.enumerated().map { index, surah in
            let ayah = surah.ayahs[min(index, surah.ayahs.count - 1)]
            return FavoriteItem(surah: surah, ayah: ayah.number, ayahText: ayah.vietnamese)
        }
    }

    var destination: ReaderDestination {
        ReaderDestination(surahNumber: surah.number, ayah: ayah)
    }
}

#Preview {
    FavoritesPage(theme: .dawn) { _ in }
        .environmentObject(AppState())
        .environmentObject(QuranDataStore())
}
