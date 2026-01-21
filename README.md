# Quran Vietnamese (Quranvn)

An iOS app for reading the Quran with Vietnamese translation, featuring CloudKit sync, favorites, notes, and reading progress tracking.

## Features

- **Quran Reading**: Browse and read all 114 surahs with Vietnamese translation
- **Favorites**: Mark ayahs as favorites for quick access
- **Notes**: Add personal notes to any ayah
- **Reading Progress**: Track your reading progress per surah
- **CloudKit Sync**: Sync favorites, notes, and progress across devices via iCloud
- **Themes**: Multiple theme gradients with light/dark mode support
- **Search**: Search through surahs and content
- **Deep Links**: Navigate directly to specific surahs/ayahs via URL schemes

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Apple Developer account (for CloudKit features)

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd "Quran in vietnamese"
```

### 2. Open in Xcode

```bash
open Quranvn.xcodeproj
```

### 3. Configure signing

1. Select the project in Xcode
2. Go to "Signing & Capabilities"
3. Select your development team
4. Ensure the bundle identifier is unique

### 4. CloudKit Setup (Optional)

The app uses CloudKit for cross-device sync. The container ID is `iCloud.donald.kvietnamisht`.

To use CloudKit:
1. Ensure you have an Apple Developer account
2. The CloudKit container must be created in the Apple Developer portal
3. See `CLOUDKIT_SETUP_FINAL.md` for detailed schema setup

### 5. Build and run

Select a simulator or device and press `Cmd+R`.

## Architecture

The app uses **MVVM** architecture with SwiftUI:

```
Quranvn/
├── App/                    # App entry point
├── Core/                   # Core services and state management
│   ├── AppState.swift      # Global app state
│   ├── QuranDataStore.swift    # Quran data loading
│   ├── FavoritesStore.swift    # Favorites & notes persistence
│   ├── ReadingProgressStore.swift  # Reading progress
│   ├── CloudKitCoordinator.swift   # CloudKit sync coordinator
│   ├── CloudKitSyncManager.swift   # Base CloudKit operations
│   ├── CloudKitFavoritesSync.swift # Favorites/notes sync
│   ├── CloudKitProgressSync.swift  # Progress sync
│   ├── CloudAuthManager.swift      # Sign in with Apple
│   └── Router.swift        # Deep link handling
├── Features/               # Feature modules
│   ├── Audio/              # Audio player views
│   ├── Library/            # Library, favorites, notes pages
│   ├── Reader/             # Quran reader views
│   ├── Search/             # Search functionality
│   └── Settings/           # Settings and attribution
└── UI/                     # Reusable UI components
    ├── ThemeManager.swift  # Theme gradients and colors
    ├── DesignTokens.swift  # Design system tokens
    └── ...                 # UI components
```

## State Management

The app uses `@StateObject` and `@EnvironmentObject` for state:

| Store | Purpose |
|-------|---------|
| `AppState` | UI state, theme, navigation |
| `QuranDataStore` | Quran data (surahs, ayahs) |
| `FavoritesStore` | Favorites and notes |
| `ReadingProgressStore` | Reading progress per surah |
| `ReaderStore` | Reader preferences |

## CloudKit Sync

The app syncs the following data types:
- **FavoriteAyah**: Favorited ayahs
- **AyahNote**: Notes on ayahs
- **ReadingProgress**: Reading progress per surah

Sync features:
- Automatic sync on app launch and every 5 minutes
- Manual sync via settings
- Retry logic for transient failures
- Merge-based conflict resolution

## Deep Links

The app supports URL schemes for navigation:

```
quranvn://surah/{number}
quranvn://surah/{number}/ayah/{ayahNumber}
```

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]
