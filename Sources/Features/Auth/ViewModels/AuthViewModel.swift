import Foundation
import Combine

/// Coordinates provider sign-in and keeps UI state in sync with the authenticated Firebase user.
@MainActor
public final class AuthViewModel: ObservableObject {
    private let authService: AuthServiceProtocol
    private let sessionStorage: SessionStorageProtocol
    private let socialSignInProvider: SocialSignInProviding

    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var errorMessage: String? = nil
    @Published public var isLoading: Bool = false
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var currentUser: UserProfile? = nil

    public init(
        authService: AuthServiceProtocol,
        sessionStorage: SessionStorageProtocol,
        socialSignInProvider: SocialSignInProviding? = nil
    ) {
        self.authService = authService
        self.sessionStorage = sessionStorage
        self.socialSignInProvider = socialSignInProvider ?? SocialSignInProvider()
        updateAuthState(authService.currentUser())
    }

    public var isEmailValid: Bool { ValidationRules.isValidEmail(email) }
    public var isPasswordValid: Bool { ValidationRules.isValidPassword(password) }
    public var isFormValid: Bool { isEmailValid && isPasswordValid }
    public var isSignInFormValid: Bool { isEmailValid && !password.isEmpty }

    public func validateEmail() -> Bool { isEmailValid }
    public func validatePassword() -> Bool { isPasswordValid }
    public func validateForm() -> Bool { isFormValid }

    public func updateAuthState(_ profile: UserProfile?) {
        currentUser = profile
        isAuthenticated = profile != nil
        // Remove the old UID marker; Firebase persists and validates the actual credentials.
        sessionStorage.clearToken()
        if profile == nil { password = "" }
    }

    @discardableResult
    public func signInWithEmail() async -> Bool {
        guard !isLoading else { return false }
        errorMessage = nil
        guard isEmailValid else {
            errorMessage = "Введите корректный адрес электронной почты"
            return false
        }
        guard !password.isEmpty else {
            errorMessage = "Введите пароль"
            return false
        }
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let enteredPassword = password
        return await authenticate {
            try await self.authService.signInWithEmail(email: normalizedEmail, password: enteredPassword)
        }
    }

    @discardableResult
    public func signUpWithEmail() async -> Bool {
        guard !isLoading else { return false }
        errorMessage = nil
        guard isEmailValid else {
            errorMessage = "Введите корректный адрес электронной почты"
            return false
        }
        guard isPasswordValid else {
            errorMessage = "Пароль должен содержать не менее 6 символов"
            return false
        }
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let enteredPassword = password
        return await authenticate {
            try await self.authService.signUpWithEmail(email: normalizedEmail, password: enteredPassword)
        }
    }

    @discardableResult
    public func signInWithApple() async -> Bool {
        await authenticate {
            let tokens = try await self.socialSignInProvider.signInWithApple()
            return try await self.authService.signInWithApple(
                idToken: tokens.idToken,
                rawNonce: tokens.rawNonce,
                fullName: tokens.fullName
            )
        }
    }

    @discardableResult
    public func signInWithGoogle() async -> Bool {
        await authenticate {
            let tokens = try await self.socialSignInProvider.signInWithGoogle()
            return try await self.authService.signInWithGoogle(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken
            )
        }
    }

    public func signOut() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signOut()
            updateAuthState(nil)
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func clearError() { errorMessage = nil }

    public func resetForm() {
        email = ""
        password = ""
        errorMessage = nil
    }

    private func authenticate(_ action: () async throws -> UserProfile) async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let profile = try await action()
            updateAuthState(profile)
            password = ""
            return true
        } catch AuthServiceError.cancelled {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
