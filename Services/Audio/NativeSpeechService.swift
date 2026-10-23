import Foundation
import AVFoundation

/// Native Text-to-Speech service using Apple AVFoundation AVSpeechSynthesizer.
/// Replaces Flutter's flutter_tts plugin without external dependencies.
public final class NativeSpeechService: NSObject, SpeechServiceProtocol, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    public private(set) var isSpeaking: Bool = false

    private var speechContinuation: CheckedContinuation<Void, Never>?

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func speak(
        text: String,
        language: String = "en-US",
        pitchMultiplier: Float = 1.0,
        rate: Float = 0.5
    ) async {
        // Ensure any previous utterance is stopped
        stopSpeaking()

        #if os(iOS)
        // Configure audio session for playback on iOS
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("[NativeSpeechService] Failed to configure audio session: \(error)")
        }
        #endif

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice(language: "en-US")
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
