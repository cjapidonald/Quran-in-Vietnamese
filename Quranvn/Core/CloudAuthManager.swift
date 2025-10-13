import AuthenticationServices
import CloudKit
import Combine
import Foundation

struct UserSummary {
    let appleUserIdentifier: String
    let nameComponents: PersonNameComponents?
    let email: String?
    let recordID: CKRecord.ID
}

enum SignInStatus {
    case signedOut
    case authorizing
    case signedIn(UserSummary)
    case error(String)
}

@MainActor
final class CloudAuthManager: NSObject, ObservableObject {
    @Published private(set) var status: SignInStatus = .signedOut

    var isSignedIn: Bool {
        if case .signedIn = status {
            return true
        }
        return false
    }

    var currentUser: UserSummary? {
        if case let .signedIn(user) = status {
            return user
        }
        return nil
    }

    private var currentUserIdentifier: String?

    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                status = .error("Không thể xử lý thông tin đăng nhập Apple ID.")
                return
            }

            status = .authorizing
            currentUserIdentifier = credential.user

            Task { @MainActor [weak self] in
                guard let self else { return }

                do {
                    let summary = try await self.persistUserProfile(with: credential)
                    self.status = .signedIn(summary)
                } catch {
                    self.status = .error(error.localizedDescription)
                }
            }

        case let .failure(error):
            status = .error(error.localizedDescription)
        }
    }

    func refreshCredentialState() {
        guard let userID = currentUserIdentifier else {
            status = .signedOut
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { [weak self] state, error in
            guard let self else { return }

            if let error {
                Task { @MainActor in
                    self.status = .error(error.localizedDescription)
                }
                return
            }

            Task { @MainActor in
                switch state {
                case .authorized:
                    break
                case .revoked, .notFound:
                    self.signOut()
                case .transferred:
                    self.status = .error("Thông tin đăng nhập Apple ID đã được chuyển đổi. Vui lòng đăng nhập lại.")
                @unknown default:
                    self.status = .error("Trạng thái xác thực không xác định.")
                }
            }
        }
    }

    func signOut() {
        currentUserIdentifier = nil
        status = .signedOut
    }

    private func persistUserProfile(with credential: ASAuthorizationAppleIDCredential) async throws -> UserSummary {
        let container = CKContainer(identifier: Self.containerIdentifier)
        let userRecordID = try await container.userRecordID()

        let database = container.privateCloudDatabase
        let profileRecord = try await fetchOrCreateUserProfileRecord(for: userRecordID, in: database)

        let emailToStore = credential.email ?? (profileRecord[RecordKey.email] as? String)
        let givenNameToStore = credential.fullName?.givenName ?? (profileRecord[RecordKey.givenName] as? String)
        let familyNameToStore = credential.fullName?.familyName ?? (profileRecord[RecordKey.familyName] as? String)

        profileRecord[RecordKey.appleUserID] = credential.user as CKRecordValue
        profileRecord[RecordKey.lastSignIn] = Date() as CKRecordValue
        profileRecord[RecordKey.userReference] = CKRecord.Reference(recordID: userRecordID, action: .none)

        if let emailToStore {
            profileRecord[RecordKey.email] = emailToStore as CKRecordValue
        }

        if let givenNameToStore {
            profileRecord[RecordKey.givenName] = givenNameToStore as CKRecordValue
        }

        if let familyNameToStore {
            profileRecord[RecordKey.familyName] = familyNameToStore as CKRecordValue
        }

        let (savedRecords, _) = try await database.modifyRecords(saving: [profileRecord], deleting: [])
        let savedRecord = savedRecords.first ?? profileRecord

        var nameComponents: PersonNameComponents?
        if givenNameToStore != nil || familyNameToStore != nil {
            var components = PersonNameComponents()
            components.givenName = givenNameToStore
            components.familyName = familyNameToStore
            nameComponents = components
        } else {
            nameComponents = credential.fullName
        }

        let summary = UserSummary(
            appleUserIdentifier: credential.user,
            nameComponents: nameComponents,
            email: emailToStore,
            recordID: savedRecord.recordID
        )

        return summary
    }

    private func fetchOrCreateUserProfileRecord(for userRecordID: CKRecord.ID, in database: CKDatabase) async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: userRecordID.recordName)

        do {
            let record = try await database.record(for: recordID)
            return record
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                let newRecord = CKRecord(recordType: RecordKey.userProfileType, recordID: recordID)
                newRecord[RecordKey.userReference] = CKRecord.Reference(recordID: userRecordID, action: .none)
                return newRecord
            }
            throw error
        }
    }
}

private enum RecordKey {
    static let userProfileType = "UserProfile"
    static let appleUserID = "appleUserID"
    static let email = "email"
    static let givenName = "givenName"
    static let familyName = "familyName"
    static let lastSignIn = "lastSignIn"
    static let userReference = "userRecord"
}

private extension CloudAuthManager {
    static let containerIdentifier = "iCloud.vn.quran.app"
}
