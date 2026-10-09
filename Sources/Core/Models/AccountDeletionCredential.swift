import Foundation

public enum AccountDeletionProvider: Sendable {
    case password, apple, google
}

public enum AccountDeletionCredential: Sendable {
    case password(String)
    case apple(idToken: String, rawNonce: String)
    case google(idToken: String, accessToken: String)
}
