import AuthenticationServices
import Combine
import Foundation

@MainActor
final class CloudAuthManager: ObservableObject {
    @Published private(set) var isSignedIn: Bool
    @Published private(set) var status: String

    init(isSignedIn: Bool = false, status: String = "Chưa đăng nhập") {
        self.isSignedIn = isSignedIn
        self.status = status
    }

    func prepareAuthorizationRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if authorization.credential is ASAuthorizationAppleIDCredential {
                isSignedIn = true
                status = "Đã đăng nhập"
            } else {
                signOut()
            }
        case .failure:
            signOut()
        }
    }

    func signOut() {
        isSignedIn = false
        status = "Chưa đăng nhập"
    }
}
