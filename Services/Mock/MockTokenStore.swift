import Foundation

/// In-memory mock implementation of SecureTokenStoreProtocol for deterministic unit tests
public final class MockTokenStore: SecureTokenStoreProtocol, @unchecked Sendable {
    private var tokens: [String: String] = [:]
    private var lastEmail: String?

    public init(initialTokens: [String: String] = [:], lastEmail: String? = nil) {
        self.tokens = initialTokens
        self.lastEmail = lastEmail
    }

    public func storeSessionToken(_ token: String, forEmail email: String) throws {
        tokens[email] = token
        lastEmail = email
    }

    public func retrieveSessionToken(forEmail email: String) -> String? {
        return tokens[email]
    }

    public func retrieveLastAuthenticatedEmail() -> String? {
        return lastEmail
    }

    public func clearSessionToken(forEmail email: String) throws {
        tokens.removeValue(forKey: email)
        if lastEmail == email {
            lastEmail = nil
        }
    }

    public func clearAllTokens() throws {
        tokens.removeAll()
        lastEmail = nil
    }
}
