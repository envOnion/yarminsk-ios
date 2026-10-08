import Foundation
import Security

/// Keychain-backed storage for user authentication tokens and session identifiers.
public final class KeychainSessionStorage: SessionStorageProtocol, @unchecked Sendable {
    private let service: String
    private let account: String
    private let lock = NSLock()

    public init(
        service: String = "by.yarminsk.app.session",
        account: String = "user_token"
    ) {
        self.service = service
        self.account = account
    }

    public func saveToken(_ token: String) {
        lock.withLock {
            guard let data = token.data(using: .utf8) else { return }

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]

            SecItemDelete(query as CFDictionary)

            var attributes = query
            attributes[kSecValueData as String] = data
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

            SecItemAdd(attributes as CFDictionary, nil)
        }
    }

    public func getToken() -> String? {
        lock.withLock {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status == errSecSuccess, let data = item as? Data else {
                return nil
            }

            return String(data: data, encoding: .utf8)
        }
    }

    public func clearToken() {
        lock.withLock {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]

            SecItemDelete(query as CFDictionary)
        }
    }
}
