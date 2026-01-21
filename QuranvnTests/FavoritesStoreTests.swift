import XCTest
@testable import Quranvn

@MainActor
final class FavoritesStoreTests: XCTestCase {

    var sut: FavoritesStore!
    var mockUserDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        mockUserDefaults = UserDefaults(suiteName: "TestDefaults")
        mockUserDefaults.removePersistentDomain(forName: "TestDefaults")
        sut = FavoritesStore(userDefaults: mockUserDefaults)
    }

    override func tearDown() async throws {
        sut = nil
        mockUserDefaults.removePersistentDomain(forName: "TestDefaults")
        mockUserDefaults = nil
        try await super.tearDown()
    }

    // MARK: - Favorites Tests

    func testToggleFavorite_addsNewFavorite() {
        let ayahID = "1:1"

        sut.toggleFavorite(ayahID)

        XCTAssertTrue(sut.isFavorite(ayahID))
        XCTAssertEqual(sut.favoriteAyahs.count, 1)
    }

    func testToggleFavorite_removesExistingFavorite() {
        let ayahID = "1:1"
        sut.toggleFavorite(ayahID) // Add

        sut.toggleFavorite(ayahID) // Remove

        XCTAssertFalse(sut.isFavorite(ayahID))
        XCTAssertEqual(sut.favoriteAyahs.count, 0)
    }

    func testIsFavorite_returnsFalseForNonFavorite() {
        XCTAssertFalse(sut.isFavorite("1:1"))
    }

    func testFavorites_persistAcrossInstances() {
        sut.toggleFavorite("1:1")
        sut.toggleFavorite("2:255")

        let newStore = FavoritesStore(userDefaults: mockUserDefaults)

        XCTAssertTrue(newStore.isFavorite("1:1"))
        XCTAssertTrue(newStore.isFavorite("2:255"))
        XCTAssertEqual(newStore.favoriteAyahs.count, 2)
    }

    // MARK: - Notes Tests

    func testAddNote_createsNewNote() {
        let ayahID = "1:1"
        let noteText = "Test note"

        sut.addNote(noteText, to: ayahID)

        let notes = sut.getNotes(for: ayahID)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first, noteText)
    }

    func testAddNote_appendsToExistingNotes() {
        let ayahID = "1:1"
        sut.addNote("First note", to: ayahID)

        sut.addNote("Second note", to: ayahID)

        let notes = sut.getNotes(for: ayahID)
        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0], "First note")
        XCTAssertEqual(notes[1], "Second note")
    }

    func testGetNotes_returnsEmptyArrayForNoNotes() {
        let notes = sut.getNotes(for: "1:1")
        XCTAssertTrue(notes.isEmpty)
    }

    func testDeleteNote_removesSpecificNote() {
        let ayahID = "1:1"
        sut.addNote("First note", to: ayahID)
        sut.addNote("Second note", to: ayahID)

        sut.deleteNote(at: 0, for: ayahID)

        let notes = sut.getNotes(for: ayahID)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first, "Second note")
    }

    func testDeleteNote_removesAyahEntryWhenLastNoteDeleted() {
        let ayahID = "1:1"
        sut.addNote("Only note", to: ayahID)

        sut.deleteNote(at: 0, for: ayahID)

        XCTAssertNil(sut.ayahNotes[ayahID])
    }

    func testDeleteNote_handlesInvalidIndex() {
        let ayahID = "1:1"
        sut.addNote("Note", to: ayahID)

        sut.deleteNote(at: 5, for: ayahID) // Invalid index

        XCTAssertEqual(sut.getNotes(for: ayahID).count, 1)
    }

    func testNotes_persistAcrossInstances() {
        sut.addNote("Persisted note", to: "1:1")

        let newStore = FavoritesStore(userDefaults: mockUserDefaults)

        let notes = newStore.getNotes(for: "1:1")
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first, "Persisted note")
    }

    // MARK: - Clear All Tests

    func testClearAll_removesAllData() {
        sut.toggleFavorite("1:1")
        sut.toggleFavorite("2:255")
        sut.addNote("Note 1", to: "1:1")
        sut.addNote("Note 2", to: "2:255")

        sut.clearAll()

        XCTAssertTrue(sut.favoriteAyahs.isEmpty)
        XCTAssertTrue(sut.ayahNotes.isEmpty)
    }

    func testClearAll_persistsEmptyState() {
        sut.toggleFavorite("1:1")
        sut.clearAll()

        let newStore = FavoritesStore(userDefaults: mockUserDefaults)

        XCTAssertTrue(newStore.favoriteAyahs.isEmpty)
    }
}
