import Foundation
import Combine

/// Local and offline implementation of AuthServiceProtocol.
/// Allows the SwiftUI app to build, test, and run seamlessly without requiring
/// a remote Firebase project or missing GoogleService-Info.plist.
public final class MockAuthService: AuthServiceProtocol, ObservableObject, @unchecked Sendable {
    @Published public private(set) var currentAuthState: AuthState = .unauthenticated
    @Published public private(set) var currentUser: AuthUser?

    private let userDefaultsKey = "voco_mock_authenticated_user_email"

    public init(preAuthenticateWithEmail: String? = nil) {
        if let email = preAuthenticateWithEmail ?? UserDefaults.standard.string(forKey: userDefaultsKey) {
            let user = AuthUser(
                id: "mock-\(email.hashValue)",
                email: email,
                displayName: email.components(separatedBy: "@").first?.capitalized ?? "VoCo Learner"
            )
            self.currentUser = user
            self.currentAuthState = .authenticated(user)
        }
    }

    public func signIn(email: String, password: String) async throws -> AuthUser {
        // Validate inputs
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            let errorMsg = "Please enter a valid email address."
            currentAuthState = .error(errorMsg)
            throw NSError(domain: "VoCoAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        guard password.count >= 6 else {
            let errorMsg = "Password must be at least 6 characters long."
            currentAuthState = .error(errorMsg)
            throw NSError(domain: "VoCoAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        // Simulate network latency (200ms)
        try? await Task.sleep(nanoseconds: 200_000_000)

        let user = AuthUser(
            id: "user-\(trimmedEmail.hashValue)",
            email: trimmedEmail,
            displayName: trimmedEmail.components(separatedBy: "@").first?.capitalized ?? "VoCo Learner"
        )

        UserDefaults.standard.set(trimmedEmail, forKey: userDefaultsKey)
        await MainActor.run {
            self.currentUser = user
            self.currentAuthState = .authenticated(user)
        }
        return user
    }

    public func signUp(email: String, password: String) async throws -> AuthUser {
        return try await signIn(email: email, password: password)
    }

    public func signOut() async throws {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        await MainActor.run {
            self.currentUser = nil
            self.currentAuthState = .unauthenticated
        }
    }

    public func sendPasswordReset(to email: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            throw NSError(domain: "VoCoAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid email for reset."])
        }
        // Simulated network delay
        try? await Task.sleep(nanoseconds: 150_000_000)
    }

    public func restoreSession(email: String, sessionToken: String) async throws -> AuthUser {
        guard !sessionToken.isEmpty else {
            throw NSError(domain: "VoCoAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid session token."])
        }

        let user = AuthUser(
            id: "user-\(email.hashValue)",
            email: email,
            displayName: email.components(separatedBy: "@").first?.capitalized ?? "VoCo Learner"
        )

        UserDefaults.standard.set(email, forKey: userDefaultsKey)
        await MainActor.run {
            self.currentUser = user
            self.currentAuthState = .authenticated(user)
        }
        return user
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
