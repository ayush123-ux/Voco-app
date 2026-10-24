import Foundation

/// In-memory mock for SpeechRecognitionServiceProtocol for unit testing and offline development
public final class MockSpeechRecognitionService: SpeechRecognitionServiceProtocol, @unchecked Sendable {
    public var isListening: Bool = false
    public var isAuthorized: Bool = true
    public var currentLocaleIdentifier: String = "en-IN"
    public var simulatedTranscription: String = ""
    public var shouldFailAuthorization: Bool = false
    public var shouldThrowStartError: Bool = false
    public var startListeningCallCount: Int = 0
    public var stopListeningCallCount: Int = 0

    public var onTranscriptionCallback: ((String) -> Void)?
    public var onErrorCallback: ((Error) -> Void)?

    public init(isAuthorized: Bool = true, localeIdentifier: String = "en-IN") {
        self.isAuthorized = isAuthorized
        self.currentLocaleIdentifier = localeIdentifier
    }

    public func setLocale(_ localeIdentifier: String) {
        self.currentLocaleIdentifier = localeIdentifier
    }

    public func requestAuthorization() async -> Bool {
        if shouldFailAuthorization {
            isAuthorized = false
            return false
        }
        isAuthorized = true
        return true
    }

    public func startListening(
        onTranscription: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) async throws {
        startListeningCallCount += 1
        self.onTranscriptionCallback = onTranscription
        self.onErrorCallback = onError

        if shouldThrowStartError {
            let error = NSError(domain: "MockSpeech", code: 500, userInfo: [NSLocalizedDescriptionKey: "Simulated mic error"])
            onError(error)
            throw error
        }

        isListening = true
        if !simulatedTranscription.isEmpty {
            onTranscription(simulatedTranscription)
        }
    }

    public func stopListening() {
        stopListeningCallCount += 1
        isListening = false
    }

    /// Simulates incoming spoken voice input during tests
    public func simulateSpeech(_ text: String, onTranscription: ((String) -> Void)? = nil) {
        simulatedTranscription = text
        if let onTranscription = onTranscription {
            onTranscription(text)
        } else {
            onTranscriptionCallback?(text)
        }
    }

    /// Simulates incoming speech recognition error during tests
    public func simulateError(_ error: Error) {
        onErrorCallback?(error)
    }
}
