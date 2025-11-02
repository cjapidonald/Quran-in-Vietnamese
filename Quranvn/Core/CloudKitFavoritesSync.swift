import CloudKit
import Foundation
import Combine

/// Syncs favorites and notes with CloudKit
@MainActor
final class CloudKitFavoritesSync: CloudKitSyncManager {
    private let favoritesStore: FavoritesStore

    init(favoritesStore: FavoritesStore) {
        self.favoritesStore = favoritesStore
        super.init()
    }

    // MARK: - Sync All

    func syncAll() async {
        guard await isCloudKitAvailable() else {
            print("⚠️ CloudKit not available, skipping sync")
            return
        }

        startSync()

        do {
            // Sync favorites and notes in parallel
            try await syncFavorites()
            try await syncNotes()
            endSync()
        } catch {
            endSync(error: error)
        }
    }

    // MARK: - Sync Favorites

    func syncFavorites() async throws {
        print("📤 Syncing favorites to CloudKit...")

        let ownerRecordName = try await getUserRecordName()

        // 1. Fetch all favorites from CloudKit
        let cloudFavorites = try await fetchCloudFavorites(ownerRecordName: ownerRecordName)

        // 2. Get local favorites
        let localFavorites = favoritesStore.favoriteAyahs

        // 3. Determine what needs to be synced
        let cloudAyahIDs = Set(cloudFavorites.map { $0.ayahID })
        let localAyahIDs = localFavorites

        // Favorites to upload (in local but not in cloud)
        let toUpload = localAyahIDs.subtracting(cloudAyahIDs)

        // Favorites to download (in cloud but not in local)
        let toDownload = cloudAyahIDs.subtracting(localAyahIDs)

        // Favorites to delete from cloud (removed locally)
        let toDeleteFromCloud = cloudAyahIDs.subtracting(localAyahIDs)

        print("📊 Favorites - Upload: \(toUpload.count), Download: \(toDownload.count), Delete: \(toDeleteFromCloud.count)")

        // 4. Upload new favorites
        if !toUpload.isEmpty {
            let recordsToSave = toUpload.map { ayahID in
                createFavoriteRecord(ayahID: ayahID, ownerRecordName: ownerRecordName)
            }
            try await saveRecords(recordsToSave)
            print("✅ Uploaded \(recordsToSave.count) favorites")
        }

        // 5. Download new favorites
        if !toDownload.isEmpty {
            for ayahID in toDownload {
                favoritesStore.favoriteAyahs.insert(ayahID)
            }
            print("✅ Downloaded \(toDownload.count) favorites")
        }

        // 6. Delete removed favorites from cloud
        if !toDeleteFromCloud.isEmpty {
            let recordIDsToDelete = cloudFavorites
                .filter { toDeleteFromCloud.contains($0.ayahID) }
                .map { $0.recordID }
            try await deleteRecords(withIDs: recordIDsToDelete)
            print("✅ Deleted \(recordIDsToDelete.count) favorites from cloud")
        }
    }

