import SwiftUI

struct LibraryPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                header
                actionButtons
                libraryPreview
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .background(
            ThemeManager
                .backgroundGradient(style: appState.selectedThemeGradient, for: colorScheme)
                .ignoresSafeArea()
        )
        .tint(accentColor)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Library")
                .font(.largeTitle.bold())
                .foregroundStyle(primaryText)
            Text("Organize favourite recitations and translations")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            PrimaryButton(
                title: appState.isLibraryExpanded ? "Collapse Collections" : "Browse Collections",
                subtitle: "Reveal placeholder collection groups",
                icon: "square.grid.2x2",
                theme: appState.selectedThemeGradient
            ) {
                withAnimation(.spring) { appState.isLibraryExpanded.toggle() }
            }

            PrimaryButton(
                title: appState.showLibraryFilters ? "Hide Filters" : "Show Filters",
                subtitle: "Toggle filtering controls",
                icon: "line.3.horizontal.decrease.circle",
                theme: appState.selectedThemeGradient
            ) {
                withAnimation(.easeInOut) { appState.showLibraryFilters.toggle() }
            }

            PrimaryButton(
                title: "Create Playlist",
                subtitle: "Placeholder for playlist creation flow",
                icon: "music.note.list",
                theme: appState.selectedThemeGradient
            ) {}
        }
    }

    private var libraryPreview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(primaryText)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if appState.isLibraryExpanded {
                    CollectionPlaceholder(
                        title: "Favourite Surahs",
                        items: ["Al-Fatiha", "Al-Baqarah", "Yasin"],
                        theme: appState.selectedThemeGradient,
                        colorScheme: colorScheme
                    )
                    CollectionPlaceholder(
                        title: "Recently Played",
                        items: ["Al-Kahf", "Al-Mulk"],
                        theme: appState.selectedThemeGradient,
                        colorScheme: colorScheme
                    )
                } else {
                    Text("Collections hidden")
                        .foregroundStyle(secondaryText)
                }

                if appState.showLibraryFilters {
                    FilterPlaceholder(theme: appState.selectedThemeGradient)
                }
            }
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
        }
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }
}

private struct CollectionPlaceholder: View {
    let title: String
    let items: [String]
    let theme: ThemeManager.ThemeGradient
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme))
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "heart")
                    .font(.subheadline)
                    .foregroundStyle(ThemeManager.semanticColor(.secondary, for: theme, colorScheme: colorScheme))
            }
        }
    }
}

private struct FilterPlaceholder: View {
    let theme: ThemeManager.ThemeGradient
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Filters")
                .font(.headline)
                .foregroundStyle(ThemeManager.semanticColor(.primary, for: theme, colorScheme: colorScheme))
            HStack(spacing: DesignTokens.Spacing.sm) {
                SegmentPill(title: "All", isSelected: true, theme: theme, action: {})
                SegmentPill(title: "Downloaded", isSelected: false, theme: theme, action: {})
                SegmentPill(title: "Favourites", isSelected: false, theme: theme, action: {})
            }
            Slider(value: .constant(0.5))
                .tint(ThemeManager.accentColor(for: theme, colorScheme: colorScheme))
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.medium)
    }
}

#Preview {
    LibraryPage()
        .environmentObject(AppState())
}
