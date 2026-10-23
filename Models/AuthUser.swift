import Foundation

/// Represents an authenticated user in VoCo
public struct AuthUser: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let email: String
    public let displayName: String?
    public let photoURL: URL?
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        email: String,
        displayName: String? = nil,
        photoURL: URL? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
    }
}

/// Represents the session state of the authentication system
public enum AuthState: Equatable, Sendable {
    case unauthenticated
    case authenticating
    case authenticated(AuthUser)
    case error(String)

    public var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }

    public var currentUser: AuthUser? {
        if case .authenticated(let user) = self {
            return user
        }
        return nil
    }
}
