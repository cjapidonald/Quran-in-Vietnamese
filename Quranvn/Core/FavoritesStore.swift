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
        guard let data = userDefaults.data(forKey: favoritesKey) else { return }

        do {
            favoriteAyahs = try JSONDecoder().decode(Set<String>.self, from: data)
            print("📖 FavoritesStore - Loaded \(favoriteAyahs.count) favorites")
        } catch {
            print("❌ FavoritesStore - Failed to decode favorites: \(error.localizedDescription)")
        }
    }

    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favoriteAyahs)
            userDefaults.set(data, forKey: favoritesKey)
            print("✅ FavoritesStore - Saved \(favoriteAyahs.count) favorites")
        } catch {
            print("❌ FavoritesStore - Failed to encode favorites: \(error.localizedDescription)")
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
        guard let data = userDefaults.data(forKey: notesKey) else { return }

        do {
            ayahNotes = try JSONDecoder().decode([String: [String]].self, from: data)
            let totalNotes = ayahNotes.values.reduce(0) { $0 + $1.count }
            print("📖 FavoritesStore - Loaded \(totalNotes) notes across \(ayahNotes.count) ayahs")
        } catch {
            print("❌ FavoritesStore - Failed to decode notes: \(error.localizedDescription)")
        }
    }

    private func saveNotes() {
        do {
            let data = try JSONEncoder().encode(ayahNotes)
            userDefaults.set(data, forKey: notesKey)
            let totalNotes = ayahNotes.values.reduce(0) { $0 + $1.count }
            print("✅ FavoritesStore - Saved \(totalNotes) notes")
        } catch {
            print("❌ FavoritesStore - Failed to encode notes: \(error.localizedDescription)")
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
