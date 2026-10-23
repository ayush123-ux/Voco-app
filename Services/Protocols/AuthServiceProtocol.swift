import Foundation

/// Defines authentication capabilities conforming to standard async/await patterns
public protocol AuthServiceProtocol: AnyObject, Sendable {
    /// Stream or publish the current authentication state
    var currentAuthState: AuthState { get }

    /// Currently authenticated user, or nil if unauthenticated
    var currentUser: AuthUser? { get }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> AuthUser

    /// Create a new account with email and password
    func signUp(email: String, password: String) async throws -> AuthUser

    /// Sign out the current user session
    func signOut() async throws

    /// Send a password reset email
    func sendPasswordReset(to email: String) async throws

    /// Restores or validates an existing session token for an email address
    func restoreSession(email: String, sessionToken: String) async throws -> AuthUser
}

public extension AuthServiceProtocol {
    func restoreSession(email: String, sessionToken: String) async throws -> AuthUser {
        guard let current = currentUser, current.email == email else {
            throw NSError(
                domain: "VoCoAuth",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No active session exists. Please sign in with your password."]
            )
        }
        return current
    }
}
