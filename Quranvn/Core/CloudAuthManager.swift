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

    var isSignedIn: Bool {
        if case .signedIn = status {
            return true
        }
        return false
    }

    var statusDescription: String {
        switch status {
        case .signedOut:
            return "Chưa đăng nhập"
        case .authorizing:
            return "Đang xác thực…"
        case .signedIn:
            return "Đã đăng nhập"
        case let .error(message):
            return "Lỗi: \(message)"
        }
    }

    var currentUser: UserSummary? {
        if case let .signedIn(summary) = status {
            return summary
        }
        return nil
    }

    private let containerIdentifier = "iCloud.com.donald.quranvn"
    private var cachedUserRecordID: CKRecord.ID?
    private var cachedAppleUserID: String?

    func prepareAuthorizationRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAuthorization(result: Result<ASAuthorization, Error>) {
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

    private func userFriendlyMessage(for error: Error) -> String {
        if let authorizationError = error as? ASAuthorizationError {
            switch authorizationError.code {
            case .unknown:
                return "Đăng nhập với Apple hiện không khả dụng trên thiết bị này. Vui lòng thử lại trên thiết bị khác đã đăng nhập iCloud."
            case .invalidResponse, .notHandled, .failed:
                return "Không thể hoàn tất đăng nhập với Apple. Vui lòng kiểm tra kết nối mạng và thử lại."
            case .notInteractive:
                return "Yêu cầu đăng nhập với Apple phải được kích hoạt từ giao diện đang hiển thị."
            case .canceled:
                return "Yêu cầu đăng nhập đã được hủy."
            @unknown default:
                break
            }
        }

        if let cloudKitError = error as? CKError {
            switch cloudKitError.code {
            case .notAuthenticated:
                return "Bạn cần đăng nhập iCloud để đồng bộ dữ liệu với Apple."
            case .networkUnavailable, .networkFailure:
                return "Kết nối mạng không ổn định nên không thể đăng nhập. Vui lòng thử lại."
            default:
                break
            }
        }

        let nsError = error as NSError
        if nsError.domain == "AKAuthenticationError" {
            switch nsError.code {
            case -7022:
                return "Thiết bị cần bật mật mã và đăng nhập iCloud để sử dụng Đăng nhập với Apple."
            default:
                break
            }
        }

        let description = error.localizedDescription
        return description.isEmpty ? "Đã xảy ra lỗi không xác định khi đăng nhập với Apple." : description
    }

    private func completeSignIn(with credential: ASAuthorizationAppleIDCredential) async throws -> UserSummary {
        let container = CKContainer(identifier: containerIdentifier)
        let userRecordID = try await container.userRecordID()
        cachedUserRecordID = userRecordID

        let database = container.privateCloudDatabase
        let profileRecord = try await fetchOrCreateProfileRecord(for: userRecordID, in: database)
        updateProfileRecord(profileRecord, with: credential, userRecordID: userRecordID)

        _ = try await database.modifyRecords(saving: [profileRecord], deleting: [])

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
