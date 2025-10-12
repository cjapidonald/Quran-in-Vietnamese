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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Library")
                .font(.largeTitle.bold())
                .foregroundStyle(primaryText)
            Text("Jump to saved favourites or personal notes")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
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
