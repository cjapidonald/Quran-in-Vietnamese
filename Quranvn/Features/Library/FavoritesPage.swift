import SwiftUI

struct FavoritesPage: View {
    let theme: ThemeManager.ThemeGradient
    let onSelect: (FavoriteItem) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let favorites: [FavoriteItem] = [
        FavoriteItem(surah: SurahPlaceholder.examples[0], ayah: 1),
        FavoriteItem(surah: SurahPlaceholder.examples[1], ayah: 7),
        FavoriteItem(surah: SurahPlaceholder.examples[2], ayah: 5),
        FavoriteItem(surah: SurahPlaceholder.examples[3], ayah: 12),
        FavoriteItem(surah: SurahPlaceholder.examples[4], ayah: 3)
    ]

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(favorites) { item in
                Button {
                    onSelect(item)
                } label: {
                    favoriteRow(for: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func favoriteRow(for item: FavoriteItem) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(item.surah.name)
                    .font(.headline)
                    .foregroundStyle(primaryText)
                Text("Ayah #\(item.ayah)")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }

            Spacer(minLength: DesignTokens.Spacing.md)

            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundStyle(accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: 0)
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
}

struct FavoriteItem: Identifiable {
    let id = UUID()
    let surah: SurahPlaceholder
    let ayah: Int

    var destination: ReaderDestination {
        ReaderDestination(surah: surah, ayah: ayah)
    }
}

#Preview {
    FavoritesPage(theme: .dawn) { _ in }
}
