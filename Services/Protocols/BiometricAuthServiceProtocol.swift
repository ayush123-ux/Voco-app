import Foundation

/// Supported biometric hardware sensor types on Apple devices
public enum BiometricType: String, Sendable, CaseIterable {
    case none = "None"
    case touchID = "Touch ID"
    case faceID = "Face ID"
    case opticID = "Optic ID"

    public var displayName: String {
        return self.rawValue
    }
}

/// Errors occurring during biometric evaluation
public enum BiometricError: LocalizedError, Equatable, Sendable {
    case notAvailable
    case notEnrolled
    case lockout
    case userCancelled
    case systemCancelled
    case authenticationFailed
    case biometricsDisabled
    case other(String)

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not supported or available on this device."
        case .notEnrolled:
            return "No Face ID or Touch ID identity has been enrolled in iOS Settings."
        case .lockout:
            return "Biometrics are locked due to too many failed attempts. Please unlock with your device passcode."
        case .userCancelled:
            return "Authentication was cancelled."
        case .systemCancelled:
            return "Authentication was cancelled by the system."
        case .authenticationFailed:
            return "Biometric recognition did not match."
        case .biometricsDisabled:
            return "Biometric login is currently disabled in your VoCo settings."
        case .other(let message):
            return message
        }
    }
}

/// Defines biometric hardware authentication and user opt-in preferences
public protocol BiometricAuthServiceProtocol: AnyObject, Sendable {
    /// Hardware biometric sensor detected on current device
    var supportedBiometricType: BiometricType { get }

    /// Whether the device hardware supports biometrics and is ready
    var isBiometricAvailable: Bool { get }

    /// Non-sensitive user preference indicating opt-in to biometric login
    var isBiometricEnrollmentEnabled: Bool { get set }

    /// Prompts the user with native Face ID or Touch ID dialog
    func authenticateUser(reason: String) async -> Result<Void, BiometricError>
}
