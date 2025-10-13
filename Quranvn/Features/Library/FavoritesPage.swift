import SwiftUI

struct FavoritesPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (FavoriteItem) -> Void

    @EnvironmentObject private var appState: AppState
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
                    Text(item.surah.name)
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
        return FavoriteItem.samples
    }
}

struct FavoriteItem: Identifiable {
    let id = UUID()
    let surah: SurahPlaceholder
    let ayah: Int
    let ayahText: String

    static let samples: [FavoriteItem] = [
        FavoriteItem(
            surah: SurahPlaceholder.examples[0],
            ayah: 1,
            ayahText: "Nhân danh Allah, Đấng Rộng Lượng, Đấng Khoan Dung."
        ),
        FavoriteItem(
            surah: SurahPlaceholder.examples[1],
            ayah: 7,
            ayahText: "Xin Ngài hướng dẫn chúng con đi trên con đường chính trực."
        ),
        FavoriteItem(
            surah: SurahPlaceholder.examples[2],
            ayah: 5,
            ayahText: "Allah biết rõ điều gì ẩn giấu trong lòng ngực của muôn loài."
        ),
        FavoriteItem(
            surah: SurahPlaceholder.examples[3],
            ayah: 12,
            ayahText: "Allah đã đặt giữa các ngươi tình thương và lòng nhân ái."
        ),
        FavoriteItem(
            surah: SurahPlaceholder.examples[4],
            ayah: 3,
            ayahText: "Hãy giữ lời giao ước, bởi vì lời giao ước sẽ được tra hỏi."
        )
    ]

    var destination: ReaderDestination {
        ReaderDestination(surah: surah, ayah: ayah)
    }
}

#Preview {
    FavoritesPage(theme: .dawn) { _ in }
        .environmentObject(AppState())
}
