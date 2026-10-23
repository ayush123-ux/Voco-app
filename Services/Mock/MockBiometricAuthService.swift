import Foundation

/// Mock implementation of BiometricAuthServiceProtocol for testing and offline development
public final class MockBiometricAuthService: BiometricAuthServiceProtocol, @unchecked Sendable {
    public var supportedBiometricType: BiometricType
    public var isBiometricAvailable: Bool
    public var isBiometricEnrollmentEnabled: Bool

    public var nextResult: Result<Void, BiometricError> = .success(())
    public private(set) var authenticateCallCount: Int = 0
    public private(set) var lastReason: String?

    public init(
        supportedBiometricType: BiometricType = .faceID,
        isBiometricAvailable: Bool = true,
        isBiometricEnrollmentEnabled: Bool = false
    ) {
        self.supportedBiometricType = supportedBiometricType
        self.isBiometricAvailable = isBiometricAvailable
        self.isBiometricEnrollmentEnabled = isBiometricEnrollmentEnabled
    }

    public func authenticateUser(reason: String) async -> Result<Void, BiometricError> {
        authenticateCallCount += 1
        lastReason = reason

        guard isBiometricAvailable else {
            return .failure(.notAvailable)
        }

        return nextResult
    }
}
