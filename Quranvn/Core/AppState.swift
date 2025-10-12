import SwiftUI

final class AppState: ObservableObject {
    @Published var showMiniPlayer = false
    @Published var showSurahDashboard = false

    @Published var isLibraryExpanded = false
    @Published var showLibraryFilters = false

    @Published var isSearchFocused = false
    @Published var selectedSearchScope: SearchScope = .all

    @Published var useSystemTheme = true
    @Published var enableNotifications = false
    @Published var selectedFontSize: FontSizeOption = .medium
    @Published var selectedThemeGradient: ThemeManager.ThemeGradient = .dawn
}

enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case surahs = "Surahs"
    case reciters = "Reciters"

    var id: String { rawValue }
}

enum FontSizeOption: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }
}
