import Foundation
import FirebaseDatabase

/// Concrete implementation of `DiscountServiceProtocol` backed by Firebase Realtime Database.
/// Interacts with the `/discount/{userId}` database node.
public final class FirebaseDiscountService: DiscountServiceProtocol, @unchecked Sendable {
    private let customRef: DatabaseReference?

    public init(databaseRef: DatabaseReference? = nil) {
        self.customRef = databaseRef
    }

    private var rootRef: DatabaseReference {
        customRef ?? Database.database().reference()
    }

    public func getDiscount(userId: String) async throws -> DiscountCard? {
        let snapshot = try await rootRef.child("discount").child(userId).getData()

        guard snapshot.exists(), let dict = snapshot.value as? [String: Any] else {
            return nil
        }

        let id = dict["id"] as? String ?? snapshot.key
        let cardHolder = dict["cardHolder"] as? String ?? ""
        let discount: Double
        if let number = dict["discount"] as? NSNumber {
            discount = number.doubleValue
        } else if let val = dict["discount"] as? Double {
            discount = val
        } else {
            discount = 10.0
        }
        let qrData = dict["qrData"] as? String ?? String(id.prefix(6))
        let phone = dict["phone"] as? String ?? ""
        let cardUserId = dict["userId"] as? String ?? userId

        return DiscountCard(
            id: id,
            userId: cardUserId,
            cardHolder: cardHolder,
            discount: discount,
            qrData: qrData,
            phone: phone
        )
    }

    public func createDiscount(_ card: DiscountCard) async throws {
        let dict: [String: Any] = [
            "id": card.id,
            "userId": card.userId,
            "cardHolder": card.cardHolder,
            "discount": card.discount,
            "qrData": card.qrData,
            "phone": card.phone
        ]

        try await rootRef.child("discount").child(card.userId).setValue(dict)
    }
}
