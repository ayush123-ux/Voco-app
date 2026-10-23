import Foundation

/// Defines secure storage for authentication tokens in the device Keychain
public protocol SecureTokenStoreProtocol: AnyObject, Sendable {
    func storeSessionToken(_ token: String, forEmail email: String) throws
    func retrieveSessionToken(forEmail email: String) -> String?
    func retrieveLastAuthenticatedEmail() -> String?
    func clearSessionToken(forEmail email: String) throws
    func clearAllTokens() throws
}
