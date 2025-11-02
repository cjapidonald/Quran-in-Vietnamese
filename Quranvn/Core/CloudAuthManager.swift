import AuthenticationServices
import CloudKit
import Combine
import Foundation

@MainActor
final class CloudAuthManager: NSObject, ObservableObject {
    enum SignInStatus {
        case signedOut
        case authorizing
        case signedIn(UserSummary)
        case error(String)
    }

    struct UserSummary {
        let appleUserID: String
        let nameComponents: PersonNameComponents?
        let email: String?
        let recordID: CKRecord.ID
    }

    @Published private(set) var status: SignInStatus = .signedOut
    @Published private(set) var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine

    private static let simulatorUnsupportedMessage = "Trình mô phỏng iOS không hỗ trợ Đăng nhập với Apple. Vui lòng thử trên thiết bị thật đã đăng nhập iCloud."

    var isSignedIn: Bool {
        if case .signedIn = status {
            return true
        }
        return false
    }

    var isSignInAvailable: Bool {
#if targetEnvironment(simulator)
        return false
#else
        return iCloudAccountStatus == .available
#endif
    }

    var statusDescription: String {
        switch status {
        case .signedOut:
            if iCloudAccountStatus != .available {
                return "iCloud không khả dụng"
            }
            return "Chưa đăng nhập"
        case .authorizing:
            return "Đang xác thực…"
        case .signedIn:
            return "Đã đăng nhập"
        case let .error(message):
            return "Lỗi: \(message)"
        }
    }

    var iCloudStatusMessage: String? {
        switch iCloudAccountStatus {
        case .couldNotDetermine:
            return "Không thể xác định trạng thái iCloud. Vui lòng thử lại."
        case .restricted:
            return "iCloud bị hạn chế trên thiết bị này do Hạn chế hoặc Kiểm soát trẻ em."
        case .noAccount:
            return "Không có tài khoản iCloud. Vui lòng đăng nhập iCloud trong Cài đặt để sử dụng tính năng này."
        case .temporarilyUnavailable:
            return "iCloud tạm thời không khả dụng. Vui lòng thử lại sau."
        case .available:
            return nil
        @unknown default:
            return "Trạng thái iCloud không xác định."
        }
    }

    var currentUser: UserSummary? {
        if case let .signedIn(summary) = status {
            return summary
        }
        return nil
    }

    private let containerIdentifier = "iCloud.donald.kvietnamisht"
    private var cachedUserRecordID: CKRecord.ID?
    private var cachedAppleUserID: String?

    override init() {
        super.init()
#if targetEnvironment(simulator)
        status = .error(Self.simulatorUnsupportedMessage)
#else
        Task {
            await checkiCloudAccountStatus()
        }
#endif
    }

    func checkiCloudAccountStatus() async {
        let container = CKContainer(identifier: containerIdentifier)
        do {
            let status = try await container.accountStatus()
            print("✅ iCloud Status Check - Status: \(status.rawValue)")
            await MainActor.run { [weak self] in
                self?.iCloudAccountStatus = status
            }
        } catch {
            print("❌ iCloud Status Check Failed: \(error)")
            await MainActor.run { [weak self] in
                self?.iCloudAccountStatus = .couldNotDetermine
            }
        }
    }

    func prepareAuthorizationRequest(_ request: ASAuthorizationAppleIDRequest) {
#if targetEnvironment(simulator)
        status = .error(Self.simulatorUnsupportedMessage)
        return
#else
        guard iCloudAccountStatus == .available else {
            if let message = iCloudStatusMessage {
                status = .error(message)
            }
            return
        }
        request.requestedScopes = [.fullName, .email]
#endif
    }

    func handleAuthorization(result: Result<ASAuthorization, Error>) {
#if targetEnvironment(simulator)
        status = .error(Self.simulatorUnsupportedMessage)
        return
#else
        guard iCloudAccountStatus == .available else {
            if let message = iCloudStatusMessage {
                status = .error(message)
            }
            return
        }

        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                status = .error("Không thể xác định thông tin đăng nhập từ Apple ID.")
                return
            }

            status = .authorizing
            cachedAppleUserID = credential.user

