import Foundation

public enum DiscountTier: String, Codable, CaseIterable, Sendable {
    case silver
    case gold
    case platinum
    case unknown

    public static func tier(for percentage: Double) -> DiscountTier {
        switch percentage {
        case 0...10: return .silver
        case 10.01...20: return .gold
        case 20.01...100: return .platinum
        default: return .unknown
        }
    }

    public var title: String {
        rawValue.uppercased()
    }
}
