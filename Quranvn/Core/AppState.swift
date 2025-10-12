import SwiftUI

final class AppState: ObservableObject {
    @Published var isReaderFullScreen = false
    @Published var showMiniPlayer = false
    @Published var selectedReaderLanguage: ReaderLanguage = .arabic
    @Published var showSurahDashboard = false

    @Published var isLibraryExpanded = false
    @Published var showLibraryFilters = false

    @Published var isSearchFocused = false
    @Published var selectedSearchScope: SearchScope = .all

    @Published var useSystemTheme = true
    @Published var enableNotifications = false
    @Published var selectedFontSize: FontSizeOption = .medium
}

enum ReaderLanguage: String, CaseIterable, Identifiable {
    case arabic = "AR"
    case vietnamese = "VI"
    case english = "EN"

    var id: String { rawValue }
    var displayTitle: String { rawValue }
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
