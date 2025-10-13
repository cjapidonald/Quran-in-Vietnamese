import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .library
    @Published var showMiniPlayer = false
    @Published var alwaysShowMiniPlayer = false
    @Published var showSurahDashboard = false

    @Published var pendingReaderDestination: ReaderDestination?
    @Published var routingAlert: RoutingAlert?

    @Published var isLibraryExpanded = false
    @Published var showLibraryFilters = false

    @Published var isSearchFocused = false
    @Published var isSearchPresented = false
    @Published var selectedSearchScope: SearchScope = .all

    @Published var themeStyle: ThemeStyle = .auto
    @Published var selectedThemeGradient: ThemeManager.ThemeGradient = .dawn

    var isMiniPlayerVisible: Bool {
        showMiniPlayer || alwaysShowMiniPlayer
    }

#if DEBUG
    @Published var debugAyahCountOverride: Int?
    @Published var debugLibraryFavoritesOverride: [FavoriteItem]?
    @Published var debugLibraryNotesOverride: [NoteItem]?

    func resetLibraryOverrides() {
        debugLibraryFavoritesOverride = nil
        debugLibraryNotesOverride = nil
    }
#endif
}

struct RoutingAlert: Identifiable {
    let id = UUID()
    let message: String
}

enum AppTab: Hashable {
    case library
    case settings
}

enum SearchScope: String, CaseIterable, Identifiable {
    case all = "Tất cả"
    case surahs = "Chương"
    case reciters = "Qari"

    var id: String { rawValue }
}

extension AppState {
    enum ThemeStyle: String, CaseIterable, Identifiable {
        case auto
        case light
        case dark

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .auto: "Tự động"
            case .light: "Sáng"
            case .dark: "Tối"
            }
        }

        var preferredColorScheme: ColorScheme? {
            switch self {
            case .auto: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }

        func resolvedColorScheme(for system: ColorScheme) -> ColorScheme {
            preferredColorScheme ?? system
        }
    }
}
