import SwiftUI

@main
struct QuranVNARApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
        }
    }
}

private struct RootTabView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            ReaderPage()
                .tabItem {
                    Label("Read", systemImage: "book")
                }

            LibraryPage()
                .tabItem {
                    Label("Library", systemImage: "heart.text.square")
                }

            SearchPage()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            SettingsPage()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(ThemeManager.accentColor(for: colorScheme))
        .background(ThemeManager.backgroundGradient(for: colorScheme))
    }
}
