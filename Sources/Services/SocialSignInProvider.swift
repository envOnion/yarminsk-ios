import AuthenticationServices
import CryptoKit
import FirebaseCore
import GoogleSignIn
import Security
import UIKit

public struct GoogleSignInTokens {
    public let idToken: String
    public let accessToken: String
}

public struct AppleSignInTokens {
    public let idToken: String
    public let rawNonce: String
    public let fullName: PersonNameComponents?
    public var authorizationCode: String? = nil
}

@MainActor
public protocol SocialSignInProviding {
    func signInWithGoogle() async throws -> GoogleSignInTokens
    func signInWithApple() async throws -> AppleSignInTokens
}

/// Presents the provider's own sign-in UI before exchanging its tokens with Firebase.
@MainActor
public final class SocialSignInProvider: NSObject, SocialSignInProviding {
    private var appleContinuation: CheckedContinuation<AppleSignInTokens, Error>?
    private var appleController: ASAuthorizationController?
    private var appleWindow: UIWindow?
    private var appleNonce: String?

    public func signInWithGoogle() async throws -> GoogleSignInTokens {
        guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
            throw AuthServiceError.underlying("Не настроен вход через Google")
        }
        guard let root = activeWindow()?.rootViewController else {
            throw AuthServiceError.underlying("Не удалось открыть окно входа")
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingController(root))
            guard let idToken = result.user.idToken?.tokenString, !idToken.isEmpty else {
                throw AuthServiceError.underlying("Google не вернул токен входа. Попробуйте ещё раз")
            }
            return GoogleSignInTokens(idToken: idToken, accessToken: result.user.accessToken.tokenString)
        } catch {
            let nsError = error as NSError
            if nsError.domain == kGIDSignInErrorDomain,
               nsError.code == GIDSignInError.canceled.rawValue {
                throw AuthServiceError.cancelled
            }
            throw error
        }
    }

    public func signInWithApple() async throws -> AppleSignInTokens {
        guard appleContinuation == nil else { throw AuthServiceError.cancelled }
        guard let window = activeWindow() else {
            throw AuthServiceError.underlying("Не удалось открыть окно входа")
        }
        let nonce = try Self.randomNonce()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        return try await withCheckedThrowingContinuation { continuation in
            appleContinuation = continuation
            appleNonce = nonce
            appleWindow = window
            let controller = ASAuthorizationController(authorizationRequests: [request])
            appleController = controller
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    static func randomNonce(length: Int = 32) throws -> String {
        let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var nonce = ""
        // Rejection sampling avoids bias when mapping random bytes into the alphabet.
        while nonce.count < length {
            var bytes = [UInt8](repeating: 0, count: 16)
            guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
                throw AuthServiceError.underlying("Не удалось подготовить безопасный вход через Apple")
            }
            for byte in bytes where Int(byte) < alphabet.count {
                nonce.append(alphabet[Int(byte)])
                if nonce.count == length { break }
            }
        }
        return nonce
    }

    static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    private func presentingController(_ root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return presentingController(presented)
        }
        if let navigation = root as? UINavigationController, let visible = navigation.visibleViewController {
            return presentingController(visible)
        }
        if let tabs = root as? UITabBarController, let selected = tabs.selectedViewController {
            return presentingController(selected)
        }
        return root
    }

    private func finishApple(_ result: Result<AppleSignInTokens, Error>) {
        let continuation = appleContinuation
        appleContinuation = nil
        appleController = nil
        appleNonce = nil
        appleWindow = nil
        continuation?.resume(with: result)
    }
}

extension SocialSignInProvider: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        appleWindow ?? ASPresentationAnchor()
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let data = credential.identityToken,
              let idToken = String(data: data, encoding: .utf8),
              !idToken.isEmpty,
              let nonce = appleNonce else {
            finishApple(.failure(AuthServiceError.underlying("Apple не вернул токен входа. Попробуйте ещё раз")))
            return
        }
        let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        finishApple(.success(AppleSignInTokens(idToken: idToken, rawNonce: nonce, fullName: credential.fullName, authorizationCode: authorizationCode)))
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue {
            finishApple(.failure(AuthServiceError.cancelled))
        } else {
            finishApple(.failure(AuthServiceError.underlying("Не удалось войти через Apple. Проверьте вход в iCloud и попробуйте ещё раз")))
        }
    }
}
