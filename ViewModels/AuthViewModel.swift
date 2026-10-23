import Foundation
import SwiftUI
import Combine

/// Manages authentication workflow state matching login.dart, register.dart, and home_decide.dart
@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    @Published public var confirmPassword = ""
    @Published public var errorMessage: String?
    @Published public var isProcessing = false
    @Published public var passwordResetSent = false
    @Published public var currentAuthState: AuthState = .unauthenticated

    // Biometric Authentication State
    @Published public var isBiometricEnrollmentEnabled: Bool = false
    @Published public var biometricType: BiometricType = .none
    @Published public var isBiometricAvailable: Bool = false
    @Published public var showBiometricEnrollmentPrompt: Bool = false

    // Voice Email Spelling State
    @Published public var emailConfirmed: Bool = false
    @Published public var voiceSpokenFeedback: String?

    public let authService: AuthServiceProtocol
    public let biometricService: BiometricAuthServiceProtocol
    public let tokenStore: SecureTokenStoreProtocol
    private let emailParser: VoiceEmailSpellingParser

    public init(
        authService: AuthServiceProtocol,
        biometricService: BiometricAuthServiceProtocol = NativeBiometricAuthService(),
        tokenStore: SecureTokenStoreProtocol = KeychainTokenStore(),
        emailParser: VoiceEmailSpellingParser = VoiceEmailSpellingParser()
    ) {
        self.authService = authService
        self.biometricService = biometricService
        self.tokenStore = tokenStore
        self.emailParser = emailParser
        self.currentAuthState = authService.currentAuthState
        self.isBiometricEnrollmentEnabled = biometricService.isBiometricEnrollmentEnabled
        self.biometricType = biometricService.supportedBiometricType
        self.isBiometricAvailable = biometricService.isBiometricAvailable
    }

    public var isAuthenticated: Bool {
        currentAuthState.isAuthenticated
    }

    public var currentUser: AuthUser? {
        currentAuthState.currentUser
    }

    public func signIn() async -> Bool {
        guard validateInputs(isRegistration: false) else { return false }

        isProcessing = true
        errorMessage = nil

        do {
            let user = try await authService.signIn(email: email, password: password)
            self.currentAuthState = .authenticated(user)

            // Secure session storage for biometrics if enrolled
            if isBiometricEnrollmentEnabled {
                try? tokenStore.storeSessionToken("session_\(user.id)", forEmail: user.email)
            } else if biometricService.isBiometricAvailable {
                showBiometricEnrollmentPrompt = true
            }

            self.isProcessing = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.currentAuthState = .error(error.localizedDescription)
            self.isProcessing = false
            return false
        }
    }

    public func signUp() async -> Bool {
        guard validateInputs(isRegistration: true) else { return false }

        isProcessing = true
        errorMessage = nil

        do {
            let user = try await authService.signUp(email: email, password: password)
            self.currentAuthState = .authenticated(user)

            if isBiometricEnrollmentEnabled {
                try? tokenStore.storeSessionToken("session_\(user.id)", forEmail: user.email)
            } else if biometricService.isBiometricAvailable {
                showBiometricEnrollmentPrompt = true
            }

            self.isProcessing = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.currentAuthState = .error(error.localizedDescription)
            self.isProcessing = false
            return false
        }
    }

    /// Authenticates with Face ID or Touch ID using LocalAuthentication and securely stored session credentials
    public func signInWithBiometrics() async -> Bool {
        guard isBiometricEnrollmentEnabled else {
            self.errorMessage = "Biometric login is not enrolled. Please sign in with your email and password first."
            return false
        }

        guard biometricService.isBiometricAvailable else {
            self.errorMessage = "\(biometricService.supportedBiometricType.displayName) is not available on this device."
            return false
        }

        guard let email = tokenStore.retrieveLastAuthenticatedEmail(),
              let sessionToken = tokenStore.retrieveSessionToken(forEmail: email) else {
            self.errorMessage = "No saved session found for biometric sign-in. Please log in with your password."
            return false
        }

        isProcessing = true
        errorMessage = nil

        let biometricResult = await biometricService.authenticateUser(
            reason: "Sign in to VoCo using \(biometricService.supportedBiometricType.displayName)"
        )

        switch biometricResult {
        case .success:
            do {
                let user = try await authService.restoreSession(email: email, sessionToken: sessionToken)
                self.email = user.email
                self.currentAuthState = .authenticated(user)
                self.isProcessing = false
                return true
            } catch {
                self.errorMessage = "Session expired. Please sign in with your password to re-enable \(biometricService.supportedBiometricType.displayName)."
                self.currentAuthState = .unauthenticated
                self.isProcessing = false
                return false
            }
        case .failure(let error):
            self.errorMessage = error.localizedDescription
            self.isProcessing = false
            return false
        }
    }

    /// Updates opt-in biometric enrollment preference
    public func setBiometricEnrollment(enabled: Bool) {
        biometricService.isBiometricEnrollmentEnabled = enabled
        self.isBiometricEnrollmentEnabled = enabled

        if enabled, let user = currentUser {
            try? tokenStore.storeSessionToken("session_\(user.id)", forEmail: user.email)
        } else if !enabled {
            try? tokenStore.clearAllTokens()
        }
        showBiometricEnrollmentPrompt = false
    }

    /// Handles voice email spelling input, punctuation, and explicit confirmation
    public func handleSpokenEmailInput(_ spokenPhrase: String) {
        let result = emailParser.parse(spokenPhrase: spokenPhrase, currentBuffer: self.email)

        switch result {
        case .updated(let normalizedEmail, let spokenFeedback, _):
            self.email = normalizedEmail
            self.voiceSpokenFeedback = spokenFeedback
            self.emailConfirmed = false
        case .confirmed(let confirmedEmail):
            self.email = confirmedEmail
            self.emailConfirmed = true
            self.voiceSpokenFeedback = "Email confirmed: \(confirmedEmail)"
        case .cleared(let spokenFeedback):
            self.email = ""
            self.emailConfirmed = false
            self.voiceSpokenFeedback = spokenFeedback
        case .error(let message):
            self.voiceSpokenFeedback = message
        }
    }

    /// Signs out the user, clearing authentication session credentials from Keychain and resetting biometric preference.
    /// Persistent user data, profile, and progress are preserved.
    public func signOut() async {
        isProcessing = true
        do {
            try await authService.signOut()

            // Explicitly clear session tokens from Keychain
            do {
                try tokenStore.clearAllTokens()
            } catch {
                self.errorMessage = "Failed to clear secure session tokens: \(error.localizedDescription)"
            }

            // Reset biometric fast-login enrollment preference
            biometricService.isBiometricEnrollmentEnabled = false
            self.isBiometricEnrollmentEnabled = false

            self.currentAuthState = .unauthenticated
            self.email = ""
            self.password = ""
            self.confirmPassword = ""
            self.emailConfirmed = false
            self.voiceSpokenFeedback = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isProcessing = false
    }

    public func sendPasswordReset() async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            self.errorMessage = "Please enter a valid email address to receive the password reset link."
            return false
        }

        isProcessing = true
        errorMessage = nil
        do {
            try await authService.sendPasswordReset(to: trimmedEmail)
            self.passwordResetSent = true
            self.isProcessing = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isProcessing = false
            return false
        }
    }

    public func validateInputs(isRegistration: Bool) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Email cannot be empty."
            return false
        }

        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid email address."
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Password cannot be empty."
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters long."
            return false
        }

        if isRegistration && !confirmPassword.isEmpty && password != confirmPassword {
            errorMessage = "Passwords do not match."
            return false
        }

        errorMessage = nil
        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
