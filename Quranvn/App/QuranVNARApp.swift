import SwiftUI

@main
struct QuranVNARApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var readingProgressStore = ReadingProgressStore()
    @StateObject private var quranStore = QuranDataStore()
    @StateObject private var favoritesStore = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .environmentObject(readingProgressStore)
                .environmentObject(quranStore)
                .environmentObject(favoritesStore)
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
        Group {
            if quranStore.isLoading {
                loadingView
            } else if let error = quranStore.loadError {
                errorView(error: error)
            } else {
                mainTabView
            }
        }
        .preferredColorScheme(appState.themeStyle.preferredColorScheme)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ThemeManager.accentColor(for: appState.selectedThemeGradient, colorScheme: effectiveColorScheme))

            Text("Đang tải Kinh Qur'an...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeManager.backgroundGradient(style: appState.selectedThemeGradient, for: effectiveColorScheme))
    }

    private func errorView(error: QuranDataError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Lỗi tải dữ liệu")
                .font(.title2)
                .fontWeight(.bold)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                quranStore.retry()
            } label: {
                Label("Thử lại", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(ThemeManager.accentColor(for: appState.selectedThemeGradient, colorScheme: effectiveColorScheme))
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeManager.backgroundGradient(style: appState.selectedThemeGradient, for: effectiveColorScheme))
    }

    private var mainTabView: some View {
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
