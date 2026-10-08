import Foundation

/// In-memory mock implementation of `AuthServiceProtocol` for testing, previews, and offline operation.
public final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var currentProfile: UserProfile?
    private var continuations: [UUID: AsyncStream<UserProfile?>.Continuation] = [:]

    public var simulatedDelayNanoseconds: UInt64

    public init(
        initialUser: UserProfile? = nil,
        simulatedDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.currentProfile = initialUser
        self.simulatedDelayNanoseconds = simulatedDelayNanoseconds
    }

    public func currentUser() -> UserProfile? {
        lock.withLock { currentProfile }
    }

    public func observeAuthState() -> AsyncStream<UserProfile?> {
        let identifier = UUID()
        return AsyncStream { [weak self] continuation in
            guard let self = self else {
                continuation.finish()
                return
            }

            let initial: UserProfile? = self.lock.withLock {
                self.continuations[identifier] = continuation
                return self.currentProfile
            }

            continuation.yield(initial)

            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                self.lock.withLock {
                    _ = self.continuations.removeValue(forKey: identifier)
                }
            }
        }
    }

    public func signInWithEmail(email: String, password: String) async throws -> UserProfile {
        try await applyDelay()

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }

        let profile = UserProfile(
            id: "mock_user_\(abs(trimmedEmail.hashValue))",
            name: "Александр",
            lastName: "Белянский",
            email: trimmedEmail,
            phone: "+375291234567"
        )

        updateCurrentProfile(profile)
        return profile
    }

    public func signUpWithEmail(email: String, password: String) async throws -> UserProfile {
        try await applyDelay()

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }

        guard password.count >= 6 else {
            throw AuthServiceError.invalidInput("Пароль должен содержать не менее 6 символов")
        }

        // New profile without name/phone to allow questionnaire flow testing
        let profile = UserProfile(
            id: "mock_user_\(UUID().uuidString.prefix(8).lowercased())",
            name: "",
            lastName: "",
            email: trimmedEmail,
            phone: ""
        )

        updateCurrentProfile(profile)
        return profile
    }

    public func signInWithApple(
        idToken: String,
        rawNonce: String,
        fullName: PersonNameComponents?
    ) async throws -> UserProfile {
        try await applyDelay()

        let givenName = fullName?.givenName ?? "Apple"
        let familyName = fullName?.familyName ?? "User"

        let profile = UserProfile(
            id: "mock_apple_\(UUID().uuidString.prefix(8).lowercased())",
            name: givenName,
            lastName: familyName,
            email: "apple_user@icloud.com",
            phone: ""
        )

        updateCurrentProfile(profile)
        return profile
    }

    public func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile {
        try await applyDelay()

        let profile = UserProfile(
            id: "mock_google_\(UUID().uuidString.prefix(8).lowercased())",
            name: "Google",
            lastName: "User",
            email: "google_user@gmail.com",
            phone: ""
        )

        updateCurrentProfile(profile)
        return profile
    }

    public func updateProfile(name: String, lastName: String, phone: String) async throws -> UserProfile {
        try await applyDelay()

        let (updatedProfile, streamSubscribers) = try lock.withLock { () -> (UserProfile, [AsyncStream<UserProfile?>.Continuation]) in
            guard var profile = currentProfile else {
                throw AuthServiceError.notAuthenticated
            }
            profile.name = name
            profile.lastName = lastName
            profile.phone = phone
            currentProfile = profile
            return (profile, Array(continuations.values))
        }

        for stream in streamSubscribers {
            stream.yield(updatedProfile)
        }

        return updatedProfile
    }

    public func signOut() async throws {
        try await applyDelay()
        updateCurrentProfile(nil)
    }

    // MARK: - Helpers

    public func setProfileDirectly(_ profile: UserProfile?) {
        updateCurrentProfile(profile)
    }

    private func updateCurrentProfile(_ profile: UserProfile?) {
        let streamSubscribers: [AsyncStream<UserProfile?>.Continuation] = lock.withLock {
            currentProfile = profile
            return Array(continuations.values)
        }

        for stream in streamSubscribers {
            stream.yield(profile)
        }
    }

    private func applyDelay() async throws {
        if simulatedDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        }
    }
}
