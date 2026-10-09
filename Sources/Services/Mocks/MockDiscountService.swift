import Foundation

/// In-memory mock implementation of `DiscountServiceProtocol` for testing, previews, and offline operation.
public final class MockDiscountService: DiscountServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var cardsByUserId: [String: DiscountCard] = [:]

    public var simulatedDelayNanoseconds: UInt64

    public init(
        initialCards: [String: DiscountCard] = [:],
        simulatedDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.cardsByUserId = initialCards
        self.simulatedDelayNanoseconds = simulatedDelayNanoseconds
    }

    public func getDiscount(userId: String) async throws -> DiscountCard? {
        try await applyDelay()
        return lock.withLock { cardsByUserId[userId] }
    }

    public func createDiscount(_ card: DiscountCard) async throws {
        try await applyDelay()
        lock.withLock {
            cardsByUserId[card.userId] = card
        }
    }

    public func deleteDiscount(userId: String) async throws {
        try await applyDelay()
        _ = lock.withLock { cardsByUserId.removeValue(forKey: userId) }
    }

    // MARK: - Testing & Previews Helpers

    /// Direct synchronous access for test assertions and previews
    public func setCardDirectly(_ card: DiscountCard) {
        lock.withLock {
            cardsByUserId[card.userId] = card
        }
    }

    /// Clear all cards for test reset
    public func clearAllCards() {
        lock.withLock {
            cardsByUserId.removeAll()
        }
    }

    private func applyDelay() async throws {
        if simulatedDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        }
    }
}
