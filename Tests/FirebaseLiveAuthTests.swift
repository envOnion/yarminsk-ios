import XCTest
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
@testable import YarMinsk

@MainActor
final class FirebaseLiveAuthTests: XCTestCase {
    /// Opt-in only: creates one temporary account and card, then deletes both through the app flow.
    func testEmailRegistrationSignInAndSessionRestoration() async throws {
        guard ProcessInfo.processInfo.environment["YAR_FIREBASE_LIVE_TEST"] == "1" else {
            throw XCTSkip("Run the YarMinskLiveAuth scheme to check the configured Firebase project")
        }
        let keychain = KeychainSessionStorage(service: "by.yarminsk.app.auth-test.\(UUID().uuidString)")
        keychain.saveToken("keychain-check")
        defer { keychain.clearToken() }
        guard keychain.getToken() == "keychain-check" else {
            XCTFail("Keychain is unavailable: run a signed build before making any Firebase writes")
            return
        }
        let options = try XCTUnwrap(FirebaseApp.app()?.options)
        let appName = "auth-check-\(UUID().uuidString)"
        FirebaseApp.configure(name: appName, options: options)
        let app = try XCTUnwrap(FirebaseApp.app(name: appName))
        let auth = Auth.auth(app: app)
        let service = FirebaseAuthService(auth: auth)
        let email = "ios-auth-check-\(UUID().uuidString.lowercased())@example.com"
        let password = UUID().uuidString + "aA1!"
        let model = AuthViewModel(authService: service, sessionStorage: TestSessionStorage())
        model.email = email
        model.password = password
        let registered = await model.signUpWithEmail()
        XCTAssertTrue(registered, model.errorMessage ?? "Registration failed")
        let temporaryUser = try XCTUnwrap(auth.currentUser)
        let root = Database.database(app: app).reference()
        addTeardownBlock {
            // Only the account created above is removed; existing Firebase users are untouched.
            if auth.currentUser?.uid == temporaryUser.uid {
                try? await root.child("discount").child(temporaryUser.uid).removeValue()
                try await auth.currentUser?.delete()
            }
            try? auth.signOut()
            _ = await app.delete()
        }
        XCTAssertEqual(model.currentUser?.id, temporaryUser.uid)
        XCTAssertTrue(model.isAuthenticated)

        let snapshot = try await Database.database(app: app).reference().child("discount").child(temporaryUser.uid).getData()
        XCTAssertFalse(snapshot.exists(), "A new account must start without a loyalty card")

        await model.signOut()
        XCTAssertNil(auth.currentUser)
        XCTAssertFalse(model.isAuthenticated)
        model.email = email
        model.password = password
        let signedIn = await model.signInWithEmail()
        XCTAssertTrue(signedIn, model.errorMessage ?? "Sign-in failed")
        XCTAssertEqual(model.currentUser?.id, temporaryUser.uid)

        let restored = AuthViewModel(authService: FirebaseAuthService(auth: auth), sessionStorage: TestSessionStorage(token: "stale-uid"))
        XCTAssertTrue(restored.isAuthenticated)
        XCTAssertEqual(restored.currentUser?.id, temporaryUser.uid)
        let observer = service.observeAuthState()
        var iterator = observer.makeAsyncIterator()
        let nextProfile = await iterator.next()
        let observedProfile = try XCTUnwrap(nextProfile)
        XCTAssertEqual(observedProfile?.id, temporaryUser.uid)

        await model.signOut()
        model.email = email
        model.password = password + "-wrong"
        let wrongPasswordSucceeded = await model.signInWithEmail()
        XCTAssertFalse(wrongPasswordSucceeded)
        XCTAssertFalse(model.isAuthenticated)
        XCTAssertEqual(model.errorMessage, "Неверный email или пароль")

        // Refresh the temporary user's credentials before teardown removes it.
        model.password = password
        let signedInAgain = await model.signInWithEmail()
        XCTAssertTrue(signedInAgain, model.errorMessage ?? "Final sign-in failed")

        let discount = ConfirmedDeletionDiscountService(service: FirebaseDiscountService(databaseRef: root))
        let card = DiscountCard(id: UUID().uuidString, userId: temporaryUser.uid,
                                cardHolder: "APP STORE QA", qrData: "QA ONLY", phone: "")
        try await discount.createDiscount(card)
        let savedCard = try await discount.getDiscount(userId: temporaryUser.uid)
        XCTAssertEqual(savedCard, card, "The isolated QA card must be acknowledged by Firebase")
        let storage = TestSessionStorage(token: temporaryUser.uid)
        let deletion = AccountDeletionViewModel(authService: service, discountService: discount,
                                               sessionStorage: storage)
        await deletion.deleteAccount(password: password)
        XCTAssertTrue(deletion.didDeleteAccount, deletion.errorMessage ?? "Deletion failed")
        XCTAssertTrue(discount.confirmedCardAbsent, "Read back the missing card before deleting Auth")
        XCTAssertNil(auth.currentUser)
        XCTAssertNil(storage.getToken())
        do {
            _ = try await service.signInWithEmail(email: email, password: password)
            XCTFail("A deleted Firebase Authentication account must not be able to sign in")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Неверный email или пароль")
        }
    }
}

private final class ConfirmedDeletionDiscountService: DiscountServiceProtocol, @unchecked Sendable {
    let service: FirebaseDiscountService
    private(set) var confirmedCardAbsent = false
    init(service: FirebaseDiscountService) { self.service = service }
    func getDiscount(userId: String) async throws -> DiscountCard? { try await service.getDiscount(userId: userId) }
    func createDiscount(_ card: DiscountCard) async throws { try await service.createDiscount(card) }
    func deleteDiscount(userId: String) async throws {
        try await service.deleteDiscount(userId: userId)
        confirmedCardAbsent = try await service.getDiscount(userId: userId) == nil
    }
}
