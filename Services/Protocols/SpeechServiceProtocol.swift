import Foundation

/// Defines Text-to-Speech (TTS) capabilities replacing flutter_tts
public protocol SpeechServiceProtocol: AnyObject, Sendable {
    /// Whether the synthesizer is actively speaking
    var isSpeaking: Bool { get }

    /// Speaks the given text using AVFoundation AVSpeechSynthesizer
    func speak(
        text: String,
        language: String,
        pitchMultiplier: Float,
        rate: Float
    ) async

    /// Stops any ongoing speech utterance immediately
    func stopSpeaking()
}

public extension SpeechServiceProtocol {
    /// Default speech synthesis matching the Flutter app's parameters
    func speak(text: String) async {
        await speak(text: text, language: "en-US", pitchMultiplier: 1.0, rate: 0.5)
    }
}
