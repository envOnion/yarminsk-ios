import XCTest
import FirebaseAuth
@testable import YarMinsk

@MainActor
final class AuthViewModelTests: XCTestCase {
    func testSavedUIDDoesNotRestoreAuthentication() {
        let storage = TestSessionStorage(token: "stale-uid")
        let model = AuthViewModel(authService: MockAuthService(), sessionStorage: storage)
        XCTAssertFalse(model.isAuthenticated)
        XCTAssertNil(model.currentUser)
        XCTAssertNil(storage.getToken())
    }

    func testSignUpAndAuthStateChangesKeepSessionConsistent() async {
        let service = MockAuthService(simulatedDelayNanoseconds: 0)
        let storage = TestSessionStorage()
        let model = AuthViewModel(authService: service, sessionStorage: storage)
        model.email = " guest@example.com "
        model.password = "test-pass-123"
        let succeeded = await model.signUpWithEmail()
        XCTAssertTrue(succeeded)
        XCTAssertEqual(model.currentUser?.email, "guest@example.com")
        XCTAssertTrue(model.isAuthenticated)
        XCTAssertTrue(model.password.isEmpty)
        model.updateAuthState(nil)
        XCTAssertFalse(model.isAuthenticated)
        XCTAssertNil(model.currentUser)
        XCTAssertNil(storage.getToken())
    }

    func testShortExistingPasswordCanBeSubmittedForSignIn() async {
        let service = RecordingAuthService()
        let model = AuthViewModel(authService: service, sessionStorage: TestSessionStorage())
        model.email = "guest@example.com"
        model.password = "short"
        XCTAssertTrue(model.isSignInFormValid)
        XCTAssertFalse(model.isFormValid)
        let succeeded = await model.signInWithEmail()
        XCTAssertTrue(succeeded)
        XCTAssertEqual(service.lastPassword, "short")
    }

    func testSocialSignInExchangesTokensReturnedByProvider() async {
        let service = RecordingAuthService()
        let provider = TestSocialSignInProvider()
        let model = AuthViewModel(authService: service, sessionStorage: TestSessionStorage(), socialSignInProvider: provider)
        let googleSucceeded = await model.signInWithGoogle()
        XCTAssertTrue(googleSucceeded)
        XCTAssertEqual(service.googleIDToken, "provider-google-id")
        XCTAssertEqual(service.googleAccessToken, "provider-google-access")
        model.updateAuthState(nil)
        let appleSucceeded = await model.signInWithApple()
        XCTAssertTrue(appleSucceeded)
        XCTAssertEqual(service.appleIDToken, "provider-apple-id")
        XCTAssertEqual(service.appleNonce, "provider-nonce")
    }

    func testCancelledSocialSignInDoesNotAuthenticateOrDisplayError() async {
        let service = RecordingAuthService()
        let provider = TestSocialSignInProvider()
        provider.error = AuthServiceError.cancelled
        let model = AuthViewModel(authService: service, sessionStorage: TestSessionStorage(), socialSignInProvider: provider)
        let succeeded = await model.signInWithGoogle()
        XCTAssertFalse(succeeded)
        XCTAssertFalse(model.isLoading)
        XCTAssertFalse(model.isAuthenticated)
        XCTAssertNil(model.errorMessage)
        XCTAssertNil(service.googleIDToken)
    }

    func testFailedSignInDoesNotReportSuccessWithAnExistingSession() async {
        let service = RecordingAuthService()
        service.profile = UserProfile(id: "existing", name: "", lastName: "", email: "guest@example.com", phone: "")
        service.error = AuthServiceError.invalidCredentials
        let model = AuthViewModel(authService: service, sessionStorage: TestSessionStorage())
        model.email = "guest@example.com"
        model.password = "wrong-password"
        let succeeded = await model.signInWithEmail()
        XCTAssertFalse(succeeded)
        XCTAssertEqual(model.errorMessage, "Неверный email или пароль")
        XCTAssertFalse(model.isLoading)
    }

    func testAppleNonceIsRandomAndHasCorrectSHA256Challenge() throws {
        let first = try SocialSignInProvider.randomNonce()
        let second = try SocialSignInProvider.randomNonce()
        XCTAssertEqual(first.count, 32)
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(SocialSignInProvider.sha256("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testFirebaseErrorsHaveActionableRussianMessages() {
        let wrongPassword = NSError(domain: AuthErrors.domain, code: AuthErrorCode.wrongPassword.rawValue)
        let error = FirebaseAuthService.localizedAuthError(wrongPassword)
        XCTAssertEqual(error.localizedDescription, "Неверный email или пароль")
        let network = NSError(domain: AuthErrors.domain, code: AuthErrorCode.networkError.rawValue)
        XCTAssertTrue(FirebaseAuthService.localizedAuthError(network).localizedDescription.contains("интернет"))
    }
}

final class TestSessionStorage: SessionStorageProtocol, @unchecked Sendable {
    private var token: String?
    init(token: String? = nil) { self.token = token }
    func saveToken(_ token: String) { self.token = token }
    func getToken() -> String? { token }
    func clearToken() { token = nil }
}

@MainActor
private final class TestSocialSignInProvider: SocialSignInProviding {
    var error: Error?
    func signInWithGoogle() async throws -> GoogleSignInTokens {
        if let error { throw error }
        return GoogleSignInTokens(idToken: "provider-google-id", accessToken: "provider-google-access")
    }
    func signInWithApple() async throws -> AppleSignInTokens {
        if let error { throw error }
        return AppleSignInTokens(idToken: "provider-apple-id", rawNonce: "provider-nonce", fullName: nil)
    }
}

private final class RecordingAuthService: AuthServiceProtocol, @unchecked Sendable {
    var profile: UserProfile?
    var error: Error?
    var lastPassword: String?
    var googleIDToken: String?
    var googleAccessToken: String?
    var appleIDToken: String?
    var appleNonce: String?
    func currentUser() -> UserProfile? { profile }
    func observeAuthState() -> AsyncStream<UserProfile?> { AsyncStream { $0.yield(profile) } }
    func signInWithEmail(email: String, password: String) async throws -> UserProfile {
        lastPassword = password
        return try result(email: email)
    }
    func signUpWithEmail(email: String, password: String) async throws -> UserProfile { try result(email: email) }
    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> UserProfile {
        appleIDToken = idToken
        appleNonce = rawNonce
        return try result(email: "apple@example.com")
    }
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile {
        googleIDToken = idToken
        googleAccessToken = accessToken
        return try result(email: "google@example.com")
    }
    func updateProfile(name: String, lastName: String, phone: String) async throws -> UserProfile { try result(email: "guest@example.com") }
    func signOut() async throws { if let error { throw error }; profile = nil }
    func accountDeletionProvider() -> AccountDeletionProvider { .password }
    func reauthenticateForDeletion(credential: AccountDeletionCredential) async throws { if let error { throw error } }
    func deleteAccount(appleAuthorizationCode: String?) async throws { if let error { throw error }; profile = nil }
    private func result(email: String) throws -> UserProfile {
        if let error { throw error }
        let user = UserProfile(id: "test-user", name: "", lastName: "", email: email, phone: "")
        profile = user
        return user
    }
}
