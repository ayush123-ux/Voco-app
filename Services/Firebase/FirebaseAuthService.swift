import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

/// Firebase Authentication Service implementation.
/// Automatically activates whenever GoogleService-Info.plist and FirebaseAuth SDK are linked.
public final class FirebaseAuthService: AuthServiceProtocol, @unchecked Sendable {
    public var currentAuthState: AuthState {
        #if canImport(FirebaseAuth)
        if let firebaseUser = Auth.auth().currentUser {
            return .authenticated(AuthUser(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName,
                photoURL: firebaseUser.photoURL
            ))
        }
        return .unauthenticated
        #else
        return .unauthenticated
        #endif
    }

    public var currentUser: AuthUser? {
        currentAuthState.currentUser
    }

    public init() {}

    public func signIn(email: String, password: String) async throws -> AuthUser {
        #if canImport(FirebaseAuth)
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthUser(
            id: result.user.uid,
            email: result.user.email ?? email,
            displayName: result.user.displayName,
            photoURL: result.user.photoURL
        )
        #else
        throw NSError(
            domain: "VoCoFirebase",
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: "Firebase SDK is not linked. Drop GoogleService-Info.plist into the project and link FirebaseAuth to enable live cloud authentication."]
        )
        #endif
    }

    public func signUp(email: String, password: String) async throws -> AuthUser {
        #if canImport(FirebaseAuth)
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthUser(
            id: result.user.uid,
            email: result.user.email ?? email,
            displayName: result.user.displayName,
            photoURL: result.user.photoURL
        )
        #else
        throw NSError(
            domain: "VoCoFirebase",
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: "Firebase SDK is not linked."]
        )
        #endif
    }

    public func signOut() async throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #endif
    }

    public func sendPasswordReset(to email: String) async throws {
        #if canImport(FirebaseAuth)
        try await Auth.auth().sendPasswordReset(withEmail: email)
        #else
        throw NSError(
            domain: "VoCoFirebase",
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: "Firebase SDK is not linked."]
        )
        #endif
    }

    public func restoreSession(email: String, sessionToken: String) async throws -> AuthUser {
        #if canImport(FirebaseAuth)
        if let firebaseUser = Auth.auth().currentUser, (firebaseUser.email ?? "") == email {
            return AuthUser(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? email,
                displayName: firebaseUser.displayName,
                photoURL: firebaseUser.photoURL
            )
        }
        throw NSError(
            domain: "VoCoFirebase",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Firebase session expired. Please sign in with your password."]
        )
        #else
        throw NSError(
            domain: "VoCoFirebase",
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: "Firebase SDK is not linked."]
        )
        #endif
    }
}
