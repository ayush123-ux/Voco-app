import Foundation
import LocalAuthentication

/// Production implementation of BiometricAuthServiceProtocol using Apple's LocalAuthentication framework
public final class NativeBiometricAuthService: BiometricAuthServiceProtocol, @unchecked Sendable {
    private let userDefaultsKey = "voco.biometric.enrollment.enabled"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Dynamically evaluates hardware capability via LAContext
    public var supportedBiometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// Evaluates if biometric authentication can be performed right now
    public var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Non-sensitive opt-in enrollment toggle stored in UserDefaults
    /// Note: Passwords or biometric credentials are NEVER stored here.
    public var isBiometricEnrollmentEnabled: Bool {
        get {
            defaults.bool(forKey: userDefaultsKey)
        }
        set {
            defaults.set(newValue, forKey: userDefaultsKey)
        }
    }

    /// Prompts the system Face ID / Touch ID evaluation dialog
    public func authenticateUser(reason: String) async -> Result<Void, BiometricError> {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                return .failure(mapLAError(laError))
            }
            return .failure(.notAvailable)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success {
                return .success(())
            } else {
                return .failure(.authenticationFailed)
            }
        } catch let laError as LAError {
            return .failure(mapLAError(laError))
        } catch {
            return .failure(.other(error.localizedDescription))
        }
    }

    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .systemCancel:
            return .systemCancelled
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        default:
            return .other(error.localizedDescription)
        }
    }
}
