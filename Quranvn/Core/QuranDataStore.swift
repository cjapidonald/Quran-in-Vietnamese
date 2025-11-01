import Foundation
import Combine

enum QuranDataError: LocalizedError {
    case fileNotFound
    case invalidData
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Không tìm thấy dữ liệu Kinh Qur'an. Vui lòng cài đặt lại ứng dụng."
        case .invalidData:
            return "Dữ liệu Kinh Qur'an không hợp lệ. Vui lòng cài đặt lại ứng dụng."
        case .decodingFailed(let error):
            return "Không thể đọc dữ liệu Kinh Qur'an: \(error.localizedDescription)"
        }
    }
}

struct QuranLibrary: Decodable {
    let metadata: QuranMetadata
    let surahs: [Surah]
}

struct QuranMetadata: Decodable {
    struct SourceInfo: Decodable {
        let name: String?
        let author: String?
        let language: String?
        let source: String?
        let link: String?
        let linkmin: String?
        let direction: String?
        let comments: String?
    }

    let generatedAt: String
    let arabicSource: SourceInfo?
    let vietnameseSource: SourceInfo?
    let structureSource: StructureSource

    struct StructureSource: Decodable {
        let name: String
        let url: String
    }

    static var empty: QuranMetadata {
        QuranMetadata(
            generatedAt: "",
            arabicSource: nil,
            vietnameseSource: nil,
            structureSource: StructureSource(name: "", url: "")
        )
    }
}

struct Surah: Identifiable, Hashable, Decodable {
    let number: Int
    let arabicName: String
    let transliteration: String
    let revelationPlace: String?
    let revelationOrder: String?
    let page: String?
    let vietnameseName: String
    let ayahs: [Ayah]

    var id: Int { number }
    var index: Int { number }
    var name: String { transliteration }
    var ayahCount: Int { ayahs.count }
}

struct Ayah: Identifiable, Hashable, Decodable {
    let id: String
    let number: Int
    let arabic: String
    let vietnamese: String
}

@MainActor
final class QuranDataStore: ObservableObject {
    @Published private(set) var metadata: QuranMetadata = .empty
    @Published private(set) var surahs: [Surah] = []
    @Published private(set) var isLoading = true
    @Published var loadError: QuranDataError?

    var hasData: Bool {
        !surahs.isEmpty
    }

    init(bundle: Bundle = .main) {
        Task {
            await loadQuranData(from: bundle)
        }
    }

    private func loadQuranData(from bundle: Bundle) async {
        print("📖 QuranDataStore - Starting to load quran.json...")

        guard let url = bundle.url(forResource: "quran", withExtension: "json") else {
            print("❌ QuranDataStore - quran.json not found in bundle")
            await MainActor.run {
                self.loadError = .fileNotFound
                self.isLoading = false
            }
            return
        }

        do {
            // Load data on background thread to avoid blocking UI
            let data = try await Task.detached(priority: .userInitiated) {
                try Data(contentsOf: url)
            }.value

            print("📖 QuranDataStore - Loaded \(data.count) bytes, decoding...")

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let library = try decoder.decode(QuranLibrary.self, from: data)

            print("✅ QuranDataStore - Successfully loaded \(library.surahs.count) surahs")

            await MainActor.run {
                self.metadata = library.metadata
                self.surahs = library.surahs
                self.isLoading = false
                self.loadError = nil
            }
        } catch let error as DecodingError {
            print("❌ QuranDataStore - Decoding error: \(error)")
            await MainActor.run {
                self.loadError = .decodingFailed(error)
                self.isLoading = false
            }
        } catch {
            print("❌ QuranDataStore - Loading error: \(error)")
            await MainActor.run {
                self.loadError = .invalidData
                self.isLoading = false
            }
        }
    }

    func retry() {
        isLoading = true
        loadError = nil
        Task {
            await loadQuranData(from: .main)
        }
    }

    func surah(number: Int) -> Surah? {
        surahs.first { $0.number == number }
    }
}
