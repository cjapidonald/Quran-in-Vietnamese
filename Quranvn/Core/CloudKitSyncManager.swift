import CloudKit
import Foundation
import Combine

/// Base CloudKit sync manager with common operations
@MainActor
class CloudKitSyncManager: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncError: Error?
    @Published private(set) var lastSyncDate: Date?

    let containerIdentifier = "iCloud.donald.kvietnamisht"

    private(set) lazy var container = CKContainer(identifier: containerIdentifier)
    private(set) lazy var privateDatabase = container.privateCloudDatabase

    private var userRecordID: CKRecord.ID?
    private var userRecordName: String?

    // MARK: - User Record Management

    func getUserRecordName() async throws -> String {
        if let cached = userRecordName {
            return cached
        }

        let recordID = try await container.userRecordID()
        userRecordID = recordID
        userRecordName = recordID.recordName
        return recordID.recordName
    }

    // MARK: - Account Status

    func checkAccountStatus() async -> CKAccountStatus {
        do {
            return try await container.accountStatus()
        } catch {
            print("❌ CloudKit - Failed to check account status: \(error)")
            return .couldNotDetermine
        }
    }

    func isCloudKitAvailable() async -> Bool {
        let status = await checkAccountStatus()
        return status == .available
    }

    // MARK: - Sync State Management

    func startSync() {
        isSyncing = true
        lastSyncError = nil
    }

    func endSync(error: Error? = nil) {
        isSyncing = false
        if let error = error {
            lastSyncError = error
            print("❌ CloudKit Sync Error: \(error.localizedDescription)")
        } else {
            lastSyncDate = Date()
            print("✅ CloudKit Sync Completed")
        }
    }

    // MARK: - Record Operations

    func fetchRecords<T>(
        ofType recordType: String,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor] = [],
        resultsLimit: Int = CKQueryOperation.maximumResults,
        transform: (CKRecord) throws -> T?
    ) async throws -> [T] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors

        var allResults: [T] = []
        var cursor: CKQueryOperation.Cursor?

        repeat {
            let (results, nextCursor) = try await fetchBatch(
                query: query,
                cursor: cursor,
                resultsLimit: resultsLimit,
                transform: transform
            )
            allResults.append(contentsOf: results)
            cursor = nextCursor
        } while cursor != nil

        return allResults
    }

    private func fetchBatch<T>(
        query: CKQuery,
        cursor: CKQueryOperation.Cursor?,
        resultsLimit: Int,
        transform: (CKRecord) throws -> T?
    ) async throws -> (results: [T], cursor: CKQueryOperation.Cursor?) {
        if let cursor = cursor {
            let (matchResults, queryCursor) = try await privateDatabase.records(
                continuingMatchFrom: cursor,
                desiredKeys: nil,
                resultsLimit: resultsLimit
            )
            let results = try matchResults.compactMap { try transform($0.1.get()) }
            return (results, queryCursor)
        } else {
            let (matchResults, queryCursor) = try await privateDatabase.records(
                matching: query,
                desiredKeys: nil,
                resultsLimit: resultsLimit
            )
            let results = try matchResults.compactMap { try transform($0.1.get()) }
            return (results, queryCursor)
        }
    }

    func saveRecords(_ records: [CKRecord]) async throws {
        guard !records.isEmpty else { return }

        // Split into batches of 400 (CloudKit limit)
        let batchSize = 400
        let batches = stride(from: 0, to: records.count, by: batchSize).map {
            Array(records[$0..<min($0 + batchSize, records.count)])
        }

        for batch in batches {
            let result = try await privateDatabase.modifyRecords(
                saving: batch,
                deleting: []
            )

            // Check for partial failures
            for (recordID, saveResult) in result.saveResults {
                if case .failure(let error) = saveResult {
                    print("❌ CloudKit - Failed to save record \(recordID): \(error)")
                }
            }
        }
    }

    func deleteRecords(withIDs recordIDs: [CKRecord.ID]) async throws {
        guard !recordIDs.isEmpty else { return }

        // Split into batches of 400 (CloudKit limit)
        let batchSize = 400
        let batches = stride(from: 0, to: recordIDs.count, by: batchSize).map {
            Array(recordIDs[$0..<min($0 + batchSize, recordIDs.count)])
        }

        for batch in batches {
            let result = try await privateDatabase.modifyRecords(
                saving: [],
                deleting: batch
            )

            // Check for partial failures
            for (recordID, deleteResult) in result.deleteResults {
                if case .failure(let error) = deleteResult {
                    // Ignore "unknownItem" errors (record already deleted)
                    if let ckError = error as? CKError, ckError.code == .unknownItem {
                        continue
                    }
                    print("❌ CloudKit - Failed to delete record \(recordID): \(error)")
                }
            }
        }
    }

    // MARK: - Conflict Resolution

    /// Simple last-write-wins conflict resolution
    func resolveConflict(clientRecord: CKRecord, serverRecord: CKRecord) -> CKRecord {
        // Compare modification dates
        let clientModTime = clientRecord.modificationDate ?? Date.distantPast
        let serverModTime = serverRecord.modificationDate ?? Date.distantPast

        // Return the most recently modified record
        return clientModTime > serverModTime ? clientRecord : serverRecord
    }

    // MARK: - Error Handling

    func shouldRetry(error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }

        switch ckError.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable:
            return true
        case .zoneBusy, .requestRateLimited:
            return true
        default:
            return false
        }
    }

    func retryDelay(for error: Error) -> TimeInterval {
        guard let ckError = error as? CKError else { return 5.0 }

        // Check if CloudKit suggests a retry delay
        if let retryAfter = ckError.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            return retryAfter
        }

        switch ckError.code {
        case .zoneBusy, .requestRateLimited:
            return 10.0
        case .networkUnavailable, .networkFailure:
            return 5.0
        default:
            return 5.0
        }
    }
}
