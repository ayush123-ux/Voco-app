import Foundation
import Security

/// Production implementation of SecureTokenStoreProtocol utilizing iOS Keychain Services
public final class KeychainTokenStore: SecureTokenStoreProtocol, @unchecked Sendable {
    private let serviceName = "app.voco.auth.tokens"
    private let lastEmailKey = "voco.last.authenticated.email"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func storeSessionToken(_ token: String, forEmail email: String) throws {
        guard let tokenData = token.data(using: .utf8) else { return }

        // Store last active email (non-sensitive identifier)
        defaults.set(email, forKey: lastEmailKey)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: email
        ]

        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: tokenData
        ]

        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if status == errSecItemNotFound {
            var newQuery = query
            newQuery[kSecValueData as String] = tokenData
            newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(newQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
            }
        } else if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    public func retrieveSessionToken(forEmail email: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    public func retrieveLastAuthenticatedEmail() -> String? {
        return defaults.string(forKey: lastEmailKey)
    }

    public func clearSessionToken(forEmail email: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: email
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    public func clearAllTokens() throws {
        defaults.removeObject(forKey: lastEmailKey)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
