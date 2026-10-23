import Foundation

/// In-memory mock for SpeechServiceProtocol for unit testing
public final class MockSpeechService: SpeechServiceProtocol, @unchecked Sendable {
    public var isSpeaking: Bool = false
    public var speakCallCount: Int = 0
    public var stopSpeakingCallCount: Int = 0
    public var lastSpokenText: String = ""

    public var onSpeakCalled: ((String) -> Void)?

    public init() {}

    public func speak(
        text: String,
        language: String = "en-US",
        pitchMultiplier: Float = 1.0,
        rate: Float = 0.5
    ) async {
        isSpeaking = true
        speakCallCount += 1
        lastSpokenText = text
        onSpeakCalled?(text)

        // Simulate speech completion
        isSpeaking = false
    }

    public func stopSpeaking() {
        stopSpeakingCallCount += 1
        isSpeaking = false
    }
}
