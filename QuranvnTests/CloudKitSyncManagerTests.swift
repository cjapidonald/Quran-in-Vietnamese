import XCTest
import CloudKit
@testable import Quranvn

/// Tests for CloudKitSyncManager retry logic and error handling
@MainActor
final class CloudKitSyncManagerTests: XCTestCase {

    // MARK: - shouldRetry Tests

    func testShouldRetry_networkUnavailable_returnsTrue() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.networkUnavailable)

        XCTAssertTrue(sut.shouldRetry(error: error))
    }

    func testShouldRetry_networkFailure_returnsTrue() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.networkFailure)

        XCTAssertTrue(sut.shouldRetry(error: error))
    }

    func testShouldRetry_serviceUnavailable_returnsTrue() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.serviceUnavailable)

        XCTAssertTrue(sut.shouldRetry(error: error))
    }

    func testShouldRetry_zoneBusy_returnsTrue() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.zoneBusy)

        XCTAssertTrue(sut.shouldRetry(error: error))
    }

    func testShouldRetry_requestRateLimited_returnsTrue() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.requestRateLimited)

        XCTAssertTrue(sut.shouldRetry(error: error))
    }

    func testShouldRetry_unknownItem_returnsFalse() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.unknownItem)

        XCTAssertFalse(sut.shouldRetry(error: error))
    }

    func testShouldRetry_permissionFailure_returnsFalse() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.permissionFailure)

        XCTAssertFalse(sut.shouldRetry(error: error))
    }

    func testShouldRetry_nonCKError_returnsFalse() {
        let sut = TestableCloudKitSyncManager()
        let error = NSError(domain: "TestDomain", code: 1)

        XCTAssertFalse(sut.shouldRetry(error: error))
    }

    // MARK: - retryDelay Tests

    func testRetryDelay_zoneBusy_returns10() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.zoneBusy)

        XCTAssertEqual(sut.retryDelay(for: error), 10.0)
    }

    func testRetryDelay_requestRateLimited_returns10() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.requestRateLimited)

        XCTAssertEqual(sut.retryDelay(for: error), 10.0)
    }

    func testRetryDelay_networkUnavailable_returns5() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.networkUnavailable)

        XCTAssertEqual(sut.retryDelay(for: error), 5.0)
    }

    func testRetryDelay_nonCKError_returns5() {
        let sut = TestableCloudKitSyncManager()
        let error = NSError(domain: "TestDomain", code: 1)

        XCTAssertEqual(sut.retryDelay(for: error), 5.0)
    }

    func testRetryDelay_respectsCloudKitSuggestedDelay() {
        let sut = TestableCloudKitSyncManager()
        let suggestedDelay: TimeInterval = 30.0
        let error = CKError(
            .requestRateLimited,
            userInfo: [CKErrorRetryAfterKey: suggestedDelay]
        )

        XCTAssertEqual(sut.retryDelay(for: error), suggestedDelay)
    }

    // MARK: - Sync State Tests

    func testStartSync_setsIsSyncing() {
        let sut = TestableCloudKitSyncManager()

        sut.startSync()

        XCTAssertTrue(sut.isSyncing)
    }

    func testStartSync_clearsLastError() {
        let sut = TestableCloudKitSyncManager()
        sut.endSync(error: CKError(.networkFailure))

        sut.startSync()

        XCTAssertNil(sut.lastSyncError)
    }

    func testEndSync_clearsIsSyncing() {
        let sut = TestableCloudKitSyncManager()
        sut.startSync()

        sut.endSync()

        XCTAssertFalse(sut.isSyncing)
    }

    func testEndSync_setsLastSyncDate() {
        let sut = TestableCloudKitSyncManager()
        let beforeSync = Date()

        sut.endSync()

        XCTAssertNotNil(sut.lastSyncDate)
        XCTAssertGreaterThanOrEqual(sut.lastSyncDate!, beforeSync)
    }

    func testEndSync_withError_setsLastError() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.networkFailure)

        sut.endSync(error: error)

        XCTAssertNotNil(sut.lastSyncError)
    }

    func testEndSync_withError_doesNotSetSyncDate() {
        let sut = TestableCloudKitSyncManager()
        let error = CKError(.networkFailure)

        sut.endSync(error: error)

        XCTAssertNil(sut.lastSyncDate)
    }
}

// MARK: - Test Helpers

/// Testable subclass that exposes internal methods for testing
private class TestableCloudKitSyncManager: CloudKitSyncManager {
    override init() {
        super.init()
    }
}

// MARK: - CKError Extension for Testing

private extension CKError {
    init(_ code: CKError.Code, userInfo: [String: Any] = [:]) {
        self.init(_nsError: NSError(
            domain: CKErrorDomain,
            code: code.rawValue,
            userInfo: userInfo
        ))
    }
}
