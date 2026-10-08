import Foundation

public struct AuthSession: Codable, Equatable, Sendable {
    public let token: String
    public let userId: String
    public let expirationDate: Date?

    public init(token: String, userId: String, expirationDate: Date? = nil) {
        self.token = token
        self.userId = userId
        self.expirationDate = expirationDate
    }
}
