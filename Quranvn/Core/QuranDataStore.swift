import Foundation
import Combine

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
    @Published private(set) var metadata: QuranMetadata
    @Published private(set) var surahs: [Surah]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "quran", withExtension: "json") else {
            fatalError("Unable to locate quran.json in bundle")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let library = try decoder.decode(QuranLibrary.self, from: data)
            metadata = library.metadata
            surahs = library.surahs
        } catch {
            fatalError("Failed to load Quran data: \(error)")
        }
    }

    func surah(number: Int) -> Surah? {
        surahs.first { $0.number == number }
    }
}
