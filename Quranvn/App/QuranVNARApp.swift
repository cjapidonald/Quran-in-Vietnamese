import SwiftUI

@main
struct QuranVNARApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var readingProgressStore = ReadingProgressStore()
    @StateObject private var quranStore = QuranDataStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .environmentObject(readingProgressStore)
                .environmentObject(quranStore)
        }
    }
}

private struct RootTabView: View {
    @StateObject private var readerStore = ReaderStore()
    @StateObject private var cloudAuthManager = CloudAuthManager()
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var quranStore: QuranDataStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            LibraryPage()
                .environmentObject(readerStore)
                .tabItem {
                    Label("Thư viện", systemImage: "heart.text.square")
                }
                .tag(AppTab.library)

            SettingsPage()
                .environmentObject(readerStore)
                .environmentObject(cloudAuthManager)
                .tabItem {
                    Label("Cài đặt", systemImage: "gear")
                }
                .tag(AppTab.settings)
        }
        .tint(ThemeManager.accentColor(for: appState.selectedThemeGradient, colorScheme: effectiveColorScheme))
        .background(ThemeManager.backgroundGradient(style: appState.selectedThemeGradient, for: effectiveColorScheme))
        .preferredColorScheme(appState.themeStyle.preferredColorScheme)
        .onOpenURL { url in
            Router.handle(url: url, appState: appState, quranStore: quranStore)
        }
        .alert(item: $appState.routingAlert) { alert in
            Alert(title: Text(alert.message))
        }
    }

    private var effectiveColorScheme: ColorScheme {
        appState.themeStyle.resolvedColorScheme(for: colorScheme)
    }
}
