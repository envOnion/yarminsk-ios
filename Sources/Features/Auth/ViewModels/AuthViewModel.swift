import Foundation
import Combine

/// View model responsible for authentication flows, input validation, and session management.
@MainActor
public final class AuthViewModel: ObservableObject {
    private let authService: AuthServiceProtocol
    private let sessionStorage: SessionStorageProtocol

    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var errorMessage: String? = nil
    @Published public var isLoading: Bool = false
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: UserProfile? = nil

    public init(
        authService: AuthServiceProtocol,
        sessionStorage: SessionStorageProtocol
    ) {
        self.authService = authService
        self.sessionStorage = sessionStorage

        if let existingUser = authService.currentUser() {
            self.currentUser = existingUser
            self.isAuthenticated = true
        } else if let savedToken = sessionStorage.getToken(), !savedToken.isEmpty {
            self.isAuthenticated = true
        }
    }

    // MARK: - Validation

    public var isEmailValid: Bool {
        ValidationRules.isValidEmail(email)
    }

    public var isPasswordValid: Bool {
        ValidationRules.isValidPassword(password)
    }

    public var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }

    public func validateEmail() -> Bool {
        ValidationRules.isValidEmail(email)
    }

    public func validatePassword() -> Bool {
        ValidationRules.isValidPassword(password)
    }

    public func validateForm() -> Bool {
        validateEmail() && validatePassword()
    }

    // MARK: - Authentication Actions

    public func signInWithEmail() async {
        errorMessage = nil

        guard validateEmail() else {
            errorMessage = "Введите корректный адрес электронной почты"
            return
        }

        guard validatePassword() else {
            errorMessage = "Пароль должен содержать не менее 6 символов"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let profile = try await authService.signInWithEmail(email: normalizedEmail, password: password)
            currentUser = profile
            sessionStorage.saveToken(profile.id)
            isAuthenticated = true
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func signUpWithEmail() async {
        errorMessage = nil

        guard validateEmail() else {
            errorMessage = "Введите корректный адрес электронной почты"
            return
        }

        guard validatePassword() else {
            errorMessage = "Пароль должен содержать не менее 6 символов"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let profile = try await authService.signUpWithEmail(email: normalizedEmail, password: password)
            currentUser = profile
            sessionStorage.saveToken(profile.id)
            isAuthenticated = true
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func signInWithApple(
        idToken: String = "mock_apple_identity_token",
        rawNonce: String = "mock_nonce",
        fullName: PersonNameComponents? = nil
    ) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await authService.signInWithApple(
                idToken: idToken,
                rawNonce: rawNonce,
                fullName: fullName
            )
            currentUser = profile
            sessionStorage.saveToken(profile.id)
            isAuthenticated = true
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func signInWithGoogle(
        idToken: String = "mock_google_id_token",
        accessToken: String = "mock_google_access_token"
    ) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await authService.signInWithGoogle(
                idToken: idToken,
                accessToken: accessToken
            )
            currentUser = profile
            sessionStorage.saveToken(profile.id)
            isAuthenticated = true
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signOut()
            sessionStorage.clearToken()
            currentUser = nil
            isAuthenticated = false
            resetForm()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func clearError() {
        errorMessage = nil
    }

    public func resetForm() {
        email = ""
        password = ""
        errorMessage = nil
    }
}
