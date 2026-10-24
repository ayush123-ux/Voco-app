import Foundation

/// Defines Speech-to-Text (STT) capabilities using Apple Speech framework
public protocol SpeechRecognitionServiceProtocol: AnyObject, Sendable {
    /// Whether speech recognition is currently recording and listening
    var isListening: Bool { get }

    /// Current authorization status for speech recognition
    var isAuthorized: Bool { get }

    /// Current active locale identifier (e.g. "en-IN", "hi-IN")
    var currentLocaleIdentifier: String { get }

    /// Sets or updates the speech recognition locale dynamically
    func setLocale(_ localeIdentifier: String)

    /// Requests user authorization for speech recognition and microphone access
    func requestAuthorization() async -> Bool

    /// Starts streaming speech recognition from the microphone
    func startListening(
        onTranscription: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) async throws

    /// Stops active speech recognition and releases audio resources
    func stopListening()
}
