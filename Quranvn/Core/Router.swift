import Foundation

enum Router {
    static func handle(url: URL, appState: AppState, quranStore: QuranDataStore) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme,
              scheme.caseInsensitiveCompare("quranvn") == .orderedSame else {
            presentNotFoundAlert(on: appState)
            return
        }

        guard let host = components.host?.lowercased() else {
            presentNotFoundAlert(on: appState)
            return
        }

        switch host {
        case "surah":
            handleSurahRoute(url: url, appState: appState, quranStore: quranStore)
        default:
            presentNotFoundAlert(on: appState)
        }
    }

    private static func handleSurahRoute(url: URL, appState: AppState, quranStore: QuranDataStore) {
        let segments = Array(url.pathComponents.dropFirst())

        guard let first = segments.first, let surahID = Int(first),
              let surah = quranStore.surah(number: surahID) else {
            presentNotFoundAlert(on: appState)
            return
        }

        var ayahNumber: Int? = nil

        if segments.count == 1 {
            ayahNumber = nil
        } else if segments.count == 3,
                  segments[1].lowercased() == "ayah",
                  let parsedAyah = Int(segments[2]) {
            ayahNumber = parsedAyah
        } else {
            presentNotFoundAlert(on: appState)
            return
        }

        appState.routingAlert = nil
        appState.pendingReaderDestination = ReaderDestination(surahNumber: surah.number, ayah: ayahNumber ?? 1)
        appState.selectedTab = .library
        appState.showSurahDashboard = true
    }

    private static func presentNotFoundAlert(on appState: AppState) {
        appState.routingAlert = RoutingAlert(message: "Không tìm thấy (tạm thời)")
    }
}
