import Foundation

public struct UserProfile: Identifiable, Codable, Equatable, Sendable {
    public let id: String // Firebase UID
    public var name: String
    public var lastName: String
    public var email: String
    public var phone: String
    public var photoUrl: URL?

    public init(
        id: String = "",
        name: String = "",
        lastName: String = "",
        email: String = "",
        phone: String = "",
        photoUrl: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.photoUrl = photoUrl
    }

    public var displayName: String {
        "\(name) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
