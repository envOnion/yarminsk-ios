import Foundation
import Combine

@MainActor
public final class AccountDeletionViewModel: ObservableObject {
    @Published public private(set) var isDeleting = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var didDeleteAccount = false

    private let authService: AuthServiceProtocol
    private let discountService: DiscountServiceProtocol
    private let sessionStorage: SessionStorageProtocol
    private let socialProvider: SocialSignInProviding

    public var provider: AccountDeletionProvider { authService.accountDeletionProvider() }

    public init(authService: AuthServiceProtocol, discountService: DiscountServiceProtocol,
                sessionStorage: SessionStorageProtocol, socialProvider: SocialSignInProviding? = nil) {
        self.authService = authService
        self.discountService = discountService
        self.sessionStorage = sessionStorage
        self.socialProvider = socialProvider ?? SocialSignInProvider()
    }

    public func deleteAccount(password: String) async {
        guard !isDeleting, !didDeleteAccount else { return }
        guard let userID = authService.currentUser()?.id else {
            errorMessage = "Войдите в аккаунт перед удалением"
            return
        }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }
        var cardWasRemoved = false
        do {
            let credential: AccountDeletionCredential
            var appleAuthorizationCode: String?
            switch provider {
            case .password:
                guard !password.isEmpty else {
                    throw AuthServiceError.invalidInput("Введите пароль для подтверждения удаления")
                }
                credential = .password(password)
            case .apple:
                let tokens = try await socialProvider.signInWithApple()
                guard let code = tokens.authorizationCode, !code.isEmpty else {
                    throw AuthServiceError.underlying("Apple не подтвердил удаление. Попробуйте ещё раз")
                }
                appleAuthorizationCode = code
                credential = .apple(idToken: tokens.idToken, rawNonce: tokens.rawNonce)
            case .google:
                let tokens = try await socialProvider.signInWithGoogle()
                credential = .google(idToken: tokens.idToken, accessToken: tokens.accessToken)
            }
            try await authService.reauthenticateForDeletion(credential: credential)
            // Never erase another user's card if the session changed during reauthentication.
            guard authService.currentUser()?.id == userID else { throw AuthServiceError.notAuthenticated }
            try await discountService.deleteDiscount(userId: userID)
            cardWasRemoved = true
            try await authService.deleteAccount(appleAuthorizationCode: appleAuthorizationCode)
            sessionStorage.clearToken()
            didDeleteAccount = true
        } catch AuthServiceError.cancelled {
            // Dismissing the provider sheet leaves all data untouched.
        } catch {
            errorMessage = cardWasRemoved
                ? "Карта удалена, но удаление аккаунта не завершено. Повторите попытку. \(error.localizedDescription)"
                : error.localizedDescription
        }
    }
}
