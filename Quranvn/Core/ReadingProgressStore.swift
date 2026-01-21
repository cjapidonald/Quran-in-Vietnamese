import SwiftUI
import Combine

@MainActor
final class ReadingProgressStore: ObservableObject {
    private struct SurahProgress: Codable, Equatable {
        var lastReadAyah: Int
        var totalAyahs: Int
    }

    @Published private var progressBySurah: [Int: SurahProgress] = [:] {
        didSet { persist() }
    }

    private let storageKey = "ReadingProgressStore.progress"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func markAyah(_ ayah: Int, asReadIn surah: Surah, totalAyahs: Int) {
        guard ayah > 0 else { return }

        let baseTotal = max(totalAyahs, surah.ayahCount)
        let normalizedTotal = max(baseTotal, 1)
        let previous = progressBySurah[surah.index]
        var entry = previous ?? SurahProgress(lastReadAyah: 0, totalAyahs: normalizedTotal)
        entry.totalAyahs = max(entry.totalAyahs, normalizedTotal)
        entry.totalAyahs = max(entry.totalAyahs, 1)

        if ayah > entry.lastReadAyah {
            entry.lastReadAyah = min(ayah, entry.totalAyahs)
        }

        guard entry != previous else { return }
        progressBySurah[surah.index] = entry
    }

    func progress(for surah: Surah) -> Double {
        let info = progressInfo(for: surah)
        guard info.total > 0 else { return 0 }
        return Double(info.last) / Double(info.total)
    }

    func lastReadAyah(for surah: Surah) -> Int {
        progressInfo(for: surah).last
    }

    func nextAyah(for surah: Surah) -> Int {
        let info = progressInfo(for: surah)
        let next = min(info.last + 1, max(info.total, 1))
        return max(next, 1)
    }

    func overallProgress(for surahs: [Surah]) -> Double {
        let totals = surahs.map { progressInfo(for: $0).total }
        let totalAyahs = totals.reduce(0, +)
        guard totalAyahs > 0 else { return 0 }

        let totalRead = surahs.reduce(0) { partialResult, surah in
            let info = progressInfo(for: surah)
            return partialResult + min(info.last, info.total)
        }

        return Double(totalRead) / Double(totalAyahs)
    }

    // MARK: - Persistence

    private func persist() {
        do {
            let data = try JSONEncoder().encode(progressBySurah)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("❌ ReadingProgressStore - Failed to encode progress: \(error.localizedDescription)")
        }
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            progressBySurah = [:]
            return
        }

        do {
            progressBySurah = try JSONDecoder().decode([Int: SurahProgress].self, from: data)
        } catch {
            print("❌ ReadingProgressStore - Failed to decode progress: \(error.localizedDescription)")
            progressBySurah = [:]
        }
    }

    private func progressInfo(for surah: Surah) -> (last: Int, total: Int) {
        if let stored = progressBySurah[surah.index] {
            let baseTotal = max(stored.totalAyahs, surah.ayahCount)
            let total = max(baseTotal, 1)
            let last = min(max(stored.lastReadAyah, 0), total)
            return (last, total)
        }

        let total = max(surah.ayahCount, 1)
        return (0, total)
    }
}
