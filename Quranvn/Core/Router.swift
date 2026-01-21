import Foundation

enum Router {
    // MARK: - Constants

    /// Valid surah range in the Quran
    private static let validSurahRange = 1...114

    /// Maximum allowed path segment length to prevent abuse
    private static let maxSegmentLength = 10

    // MARK: - Public API

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

    // MARK: - Route Handlers

    private static func handleSurahRoute(url: URL, appState: AppState, quranStore: QuranDataStore) {
        let segments = Array(url.pathComponents.dropFirst())

        // Validate and sanitize surah ID
        guard let first = segments.first,
              let surahID = parseSanitizedInt(first),
              validSurahRange.contains(surahID),
              let surah = quranStore.surah(number: surahID) else {
            presentInvalidSurahAlert(on: appState)
            return
        }

        var ayahNumber: Int? = nil

        if segments.count == 1 {
            ayahNumber = nil
        } else if segments.count == 3,
                  segments[1].lowercased() == "ayah",
                  let parsedAyah = parseSanitizedInt(segments[2]) {
            // Validate ayah is within surah bounds
            let maxAyah = surah.ayahCount
            if parsedAyah >= 1 && parsedAyah <= maxAyah {
                ayahNumber = parsedAyah
            } else {
                // Clamp to valid range instead of failing
                ayahNumber = min(max(parsedAyah, 1), maxAyah)
                print("⚠️ Router - Ayah \(parsedAyah) out of bounds for surah \(surahID), clamped to \(ayahNumber!)")
            }
        } else if segments.count > 1 {
            // Invalid path format
            presentNotFoundAlert(on: appState)
            return
        }

        appState.routingAlert = nil
        appState.pendingReaderDestination = ReaderDestination(surahNumber: surah.number, ayah: ayahNumber ?? 1)
        appState.selectedTab = .library
        appState.showSurahDashboard = true
    }

    // MARK: - Input Sanitization

    /// Parse an integer from a string with length validation
    private static func parseSanitizedInt(_ string: String) -> Int? {
        // Reject overly long strings to prevent abuse
        guard string.count <= maxSegmentLength else {
            print("⚠️ Router - Rejected overly long segment: \(string.prefix(20))...")
            return nil
        }

        // Only allow numeric characters
        guard string.allSatisfy({ $0.isNumber }) else {
            return nil
        }

        return Int(string)
    }

    // MARK: - Alerts

    private static func presentNotFoundAlert(on appState: AppState) {
        appState.routingAlert = RoutingAlert(message: "Không tìm thấy đường dẫn")
    }

    private static func presentInvalidSurahAlert(on appState: AppState) {
        appState.routingAlert = RoutingAlert(message: "Chương không hợp lệ (1-114)")
    }
}