            Task {
                let summary: UserSummary
                do {
                    summary = try await self.completeSignIn(with: credential)
                } catch {
                    let message = self.userFriendlyMessage(for: error)
                    await MainActor.run { [weak self] in
                        self?.clearCachedState()
                        self?.status = .error(message)
                    }
                    return
                }

                await MainActor.run { [weak self] in
                    self?.status = .signedIn(summary)
                }
            }

        case let .failure(error):
            if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
                status = .signedOut
            } else {
                clearCachedState()
                status = .error(userFriendlyMessage(for: error))
            }
        }
#endif
    }

    func refreshCredentialState() {
        guard let userID = cachedAppleUserID else {
            status = .signedOut
            return
        }

        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, error in
            Task {
                if let error {
                    await MainActor.run { [weak self] in
                        self?.status = .error(error.localizedDescription)
                    }
                    return
                }

                switch state {
                case .authorized:
                    break
                case .revoked, .notFound, .transferred:
                    await MainActor.run { [weak self] in
                        self?.clearCachedState()
                        self?.status = .signedOut
                    }
                @unknown default:
                    await MainActor.run { [weak self] in
                        self?.status = .error("Trạng thái xác thực không xác định.")
                    }
                }
            }
        }
    }

    func signOut() {
        clearCachedState()
        status = .signedOut
    }

    private func clearCachedState() {
        cachedAppleUserID = nil
        cachedUserRecordID = nil
    }

    private enum AccountActionError: LocalizedError {
        case notSignedIn

        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return "Bạn cần đăng nhập để thực hiện thao tác này."
            }
        }
    }

    func deleteAccount() async throws {
        guard case let .signedIn(summary) = status else {
            throw AccountActionError.notSignedIn
        }

        status = .authorizing

        do {
            let container = CKContainer(identifier: containerIdentifier)
            let database = container.privateCloudDatabase

            do {
                _ = try await database.deleteRecord(withID: summary.recordID)
            } catch let error as CKError where error.code == .unknownItem {
                // If the record is already gone, we can safely continue.
            }

            clearCachedState()
            status = .signedOut
        } catch {
            status = .signedIn(summary)
            throw error
        }
    }

    func userFriendlyMessage(for error: Error) -> String {
        if let authorizationError = error as? ASAuthorizationError {
            switch authorizationError.code {
            case .unknown:
#if targetEnvironment(simulator)
                return Self.simulatorUnsupportedMessage
#else
                return "Đăng nhập với Apple hiện không khả dụng trên thiết bị này. Vui lòng thử lại trên thiết bị khác đã đăng nhập iCloud."
#endif
            case .invalidResponse, .notHandled, .failed:
                return "Không thể hoàn tất đăng nhập với Apple. Vui lòng kiểm tra kết nối mạng và thử lại."
            case .notInteractive:
                return "Yêu cầu đăng nhập với Apple phải được kích hoạt từ giao diện đang hiển thị."
            case .canceled:
                return "Yêu cầu đăng nhập đã được hủy."
            @unknown default:
                let description = error.localizedDescription
                return description.isEmpty ? "Đã xảy ra lỗi không xác định khi đăng nhập với Apple." : description
            }
        }

        if let cloudKitError = error as? CKError {
            switch cloudKitError.code {
            case .notAuthenticated:
                return "Bạn cần đăng nhập iCloud để đồng bộ dữ liệu với Apple."
            case .networkUnavailable, .networkFailure:
                return "Kết nối mạng không ổn định nên không thể đăng nhập. Vui lòng thử lại."
            case .accountTemporarilyUnavailable:
                return "Tài khoản iCloud tạm thời không khả dụng. Vui lòng thử lại sau."
            case .permissionFailure:
                return "Không có quyền truy cập iCloud. Vui lòng kiểm tra cài đặt quyền trong Cài đặt."
            case .serverRejectedRequest, .invalidArguments:
                return "Lỗi cấu hình máy chủ. Vui lòng cập nhật phiên bản mới nhất của ứng dụng."
            case .internalError, .serverResponseLost:
                return "Lỗi máy chủ iCloud. Vui lòng thử lại sau."
            case .serviceUnavailable:
                return "Dịch vụ iCloud tạm thời không khả dụng. Vui lòng thử lại sau."
            case .quotaExceeded:
                return "Dung lượng iCloud đã đầy. Vui lòng giải phóng dung lượng."
            case .unknownItem:
                return "Không tìm thấy dữ liệu. Vui lòng thử đăng nhập lại."
            default:
                let description = error.localizedDescription
                return description.isEmpty ? "Đã xảy ra lỗi không xác định khi đăng nhập với Apple." : description
            }
        }

        let nsError = error as NSError
        if nsError.domain == "AKAuthenticationError" {
            switch nsError.code {
            case -7022:
                return "Thiết bị cần bật mật mã và đăng nhập iCloud để sử dụng Đăng nhập với Apple."
            default:
                let description = error.localizedDescription
                return description.isEmpty ? "Đã xảy ra lỗi không xác định khi đăng nhập với Apple." : description
            }
        }

        let description = error.localizedDescription
        return description.isEmpty ? "Đã xảy ra lỗi không xác định khi đăng nhập với Apple." : description
    }

    private func completeSignIn(with credential: ASAuthorizationAppleIDCredential) async throws -> UserSummary {
        let container = CKContainer(identifier: containerIdentifier)

        // Get user record ID
        let userRecordID: CKRecord.ID
        do {
            userRecordID = try await container.userRecordID()
            cachedUserRecordID = userRecordID
        } catch {
            print("❌ CloudKit Error - Failed to get userRecordID: \(error)")
            throw error
        }

        let database = container.privateCloudDatabase

        // Fetch or create profile record
        let profileRecord: CKRecord
        do {
            profileRecord = try await fetchOrCreateProfileRecord(for: userRecordID, in: database)
        } catch {
            print("❌ CloudKit Error - Failed to fetch/create profile: \(error)")
            throw error
        }

        updateProfileRecord(profileRecord, with: credential, userRecordID: userRecordID)

        // Save profile record
        do {
            _ = try await database.modifyRecords(saving: [profileRecord], deleting: [])
            print("✅ CloudKit - Profile saved successfully")
        } catch let error as CKError {
            print("❌ CloudKit Error - Failed to save profile:")
            print("   Error code: \(error.code.rawValue)")
            print("   Error: \(error.localizedDescription)")
            if let underlying = error.userInfo[NSUnderlyingErrorKey] {
                print("   Underlying: \(underlying)")
            }
            throw error
        } catch {
            print("❌ Unknown error saving profile: \(error)")
            throw error
        }

        let summary = UserSummary(
            appleUserID: credential.user,
            nameComponents: resolvedNameComponents(from: credential, record: profileRecord),
            email: credential.email ?? profileRecord["email"] as? String,
            recordID: profileRecord.recordID
        )

        cachedAppleUserID = summary.appleUserID

        return summary
    }

    private func fetchOrCreateProfileRecord(for userRecordID: CKRecord.ID, in database: CKDatabase) async throws -> CKRecord {
        let profileRecordID = CKRecord.ID(recordName: userRecordID.recordName)

        do {
            return try await database.record(for: profileRecordID)
        } catch let error as CKError {
            guard error.code == .unknownItem else { throw error }
            let newRecord = CKRecord(recordType: "UserProfile", recordID: profileRecordID)
            newRecord["userRecord"] = CKRecord.Reference(recordID: userRecordID, action: .none)
            return newRecord
        } catch {
            throw error
        }
    }

    private func updateProfileRecord(_ record: CKRecord, with credential: ASAuthorizationAppleIDCredential, userRecordID: CKRecord.ID) {
        record["appleUserID"] = credential.user
        record["userRecord"] = CKRecord.Reference(recordID: userRecordID, action: .none)
        record["lastSignIn"] = Date() as NSDate

        if let email = credential.email {
            record["email"] = email
        }

        if let givenName = credential.fullName?.givenName {
            record["givenName"] = givenName
        }

        if let familyName = credential.fullName?.familyName {
            record["familyName"] = familyName
        }
    }

    private func resolvedNameComponents(from credential: ASAuthorizationAppleIDCredential, record: CKRecord) -> PersonNameComponents? {
        if let fullName = credential.fullName {
            return fullName
        }

        var components = PersonNameComponents()
        var hasComponent = false

        if let givenName = record["givenName"] as? String {
            components.givenName = givenName
            hasComponent = true
        }

        if let familyName = record["familyName"] as? String {
            components.familyName = familyName
            hasComponent = true
        }

        return hasComponent ? components : nil
    }
}
