import SwiftUI

struct LibraryPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                header
                actionButtons
                libraryPreview
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .background(ThemeManager.backgroundGradient(for: colorScheme).ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Library")
                .font(.largeTitle.bold())
            Text("Organize favourite recitations and translations")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Button(action: { withAnimation(.spring) { appState.isLibraryExpanded.toggle() } }) {
                StubButtonLabel(title: appState.isLibraryExpanded ? "Collapse Collections" : "Browse Collections", subtitle: "Reveal placeholder collection groups")
            }

            Button(action: { withAnimation(.easeInOut) { appState.showLibraryFilters.toggle() } }) {
                StubButtonLabel(title: appState.showLibraryFilters ? "Hide Filters" : "Show Filters", subtitle: "Toggle filtering controls")
            }

            Button(action: {}) {
                StubButtonLabel(title: "Create Playlist", subtitle: "Placeholder for playlist creation flow")
            }
        }
    }

    private var libraryPreview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("Preview")
                .font(.headline)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if appState.isLibraryExpanded {
                    CollectionPlaceholder(title: "Favourite Surahs", items: ["Al-Fatiha", "Al-Baqarah", "Yasin"])
                    CollectionPlaceholder(title: "Recently Played", items: ["Al-Kahf", "Al-Mulk"])
                } else {
                    Text("Collections hidden")
                        .foregroundStyle(.secondary)
                }

                if appState.showLibraryFilters {
                    FilterPlaceholder()
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(ThemeManager.cardBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: DesignTokens.Shadow.subtle.radius, x: DesignTokens.Shadow.subtle.x, y: DesignTokens.Shadow.subtle.y)
        }
    }
}

private struct CollectionPlaceholder: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(.title3.weight(.semibold))
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "heart")
                    .font(.subheadline)
            }
        }
    }
}

private struct FilterPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Filters")
                .font(.headline)
            HStack(spacing: DesignTokens.Spacing.sm) {
                TagView(title: "All")
                TagView(title: "Downloaded")
                TagView(title: "Favourites")
            }
            Slider(value: .constant(0.5))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous))
    }
}

private struct TagView: View {
    let title: String

    var body: some View {
        Text(title)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(Color.accentColor.opacity(0.2))
            .clipShape(Capsule())
    }
}

#Preview {
    LibraryPage()
        .environmentObject(AppState())
}
