import Foundation
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn

/// Concrete implementation of `AuthServiceProtocol` using Firebase Authentication,
/// Apple Sign-In, and Google Sign-In.
public final class FirebaseAuthService: AuthServiceProtocol, @unchecked Sendable {

    public init() {}

    public func currentUser() -> UserProfile? {
        guard let user = Auth.auth().currentUser else { return nil }
        return mapUserToProfile(user)
    }

    public func observeAuthState() -> AsyncStream<UserProfile?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                let profile = user.flatMap { self?.mapUserToProfile($0) }
                continuation.yield(profile)
            }

            let box = ListenerBox(handle: handle)
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

        let result = try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
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

        let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
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

        let result = try await Auth.auth().signIn(with: credential)

        // Apple ID only provides fullName on the very first sign-in.
        // If provided, update Firebase user display name.
        if let fullName = fullName,
           let user = Auth.auth().currentUser,
           (user.displayName == nil || user.displayName?.isEmpty == true) {
            let formattedName = PersonNameComponentsFormatter().string(from: fullName).trimmingCharacters(in: .whitespaces)
            if !formattedName.isEmpty {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = formattedName
                try? await changeRequest.commitChanges()
                try? await user.reload()
            }
        }

        let updatedUser = Auth.auth().currentUser ?? result.user
        return mapUserToProfile(updatedUser, fallbackFullName: fullName)
    }

    public func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        let result = try await Auth.auth().signIn(with: credential)
        return mapUserToProfile(result.user)
    }

    public func updateProfile(name: String, lastName: String, phone: String) async throws -> UserProfile {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }

        let fullName = "\(name) \(lastName)".trimmingCharacters(in: .whitespaces)
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        try await user.reload()

        let updatedUser = Auth.auth().currentUser ?? user
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
        try Auth.auth().signOut()
    }

    // MARK: - Mapping

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
    private var handle: AuthStateDidChangeListenerHandle?

    init(handle: AuthStateDidChangeListenerHandle?) {
        self.handle = handle
    }

    func cleanup() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
            self.handle = nil
        }
    }
}
