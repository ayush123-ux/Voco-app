import Foundation

/// In-memory mock for SpeechServiceProtocol for unit testing
public final class MockSpeechService: SpeechServiceProtocol, @unchecked Sendable {
    public var isSpeaking: Bool = false
    public var defaultLanguage: String = "en-IN"
    public var speakCallCount: Int = 0
    public var stopSpeakingCallCount: Int = 0
    public var lastSpokenText: String = ""
    public var lastSpokenLanguage: String? = nil
    public var spokenUtterances: [String] = []

    public var onSpeakCalled: ((String) -> Void)?

    public init() {}

    public func speak(
        text: String,
        language: String? = nil,
        pitchMultiplier: Float = 1.0,
        rate: Float = 0.5
    ) async {
        isSpeaking = true
        speakCallCount += 1
        lastSpokenText = text
        lastSpokenLanguage = language ?? defaultLanguage
        spokenUtterances.append(text)
        onSpeakCalled?(text)

        // Simulate speech completion
        isSpeaking = false
    }

    public func stopSpeaking() {
        stopSpeakingCallCount += 1
        isSpeaking = false
    }
}
