import Foundation
import SwiftUI

/// View model managing loyalty state, card fetching, user registration, and session.
@MainActor
public final class LoyaltyViewModel: ObservableObject {
    @Published public var profile: UserProfile?
    @Published public var discountCard: DiscountCard?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var needsRegistration: Bool = false

    private let authService: AuthServiceProtocol
    private let discountService: DiscountServiceProtocol
    private let sessionStorage: SessionStorageProtocol

    public init(
        authService: AuthServiceProtocol,
        discountService: DiscountServiceProtocol,
        sessionStorage: SessionStorageProtocol
    ) {
        self.authService = authService
        self.discountService = discountService
        self.sessionStorage = sessionStorage
    }

    /// Fetches the current user profile and checks for an existing loyalty discount card.
    /// Sets `needsRegistration = true` if no card is found in the database.
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let user = authService.currentUser()
        self.profile = user

        guard let userId = user?.id, !userId.isEmpty else {
            self.discountCard = nil
            self.needsRegistration = false
            return
        }

        do {
            let card = try await discountService.getDiscount(userId: userId)
            self.discountCard = card
            self.needsRegistration = (card == nil)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Updates the user profile and creates a new loyalty discount card.
    /// Automatically sets `needsRegistration = false` upon success.
    public func createCard(name: String, lastName: String, phone: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            // 1. Update user profile
            let updatedProfile = try await authService.updateProfile(
                name: trimmedName,
                lastName: trimmedLastName,
                phone: trimmedPhone
            )
            self.profile = updatedProfile

            // 2. Generate new discount card
            let cardId = UUID().uuidString
            let cardHolder = "\(trimmedName) \(trimmedLastName)".uppercased()
            let qrPrefix = String(cardId.prefix(6)).uppercased()

            let card = DiscountCard(
                id: cardId,
                userId: updatedProfile.id,
                cardHolder: cardHolder,
                discount: 10.0,
                qrData: qrPrefix,
                phone: trimmedPhone
            )

            try await discountService.createDiscount(card)
            self.discountCard = card
            self.needsRegistration = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Re-fetches the discount card from the backend service.
    public func refresh() async {
        guard let userId = profile?.id ?? authService.currentUser()?.id, !userId.isEmpty else {
            return
        }

        do {
            let card = try await discountService.getDiscount(userId: userId)
            self.discountCard = card
            self.needsRegistration = (card == nil)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Signs out the current user and clears persisted session tokens.
    public func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signOut()
        } catch {
            self.errorMessage = error.localizedDescription
            return
        }

        sessionStorage.clearToken()
        self.profile = nil
        self.discountCard = nil
        self.needsRegistration = false
    }
}
