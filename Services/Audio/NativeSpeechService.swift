import Foundation
import AVFoundation

/// Native Text-to-Speech service using Apple AVFoundation AVSpeechSynthesizer.
/// Replaces Flutter's flutter_tts plugin without external dependencies.
public final class NativeSpeechService: NSObject, SpeechServiceProtocol, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    public private(set) var isSpeaking: Bool = false
    public var defaultLanguage: String = "en-IN"

    private var speechContinuation: CheckedContinuation<Void, Never>?

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func speak(
        text: String,
        language: String? = nil,
        pitchMultiplier: Float = 1.0,
        rate: Float = 0.5
    ) async {
        // Ensure any previous utterance is stopped
        stopSpeaking()

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            isSpeaking = false
            return
        }

        #if os(iOS)
        // Maintain playAndRecord category with speaker and bluetooth options so TTS
        // plays clearly without tearing down or permanently blocking microphone input.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[NativeSpeechService] Failed to configure audio session: \(error)")
        }
        #endif

        let targetLanguage = language ?? defaultLanguage
        let utterance = AVSpeechUtterance(string: trimmedText)

        #if os(iOS)
        utterance.voice = AVSpeechSynthesisVoice(language: targetLanguage)
            ?? AVSpeechSynthesisVoice(language: String(targetLanguage.prefix(2)))
            ?? AVSpeechSynthesisVoice(language: "en-IN")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        #endif

        utterance.pitchMultiplier = max(0.5, min(2.0, pitchMultiplier))
        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, rate * AVSpeechUtteranceDefaultSpeechRate * 2.0))

        isSpeaking = true

        await withCheckedContinuation { continuation in
            self.speechContinuation = continuation
            self.synthesizer.speak(utterance)
        }
    }

    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        speechContinuation?.resume()
        speechContinuation = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        speechContinuation?.resume()
        speechContinuation = nil
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        speechContinuation?.resume()
        speechContinuation = nil
    }
}
