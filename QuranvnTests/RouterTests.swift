import XCTest
@testable import Quranvn

@MainActor
final class RouterTests: XCTestCase {

    var mockAppState: AppState!
    var mockQuranStore: QuranDataStore!

    override func setUp() async throws {
        try await super.setUp()
        mockAppState = AppState()
        mockQuranStore = QuranDataStore()
        // Wait for data to load
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    override func tearDown() async throws {
        mockAppState = nil
        mockQuranStore = nil
        try await super.tearDown()
    }

    // MARK: - URL Scheme Tests

    func testHandle_invalidScheme_showsAlert() {
        let url = URL(string: "https://surah/1")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertNotNil(mockAppState.routingAlert)
    }

    func testHandle_validScheme_noAlert() {
        guard !mockQuranStore.surahs.isEmpty else {
            XCTSkip("QuranDataStore not loaded")
            return
        }

        let url = URL(string: "quranvn://surah/1")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertNil(mockAppState.routingAlert)
    }

    func testHandle_caseInsensitiveScheme_works() {
        guard !mockQuranStore.surahs.isEmpty else {
            XCTSkip("QuranDataStore not loaded")
            return
        }

        let url = URL(string: "QURANVN://surah/1")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertNil(mockAppState.routingAlert)
    }

    // MARK: - Surah Route Tests

    func testHandle_validSurahRoute_setsDestination() {
        guard !mockQuranStore.surahs.isEmpty else {
            XCTSkip("QuranDataStore not loaded")
            return
        }

        let url = URL(string: "quranvn://surah/1")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertNotNil(mockAppState.pendingReaderDestination)
        XCTAssertEqual(mockAppState.pendingReaderDestination?.surahNumber, 1)
    }

    func testHandle_validSurahWithAyah_setsDestinationWithAyah() {
        guard !mockQuranStore.surahs.isEmpty else {
            XCTSkip("QuranDataStore not loaded")
            return
        }

        let url = URL(string: "quranvn://surah/2/ayah/255")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertNotNil(mockAppState.pendingReaderDestination)
        XCTAssertEqual(mockAppState.pendingReaderDestination?.surahNumber, 2)
        XCTAssertEqual(mockAppState.pendingReaderDestination?.ayah, 255)
    }

    func testHandle_invalidSurahNumber_showsAlert() {
        let url = URL(string: "quranvn://surah/999")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertNotNil(mockAppState.routingAlert)
    }

    func testHandle_nonNumericSurah_showsAlert() {
        let url = URL(string: "quranvn://surah/abc")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertNotNil(mockAppState.routingAlert)
    }

    func testHandle_unknownHost_showsAlert() {
        let url = URL(string: "quranvn://unknown/1")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertNotNil(mockAppState.routingAlert)
    }

    func testHandle_malformedAyahPath_showsAlert() {
        guard !mockQuranStore.surahs.isEmpty else {
            XCTSkip("QuranDataStore not loaded")
            return
        }

        let url = URL(string: "quranvn://surah/1/ayah")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertNotNil(mockAppState.routingAlert)
    }

    // MARK: - Navigation State Tests

    func testHandle_validRoute_switchesToLibraryTab() {
        guard !mockQuranStore.surahs.isEmpty else {
            XCTSkip("QuranDataStore not loaded")
            return
        }

        mockAppState.selectedTab = .settings
        let url = URL(string: "quranvn://surah/1")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertEqual(mockAppState.selectedTab, .library)
    }

    func testHandle_validRoute_showsSurahDashboard() {
        guard !mockQuranStore.surahs.isEmpty else {
            XCTSkip("QuranDataStore not loaded")
            return
        }

        let url = URL(string: "quranvn://surah/1")!

        Router.handle(url: url, appState: mockAppState, quranStore: mockQuranStore)

        XCTAssertTrue(mockAppState.showSurahDashboard)
    }
}
