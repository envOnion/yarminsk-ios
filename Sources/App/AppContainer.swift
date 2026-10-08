import SwiftUI

@MainActor
public final class AppContainer: ObservableObject {
    public let authService: AuthServiceProtocol
    public let discountService: DiscountServiceProtocol
    public let sessionStorage: SessionStorageProtocol

    public init(
        authService: AuthServiceProtocol,
        discountService: DiscountServiceProtocol,
        sessionStorage: SessionStorageProtocol
    ) {
        self.authService = authService
        self.discountService = discountService
        self.sessionStorage = sessionStorage
    }
}
