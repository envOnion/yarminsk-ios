import Foundation
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import OSLog

/// Concrete implementation of `AuthServiceProtocol` using Firebase Authentication,
/// Apple Sign-In, and Google Sign-In.
public final class FirebaseAuthService: AuthServiceProtocol, @unchecked Sendable {
    private let auth: Auth

    public init(auth: Auth? = nil) {
        self.auth = auth ?? Auth.auth()
    }

    public func currentUser() -> UserProfile? {
        guard let user = auth.currentUser else { return nil }
        return mapUserToProfile(user)
    }

    public func observeAuthState() -> AsyncStream<UserProfile?> {
        AsyncStream { continuation in
            let handle = auth.addStateDidChangeListener { [weak self] _, user in
                let profile = user.flatMap { self?.mapUserToProfile($0) }
                continuation.yield(profile)
            }

            let box = ListenerBox(auth: auth, handle: handle)
            continuation.onTermination = { @Sendable _ in
                box.cleanup()
            }
        }
    }

    public func signInWithEmail(email: String, password: String) async throws -> UserProfile {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }

        let result = try await performAuthentication {
            try await auth.signIn(withEmail: trimmedEmail, password: password)
        }
        return mapUserToProfile(result.user)
    }

    public func signUpWithEmail(email: String, password: String) async throws -> UserProfile {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }

        guard password.count >= 6 else {
            throw AuthServiceError.invalidInput("Пароль должен содержать не менее 6 символов")
        }

        let result = try await performAuthentication {
            try await auth.createUser(withEmail: trimmedEmail, password: password)
        }
        return mapUserToProfile(result.user)
    }

    public func signInWithApple(
        idToken: String,
        rawNonce: String,
        fullName: PersonNameComponents?
    ) async throws -> UserProfile {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName
        )

        let result = try await performAuthentication {
            try await auth.signIn(with: credential)
        }

        // Apple ID only provides fullName on the very first sign-in.
        // If provided, update Firebase user display name.
        if let fullName = fullName,
           let user = auth.currentUser,
           (user.displayName == nil || user.displayName?.isEmpty == true) {
            let formattedName = PersonNameComponentsFormatter().string(from: fullName).trimmingCharacters(in: .whitespaces)
            if !formattedName.isEmpty {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = formattedName
                try? await changeRequest.commitChanges()
                try? await user.reload()
            }
        }

        let updatedUser = auth.currentUser ?? result.user
        return mapUserToProfile(updatedUser, fallbackFullName: fullName)
    }

    public func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        let result = try await performAuthentication {
            try await auth.signIn(with: credential)
        }
        return mapUserToProfile(result.user)
    }

    public func updateProfile(name: String, lastName: String, phone: String) async throws -> UserProfile {
        guard let user = auth.currentUser else {
            throw AuthServiceError.notAuthenticated
        }

        let fullName = "\(name) \(lastName)".trimmingCharacters(in: .whitespaces)
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        try await user.reload()

        let updatedUser = auth.currentUser ?? user
        var profile = mapUserToProfile(updatedUser)
        if !name.isEmpty {
            profile.name = name
        }
        if !lastName.isEmpty {
            profile.lastName = lastName
        }
        if !phone.isEmpty {
            profile.phone = phone
        }
        return profile
    }

    public func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
        try auth.signOut()
    }

    public func accountDeletionProvider() -> AccountDeletionProvider {
        let providers = auth.currentUser?.providerData.map(\.providerID) ?? []
        // Linked Apple accounts also need their Apple authorization revoked.
        if providers.contains("apple.com") { return .apple }
        if providers.contains("password") { return .password }
        return .google
    }

    public func reauthenticateForDeletion(credential: AccountDeletionCredential) async throws {
        guard let user = auth.currentUser else { throw AuthServiceError.notAuthenticated }
        let firebaseCredential: AuthCredential
        switch credential {
        case .password(let password):
            guard let email = user.email, !password.isEmpty else {
                throw AuthServiceError.invalidInput("Введите пароль для подтверждения удаления")
            }
            firebaseCredential = EmailAuthProvider.credential(withEmail: email, password: password)
        case .apple(let idToken, let rawNonce):
            firebaseCredential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: rawNonce, fullName: nil)
        case .google(let idToken, let accessToken):
            firebaseCredential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        }
        do {
            _ = try await user.reauthenticate(with: firebaseCredential)
        } catch {
            throw Self.localizedAuthError(error)
        }
    }

    public func deleteAccount(appleAuthorizationCode: String?) async throws {
        guard let user = auth.currentUser else { throw AuthServiceError.notAuthenticated }
        do {
            if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
                guard let code = appleAuthorizationCode, !code.isEmpty else {
                    throw AuthServiceError.invalidInput("Подтвердите удаление через Apple ещё раз")
                }
                try await auth.revokeToken(withAuthorizationCode: code)
            }
            try await user.delete()
            await MainActor.run { GIDSignIn.sharedInstance.signOut() }
        } catch {
            throw Self.localizedAuthError(error)
        }
    }

    // MARK: - Mapping

    private func performAuthentication(_ action: () async throws -> AuthDataResult) async throws -> AuthDataResult {
        do {
            return try await action()
        } catch {
            let nsError = error as NSError
            Logger(subsystem: "by.yarminsk.app", category: "Authentication")
                .error("Authentication failed: domain=\(nsError.domain, privacy: .public) code=\(nsError.code)")
            throw Self.localizedAuthError(error)
        }
    }

    static func localizedAuthError(_ error: Error) -> Error {
        let nsError = error as NSError
        guard nsError.domain == AuthErrors.domain,
              let code = AuthErrorCode(rawValue: nsError.code) else { return error }
        switch code {
        case .invalidCredential, .wrongPassword, .userNotFound:
            return AuthServiceError.invalidCredentials
        case .invalidEmail, .missingEmail:
            return AuthServiceError.invalidInput("Введите корректный адрес электронной почты")
        case .emailAlreadyInUse:
            return AuthServiceError.userAlreadyExists
        case .weakPassword:
            return AuthServiceError.invalidInput("Пароль не соответствует требованиям безопасности. Используйте более длинный пароль")
        case .networkError, .webNetworkRequestFailed:
            return AuthServiceError.underlying("Не удалось связаться с сервером. Проверьте подключение к интернету")
        case .tooManyRequests:
            return AuthServiceError.underlying("Слишком много попыток входа. Попробуйте позже")
        case .userDisabled:
            return AuthServiceError.underlying("Аккаунт заблокирован. Обратитесь в поддержку")
        case .operationNotAllowed:
            return AuthServiceError.underlying("Этот способ входа пока недоступен. Используйте другой способ")
        case .accountExistsWithDifferentCredential:
            return AuthServiceError.underlying("Аккаунт с этой почтой уже существует. Используйте способ входа, выбранный при регистрации")
        case .webContextCancelled:
            return AuthServiceError.cancelled
        case .invalidUserToken, .userTokenExpired:
            return AuthServiceError.underlying("Сессия истекла. Войдите заново")
        case .requiresRecentLogin:
            return AuthServiceError.underlying("Для удаления аккаунта подтвердите вход ещё раз")
        case .userMismatch:
            return AuthServiceError.underlying("Выберите тот же аккаунт, с которым вошли в приложение")
        case .keychainError:
            return AuthServiceError.underlying("Не удалось сохранить сессию на устройстве. Обновите приложение и попробуйте ещё раз")
        default:
            return AuthServiceError.underlying("Не удалось выполнить вход. Попробуйте ещё раз")
        }
    }

    public func mapUserToProfile(_ user: User, fallbackFullName: PersonNameComponents? = nil) -> UserProfile {
        var name = ""
        var lastName = ""

        if let displayName = user.displayName, !displayName.isEmpty {
            let parts = displayName.components(separatedBy: " ")
            name = parts.first ?? ""
            lastName = parts.count > 1 ? parts.dropFirst().joined(separator: " ") : ""
        } else if let fallback = fallbackFullName {
            name = fallback.givenName ?? ""
            lastName = fallback.familyName ?? ""
        }

        return UserProfile(
            id: user.uid,
            name: name,
            lastName: lastName,
            email: user.email ?? "",
            phone: user.phoneNumber ?? "",
            photoUrl: user.photoURL
        )
    }
}

// MARK: - ListenerBox Helper

private final class ListenerBox: @unchecked Sendable {
    private let auth: Auth
    private var handle: AuthStateDidChangeListenerHandle?

    init(auth: Auth, handle: AuthStateDidChangeListenerHandle?) {
        self.auth = auth
        self.handle = handle
    }

    func cleanup() {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
            self.handle = nil
        }
    }
}