    private func fetchCloudFavorites(ownerRecordName: String) async throws -> [CloudFavorite] {
        let predicate = NSPredicate(format: "ownerRecordName == %@", ownerRecordName)

        return try await fetchRecords(
            ofType: "FavoriteAyah",
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "favoritedAt", ascending: false)]
        ) { record in
            guard let ayahID = record["ayahID"] as? String else { return nil }
            return CloudFavorite(recordID: record.recordID, ayahID: ayahID)
        }
    }

    private func createFavoriteRecord(ayahID: String, ownerRecordName: String) -> CKRecord {
        let recordID = CKRecord.ID(recordName: "favorite-\(ownerRecordName)-\(ayahID)")
        let record = CKRecord(recordType: "FavoriteAyah", recordID: recordID)

        // Parse ayahID (format: "surahNumber:ayahNumber")
        let components = ayahID.split(separator: ":").compactMap { Int($0) }
        let surahNumber = components.count > 0 ? components[0] : 0
        let ayahNumber = components.count > 1 ? components[1] : 0

        record["ayahID"] = ayahID
        record["surahNumber"] = surahNumber as CKRecordValue
        record["ayahNumber"] = ayahNumber as CKRecordValue
        record["favoritedAt"] = Date() as CKRecordValue
        record["ownerRecordName"] = ownerRecordName

        return record
    }

    // MARK: - Sync Notes

    func syncNotes() async throws {
        print("📤 Syncing notes to CloudKit...")

        let ownerRecordName = try await getUserRecordName()

        // 1. Fetch all notes from CloudKit
        let cloudNotes = try await fetchCloudNotes(ownerRecordName: ownerRecordName)

        // 2. Get local notes
        let localNotes = favoritesStore.ayahNotes

        // 3. Build lookup maps
        var cloudNotesByAyah: [String: [CloudNote]] = [:]
        for note in cloudNotes {
            cloudNotesByAyah[note.ayahID, default: []].append(note)
        }

        // 4. Sync each ayah's notes
        var recordsToSave: [CKRecord] = []
        var recordsToDelete: [CKRecord.ID] = []

        // Upload new local notes
        for (ayahID, localNoteTexts) in localNotes {
            let cloudNotesForAyah = cloudNotesByAyah[ayahID] ?? []
            let cloudNoteTexts = Set(cloudNotesForAyah.map { $0.noteText })

            // Notes to upload
            let notesToUpload = localNoteTexts.filter { !cloudNoteTexts.contains($0) }
            for noteText in notesToUpload {
                let record = createNoteRecord(
                    ayahID: ayahID,
                    noteText: noteText,
                    ownerRecordName: ownerRecordName
                )
                recordsToSave.append(record)
            }

            // Notes to download
            let notesToDownload = cloudNotesForAyah.filter { !localNoteTexts.contains($0.noteText) }
            for note in notesToDownload {
                favoritesStore.ayahNotes[ayahID, default: []].append(note.noteText)
            }

            // Notes to delete from cloud (removed locally)
            let notesToDelete = cloudNotesForAyah.filter { !localNoteTexts.contains($0.noteText) }
            recordsToDelete.append(contentsOf: notesToDelete.map { $0.recordID })
        }

        // Delete notes for ayahs that no longer have any notes locally
        for (ayahID, cloudNotesForAyah) in cloudNotesByAyah {
            if localNotes[ayahID] == nil {
                recordsToDelete.append(contentsOf: cloudNotesForAyah.map { $0.recordID })
            }
        }

        print("📊 Notes - Upload: \(recordsToSave.count), Delete: \(recordsToDelete.count)")

        // 5. Save and delete
        if !recordsToSave.isEmpty {
            try await saveRecords(recordsToSave)
            print("✅ Uploaded \(recordsToSave.count) notes")
        }

        if !recordsToDelete.isEmpty {
            try await deleteRecords(withIDs: recordsToDelete)
            print("✅ Deleted \(recordsToDelete.count) notes from cloud")
        }
    }

    private func fetchCloudNotes(ownerRecordName: String) async throws -> [CloudNote] {
        let predicate = NSPredicate(format: "ownerRecordName == %@", ownerRecordName)

        return try await fetchRecords(
            ofType: "AyahNote",
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
        ) { record in
            guard let ayahID = record["ayahID"] as? String,
                  let noteText = record["noteText"] as? String else { return nil }
            return CloudNote(recordID: record.recordID, ayahID: ayahID, noteText: noteText)
        }
    }

    private func createNoteRecord(ayahID: String, noteText: String, ownerRecordName: String) -> CKRecord {
        let uuid = UUID().uuidString
        let recordID = CKRecord.ID(recordName: "note-\(ownerRecordName)-\(ayahID)-\(uuid)")
        let record = CKRecord(recordType: "AyahNote", recordID: recordID)

        // Parse ayahID
        let components = ayahID.split(separator: ":").compactMap { Int($0) }
        let surahNumber = components.count > 0 ? components[0] : 0
        let ayahNumber = components.count > 1 ? components[1] : 0

        let now = Date()
        record["ayahID"] = ayahID
        record["surahNumber"] = surahNumber as CKRecordValue
        record["ayahNumber"] = ayahNumber as CKRecordValue
        record["noteText"] = noteText
        record["createdAt"] = now as CKRecordValue
        record["modifiedAt"] = now as CKRecordValue
        record["ownerRecordName"] = ownerRecordName

        return record
    }

    // MARK: - Individual Operations

    func uploadFavorite(ayahID: String) async throws {
        let ownerRecordName = try await getUserRecordName()
        let record = createFavoriteRecord(ayahID: ayahID, ownerRecordName: ownerRecordName)
        try await saveRecords([record])
        print("✅ Uploaded favorite: \(ayahID)")
    }

    func deleteFavorite(ayahID: String) async throws {
        let ownerRecordName = try await getUserRecordName()
        let recordID = CKRecord.ID(recordName: "favorite-\(ownerRecordName)-\(ayahID)")
        try await deleteRecords(withIDs: [recordID])
        print("✅ Deleted favorite: \(ayahID)")
    }

    func uploadNote(ayahID: String, noteText: String) async throws {
        let ownerRecordName = try await getUserRecordName()
        let record = createNoteRecord(ayahID: ayahID, noteText: noteText, ownerRecordName: ownerRecordName)
        try await saveRecords([record])
        print("✅ Uploaded note for: \(ayahID)")
    }
}

// MARK: - Helper Types

private struct CloudFavorite {
    let recordID: CKRecord.ID
    let ayahID: String
}

private struct CloudNote {
    let recordID: CKRecord.ID
    let ayahID: String
    let noteText: String
}
