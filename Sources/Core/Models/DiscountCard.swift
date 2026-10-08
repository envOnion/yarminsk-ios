import Foundation

public struct DiscountCard: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let userId: String
    public let cardHolder: String
    public let discount: Double
    public let qrData: String
    public let phone: String

    public init(
        id: String,
        userId: String,
        cardHolder: String,
        discount: Double = 10.0,
        qrData: String = "",
        phone: String = ""
    ) {
        self.id = id
        self.userId = userId
        self.cardHolder = cardHolder
        self.discount = discount
        self.qrData = qrData.isEmpty ? String(id.prefix(6)) : qrData
        self.phone = phone
    }

    public var tier: DiscountTier {
        DiscountTier.tier(for: discount)
    }
}
