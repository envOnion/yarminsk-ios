import Foundation

public protocol AuthServiceProtocol: Sendable {
    func currentUser() -> UserProfile?
    func observeAuthState() -> AsyncStream<UserProfile?>
    func signInWithEmail(email: String, password: String) async throws -> UserProfile
    func signUpWithEmail(email: String, password: String) async throws -> UserProfile
    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> UserProfile
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile
    func updateProfile(name: String, lastName: String, phone: String) async throws -> UserProfile
    func signOut() async throws
}

public protocol DiscountServiceProtocol: Sendable {
    func getDiscount(userId: String) async throws -> DiscountCard?
    func createDiscount(_ card: DiscountCard) async throws
}

public protocol SessionStorageProtocol: Sendable {
    func saveToken(_ token: String)
    func getToken() -> String?
    func clearToken()
}
