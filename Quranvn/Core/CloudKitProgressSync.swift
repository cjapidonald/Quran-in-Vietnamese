import CloudKit
import Foundation
import Combine

/// Syncs reading progress with CloudKit
@MainActor
final class CloudKitProgressSync: CloudKitSyncManager {
    private let progressStore: ReadingProgressStore
    private let quranStore: QuranDataStore

    init(progressStore: ReadingProgressStore, quranStore: QuranDataStore) {
        self.progressStore = progressStore
        self.quranStore = quranStore
        super.init()
    }

    // MARK: - Sync All

    func syncAll() async {
        guard await isCloudKitAvailable() else {
            print("⚠️ CloudKit not available, skipping progress sync")
            return
        }

        startSync()

        do {
            try await syncProgress()
            endSync()
        } catch {
            endSync(error: error)
        }
    }

    // MARK: - Sync Progress

    func syncProgress() async throws {
        print("📤 Syncing reading progress to CloudKit...")

        let ownerRecordName = try await getUserRecordName()

        // 1. Fetch all progress records from CloudKit
        let cloudProgress = try await fetchCloudProgress(ownerRecordName: ownerRecordName)

        // 2. Get all surahs to check local progress
        let surahs = quranStore.surahs
        guard !surahs.isEmpty else {
            print("⚠️ No surahs loaded, skipping progress sync")
            return
        }

        var recordsToSave: [CKRecord] = []
        var recordsToUpdate: [CKRecord] = []

        // 3. Build lookup map for cloud progress
        var cloudProgressBySurah: [Int: CloudProgress] = [:]
        for progress in cloudProgress {
            cloudProgressBySurah[progress.surahNumber] = progress
        }

        // 4. Sync each surah's progress
        for surah in surahs {
            let localLastRead = progressStore.lastReadAyah(for: surah)

            // Skip surahs with no local progress
            guard localLastRead > 0 else { continue }

            let totalAyahs = surah.ayahCount
            let progressPercentage = Double(localLastRead) / Double(totalAyahs)

            if let cloudProg = cloudProgressBySurah[surah.number] {
                // Cloud record exists - check if we need to update
                if localLastRead > cloudProg.lastReadAyah {
                    // Local is ahead - update cloud
                    let record = updateProgressRecord(
                        recordID: cloudProg.recordID,
                        surahNumber: surah.number,
                        lastReadAyah: localLastRead,
                        totalAyahs: totalAyahs,
                        progressPercentage: progressPercentage,
                        ownerRecordName: ownerRecordName
                    )
                    recordsToUpdate.append(record)
                } else if localLastRead < cloudProg.lastReadAyah {
                    // Cloud is ahead - update local
                    progressStore.markAyah(cloudProg.lastReadAyah, asReadIn: surah, totalAyahs: cloudProg.totalAyahs)
                }
                // If equal, no sync needed
            } else {
                // No cloud record - create new
                let record = createProgressRecord(
                    surahNumber: surah.number,
                    lastReadAyah: localLastRead,
                    totalAyahs: totalAyahs,
                    progressPercentage: progressPercentage,
                    ownerRecordName: ownerRecordName
                )
                recordsToSave.append(record)
            }
        }

        // 5. Download progress for surahs that only exist in cloud
        for (surahNumber, cloudProg) in cloudProgressBySurah {
            guard let surah = quranStore.surah(number: surahNumber) else { continue }
            let localLastRead = progressStore.lastReadAyah(for: surah)

            if localLastRead == 0 && cloudProg.lastReadAyah > 0 {
                // Download cloud progress to local
                progressStore.markAyah(cloudProg.lastReadAyah, asReadIn: surah, totalAyahs: cloudProg.totalAyahs)
            }
        }

        print("📊 Progress - Create: \(recordsToSave.count), Update: \(recordsToUpdate.count)")

        // 6. Save and update
        let allRecordsToSave = recordsToSave + recordsToUpdate
        if !allRecordsToSave.isEmpty {
            try await saveRecords(allRecordsToSave)
            print("✅ Synced \(allRecordsToSave.count) progress records")
        }
    }

    private func fetchCloudProgress(ownerRecordName: String) async throws -> [CloudProgress] {
        let predicate = NSPredicate(format: "ownerRecordName == %@", ownerRecordName)

        return try await fetchRecords(
            ofType: "ReadingProgress",
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "surahNumber", ascending: true)]
        ) { record in
            guard let surahNumber = record["surahNumber"] as? Int,
                  let lastReadAyah = record["lastReadAyah"] as? Int,
                  let totalAyahs = record["totalAyahs"] as? Int else { return nil }

            return CloudProgress(
                recordID: record.recordID,
                surahNumber: surahNumber,
                lastReadAyah: lastReadAyah,
                totalAyahs: totalAyahs
            )
        }
    }

    private func createProgressRecord(
        surahNumber: Int,
        lastReadAyah: Int,
        totalAyahs: Int,
        progressPercentage: Double,
        ownerRecordName: String
    ) -> CKRecord {
        let recordID = CKRecord.ID(recordName: "progress-\(ownerRecordName)-\(surahNumber)")
        let record = CKRecord(recordType: "ReadingProgress", recordID: recordID)

        record["surahNumber"] = surahNumber as CKRecordValue
        record["lastReadAyah"] = lastReadAyah as CKRecordValue
        record["totalAyahs"] = totalAyahs as CKRecordValue
        record["progressPercentage"] = progressPercentage as CKRecordValue
        record["lastUpdatedAt"] = Date() as CKRecordValue
        record["ownerRecordName"] = ownerRecordName

        return record
    }

    private func updateProgressRecord(
        recordID: CKRecord.ID,
        surahNumber: Int,
        lastReadAyah: Int,
        totalAyahs: Int,
        progressPercentage: Double,
        ownerRecordName: String
    ) -> CKRecord {
        // Create a new record with the same ID to update it
        let record = CKRecord(recordType: "ReadingProgress", recordID: recordID)

        record["surahNumber"] = surahNumber as CKRecordValue
        record["lastReadAyah"] = lastReadAyah as CKRecordValue
        record["totalAyahs"] = totalAyahs as CKRecordValue
        record["progressPercentage"] = progressPercentage as CKRecordValue
        record["lastUpdatedAt"] = Date() as CKRecordValue
        record["ownerRecordName"] = ownerRecordName

        return record
    }

    // MARK: - Individual Operations

    func uploadProgress(for surah: Surah) async throws {
        let ownerRecordName = try await getUserRecordName()
        let lastReadAyah = progressStore.lastReadAyah(for: surah)
        let totalAyahs = surah.ayahCount
        let progressPercentage = Double(lastReadAyah) / Double(totalAyahs)

        let record = createProgressRecord(
            surahNumber: surah.number,
            lastReadAyah: lastReadAyah,
            totalAyahs: totalAyahs,
            progressPercentage: progressPercentage,
            ownerRecordName: ownerRecordName
        )

        try await saveRecords([record])
        print("✅ Uploaded progress for Surah \(surah.number)")
    }
}

// MARK: - Helper Types

private struct CloudProgress {
    let recordID: CKRecord.ID
    let surahNumber: Int
    let lastReadAyah: Int
    let totalAyahs: Int
}
