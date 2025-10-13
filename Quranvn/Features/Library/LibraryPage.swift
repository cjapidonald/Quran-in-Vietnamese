import SwiftUI

struct LibraryPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedSegment: LibrarySegment = .favorites

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                header
                segmentedControl
                segmentContent
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
        Button {
            appState.selectedTab = .read
            appState.showSurahDashboard = true
            appState.isSearchFocused = true
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(primaryText)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Search the Quran")
                        .font(.headline)
                        .foregroundStyle(primaryText)
                    Text("Find surahs, reciters, and more")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private var segmentedControl: some View {
        Picker("Library Section", selection: $selectedSegment) {
            Text("Favorites").tag(LibrarySegment.favorites)
            Text("Notes").tag(LibrarySegment.notes)
        }
        .pickerStyle(.segmented)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    @ViewBuilder
    private var segmentContent: some View {
        switch selectedSegment {
        case .favorites:
            FavoritesPage(theme: appState.selectedThemeGradient) { item in
                openReader(for: item.destination)
            }
        case .notes:
            NotesPage(theme: appState.selectedThemeGradient) { note in
                openReader(for: note.destination)
            }
        }
    }

    private func openReader(for destination: ReaderDestination) {
        appState.pendingReaderDestination = destination
        appState.selectedTab = .read
        appState.showSurahDashboard = true
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

enum LibrarySegment: Hashable {
    case favorites
    case notes
}

#Preview {
    LibraryPage()
        .environmentObject(AppState())
}
