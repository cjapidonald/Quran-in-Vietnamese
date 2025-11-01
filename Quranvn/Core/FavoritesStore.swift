import Foundation
import Combine

@MainActor
final class FavoritesStore: ObservableObject {
    @Published var favoriteAyahs: Set<String> = []
    @Published var ayahNotes: [String: [String]] = [:]

    private let favoritesKey = "favoriteAyahs"
    private let notesKey = "ayahNotes"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadFavorites()
        loadNotes()
    }

    // MARK: - Favorites

    func toggleFavorite(_ ayahID: String) {
        if favoriteAyahs.contains(ayahID) {
            favoriteAyahs.remove(ayahID)
        } else {
            favoriteAyahs.insert(ayahID)
        }
        saveFavorites()
    }

    func isFavorite(_ ayahID: String) -> Bool {
        favoriteAyahs.contains(ayahID)
    }

    private func loadFavorites() {
        if let data = userDefaults.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteAyahs = decoded
            print("📖 FavoritesStore - Loaded \(favoriteAyahs.count) favorites")
        }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteAyahs) {
            userDefaults.set(data, forKey: favoritesKey)
            print("✅ FavoritesStore - Saved \(favoriteAyahs.count) favorites")
        }
    }

    // MARK: - Notes

    func addNote(_ note: String, to ayahID: String) {
        var notes = ayahNotes[ayahID] ?? []
        notes.append(note)
        ayahNotes[ayahID] = notes
        saveNotes()
    }

    func getNotes(for ayahID: String) -> [String] {
        ayahNotes[ayahID] ?? []
    }

    func deleteNote(at index: Int, for ayahID: String) {
        guard var notes = ayahNotes[ayahID], index < notes.count else { return }
        notes.remove(at: index)

        if notes.isEmpty {
            ayahNotes.removeValue(forKey: ayahID)
        } else {
            ayahNotes[ayahID] = notes
        }
        saveNotes()
    }

    private func loadNotes() {
        if let data = userDefaults.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            ayahNotes = decoded
            let totalNotes = ayahNotes.values.reduce(0) { $0 + $1.count }
            print("📖 FavoritesStore - Loaded \(totalNotes) notes across \(ayahNotes.count) ayahs")
        }
    }

    private func saveNotes() {
        if let data = try? JSONEncoder().encode(ayahNotes) {
            userDefaults.set(data, forKey: notesKey)
            let totalNotes = ayahNotes.values.reduce(0) { $0 + $1.count }
            print("✅ FavoritesStore - Saved \(totalNotes) notes")
        }
    }

    // MARK: - Utility

    func clearAll() {
        favoriteAyahs.removeAll()
        ayahNotes.removeAll()
        userDefaults.removeObject(forKey: favoritesKey)
        userDefaults.removeObject(forKey: notesKey)
        print("🗑️ FavoritesStore - Cleared all favorites and notes")
    }
}
