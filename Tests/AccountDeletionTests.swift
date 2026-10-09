import XCTest
@testable import YarMinsk

@MainActor
final class AccountDeletionTests: XCTestCase {
    func testSuccessfulDeletionRemovesCardBeforeAccountAndClearsLocalSession() async {
        let fixture = DeletionFixture()
        await fixture.model.deleteAccount(password: "valid-password")
        XCTAssertEqual(fixture.events.values, ["reauthenticate", "delete-card:owner", "delete-account"])
        XCTAssertTrue(fixture.model.didDeleteAccount)
        XCTAssertNil(fixture.auth.currentUser())
        XCTAssertNil(fixture.storage.getToken())
    }

    func testWrongPasswordDoesNotDeleteAnyData() async {
        let fixture = DeletionFixture()
        fixture.auth.reauthenticationError = AuthServiceError.invalidCredentials
        await fixture.model.deleteAccount(password: "wrong")
        XCTAssertEqual(fixture.events.values, ["reauthenticate"])
        XCTAssertFalse(fixture.model.didDeleteAccount)
        XCTAssertNotNil(fixture.auth.currentUser())
        XCTAssertNotNil(fixture.storage.getToken())
    }

    func testDatabaseFailureKeepsAuthenticationAccount() async {
        let fixture = DeletionFixture()
        fixture.discount.error = AuthServiceError.underlying("Permission denied")
        await fixture.model.deleteAccount(password: "valid-password")
        XCTAssertEqual(fixture.events.values, ["reauthenticate", "delete-card:owner"])
        XCTAssertFalse(fixture.model.didDeleteAccount)
        XCTAssertNotNil(fixture.auth.currentUser())
        XCTAssertEqual(fixture.model.errorMessage, "Permission denied")
    }

    func testFinalDeletionFailureIsReportedAsIncompleteAndCanBeRetried() async {
        let fixture = DeletionFixture()
        fixture.auth.deletionError = AuthServiceError.underlying("Network error")
        await fixture.model.deleteAccount(password: "valid-password")
        XCTAssertFalse(fixture.model.didDeleteAccount)
        XCTAssertTrue(fixture.model.errorMessage?.contains("не завершено") == true)
        XCTAssertNotNil(fixture.storage.getToken())
        fixture.auth.deletionError = nil
        await fixture.model.deleteAccount(password: "valid-password")
        XCTAssertTrue(fixture.model.didDeleteAccount)
        XCTAssertNil(fixture.storage.getToken())
    }

    func testAppleDeletionPassesAuthorizationCodeForRevocation() async {
        let fixture = DeletionFixture(provider: .apple)
        await fixture.model.deleteAccount(password: "")
        XCTAssertTrue(fixture.model.didDeleteAccount)
        XCTAssertEqual(fixture.auth.revocationCode, "fresh-authorization-code")
    }

    func testMissingAppleAuthorizationCodeAndCancelledGoogleDoNotDeleteData() async {
        let apple = DeletionFixture(provider: .apple)
        apple.social.authorizationCode = nil
        await apple.model.deleteAccount(password: "")
        XCTAssertTrue(apple.events.values.isEmpty)
        XCTAssertNotNil(apple.model.errorMessage)

        let google = DeletionFixture(provider: .google)
        google.social.error = AuthServiceError.cancelled
        await google.model.deleteAccount(password: "")
        XCTAssertTrue(google.events.values.isEmpty)
        XCTAssertNil(google.model.errorMessage)
        XCTAssertFalse(google.model.isDeleting)
    }

    func testChangingAccountDuringReauthenticationDoesNotDeleteEitherCard() async {
        let fixture = DeletionFixture()
        fixture.auth.changeUserDuringReauthentication = true
        await fixture.model.deleteAccount(password: "valid-password")
        XCTAssertEqual(fixture.events.values, ["reauthenticate"])
        XCTAssertFalse(fixture.model.didDeleteAccount)
    }
}

private final class DeletionEvents: @unchecked Sendable { var values: [String] = [] }

@MainActor
private final class DeletionFixture {
    let events = DeletionEvents()
    let storage = TestSessionStorage(token: "session-marker")
    let auth: DeletionAuthService
    let discount: DeletionDiscountService
    let social = DeletionSocialProvider()
    let model: AccountDeletionViewModel
    init(provider: AccountDeletionProvider = .password) {
        auth = DeletionAuthService(events: events, provider: provider)
        discount = DeletionDiscountService(events: events)
        model = AccountDeletionViewModel(authService: auth, discountService: discount,
                                         sessionStorage: storage, socialProvider: social)
    }
}

private final class DeletionAuthService: AuthServiceProtocol, @unchecked Sendable {
    var profile: UserProfile? = UserProfile(id: "owner", email: "guest@example.com")
    var reauthenticationError: Error?
    var deletionError: Error?
    var changeUserDuringReauthentication = false
    var revocationCode: String?
    let events: DeletionEvents
    let provider: AccountDeletionProvider
    init(events: DeletionEvents, provider: AccountDeletionProvider) { self.events = events; self.provider = provider }
    func currentUser() -> UserProfile? { profile }
    func accountDeletionProvider() -> AccountDeletionProvider { provider }
    func reauthenticateForDeletion(credential: AccountDeletionCredential) async throws {
        events.values.append("reauthenticate")
        if let reauthenticationError { throw reauthenticationError }
        if changeUserDuringReauthentication { profile = UserProfile(id: "another-user") }
    }
    func deleteAccount(appleAuthorizationCode: String?) async throws {
        events.values.append("delete-account")
        if let deletionError { throw deletionError }
        revocationCode = appleAuthorizationCode
        profile = nil
    }
    func observeAuthState() -> AsyncStream<UserProfile?> { AsyncStream { $0.yield(profile) } }
    func signInWithEmail(email: String, password: String) async throws -> UserProfile { throw AuthServiceError.cancelled }
    func signUpWithEmail(email: String, password: String) async throws -> UserProfile { throw AuthServiceError.cancelled }
    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> UserProfile { throw AuthServiceError.cancelled }
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile { throw AuthServiceError.cancelled }
    func updateProfile(name: String, lastName: String, phone: String) async throws -> UserProfile { throw AuthServiceError.cancelled }
    func signOut() async throws { profile = nil }
}

private final class DeletionDiscountService: DiscountServiceProtocol, @unchecked Sendable {
    var error: Error?
    let events: DeletionEvents
    init(events: DeletionEvents) { self.events = events }
    func getDiscount(userId: String) async throws -> DiscountCard? { nil }
    func createDiscount(_ card: DiscountCard) async throws {}
    func deleteDiscount(userId: String) async throws {
        events.values.append("delete-card:\(userId)")
        if let error { throw error }
    }
}

@MainActor
private final class DeletionSocialProvider: SocialSignInProviding {
    var error: Error?
    var authorizationCode: String? = "fresh-authorization-code"
    func signInWithApple() async throws -> AppleSignInTokens {
        if let error { throw error }
        return AppleSignInTokens(idToken: "fresh-id-token", rawNonce: "nonce", fullName: nil, authorizationCode: authorizationCode)
    }
    func signInWithGoogle() async throws -> GoogleSignInTokens {
        if let error { throw error }
        return GoogleSignInTokens(idToken: "fresh-id-token", accessToken: "fresh-access-token")
    }
}
