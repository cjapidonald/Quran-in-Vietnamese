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
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var readingProgressStore: ReadingProgressStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var cloudKitCoordinator: CloudKitCoordinator?

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
        .onAppear {
            initializeCloudKitIfNeeded()
        }
        .onChange(of: cloudAuthManager.isSignedIn) { _, isSignedIn in
            handleSignInStatusChange(isSignedIn)
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private func initializeCloudKitIfNeeded() {
        guard cloudKitCoordinator == nil else { return }

        cloudKitCoordinator = CloudKitCoordinator(
            favoritesStore: favoritesStore,
            progressStore: readingProgressStore,
            quranStore: quranStore,
            cloudAuthManager: cloudAuthManager
        )

        print("✅ CloudKitCoordinator initialized")

        // Initial sync if user is already signed in
        if cloudAuthManager.isSignedIn {
            cloudKitCoordinator?.syncAll()
        }
    }

    private func handleSignInStatusChange(_ isSignedIn: Bool) {
        if isSignedIn {
            cloudKitCoordinator?.handleSignIn()
        } else {
            cloudKitCoordinator?.handleSignOut()
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            cloudKitCoordinator?.handleAppDidBecomeActive()
        case .inactive, .background:
            cloudKitCoordinator?.handleAppWillResignActive()
        @unknown default:
            break
        }
    }

    private var effectiveColorScheme: ColorScheme {
        appState.themeStyle.resolvedColorScheme(for: colorScheme)
    }
}
