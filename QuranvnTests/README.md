# QuranvnTests

Unit tests for the Quran Vietnamese app.

## Setup

The test files need to be added to a test target in Xcode:

1. Open `Quranvn.xcodeproj` in Xcode
2. Go to **File > New > Target**
3. Select **iOS > Unit Testing Bundle**
4. Name it `QuranvnTests`
5. Set **Host Application** to `Quranvn`
6. Click **Finish**
7. Add all `.swift` files from this directory to the test target:
   - Select all test files in Finder
   - Drag them to the `QuranvnTests` folder in Xcode
   - Ensure **Target Membership** includes `QuranvnTests`

## Test Files

| File | Tests |
|------|-------|
| `FavoritesStoreTests.swift` | Favorites and notes persistence |
| `RouterTests.swift` | Deep link URL parsing and navigation |
| `CloudKitSyncManagerTests.swift` | Retry logic and error handling |

## Running Tests

- **Xcode**: `Cmd + U` or **Product > Test**
- **Command line**: `xcodebuild test -project Quranvn.xcodeproj -scheme Quranvn -destination 'platform=iOS Simulator,name=iPhone 17'`

## Test Coverage

Current coverage focuses on:
- **FavoritesStore**: Favorites management, notes CRUD, persistence
- **Router**: URL scheme validation, surah/ayah routing, error handling
- **CloudKitSyncManager**: Retry logic, error classification, sync state
