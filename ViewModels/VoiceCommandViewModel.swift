import Foundation
import SwiftUI
import Combine
import AVFoundation

/// State representing the coordinated voice listening lifecycle, accessibility, and privacy status
public enum VoiceListeningState: Equatable {
    case idle
    case speaking
    case listening
    case processing
    case awaitingAnswer
    case clarificationRequired(prompt: String)
    case paused
    case permissionRequired
    case error(String)

    public var statusDescription: String {
        switch self {
        case .idle: return "Idle"
        case .speaking: return "Speaking"
        case .listening: return "Listening"
        case .processing: return "Processing"
        case .awaitingAnswer: return "Awaiting Answer"
        case .clarificationRequired: return "Clarification Required"
        case .paused: return "Paused"
        case .permissionRequired: return "Permission Required"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .idle: return "Voice assistant idle. Tap microphone to speak."
        case .speaking: return "VoCo is speaking. Microphone paused."
        case .listening: return "Voice listening active. Speak your command now."
        case .processing: return "Evaluating recognized command."
        case .awaitingAnswer: return "Waiting for your answer. Speak now."
        case .clarificationRequired(let prompt): return "Clarification needed: \(prompt)"
        case .paused: return "Voice listening paused. Tap resume to continue."
        case .permissionRequired: return "Microphone or speech permission required. Enable in iOS Settings."
        case .error(let msg): return "Voice assistant error: \(msg)."
        }
    }
}

/// Manages hands-free speech recognition, continuous conversational loops, and privacy controls
@MainActor
public final class VoiceCommandViewModel: ObservableObject {
    @Published public private(set) var isListening: Bool = false
    @Published public private(set) var isHandsFreeModeEnabled: Bool = false
    @Published public private(set) var isPaused: Bool = false
    @Published public private(set) var listeningState: VoiceListeningState = .idle
    @Published public private(set) var liveTranscription: String = ""
    @Published public private(set) var lastExecutedIntent: VoiceCommandIntent?
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var statusMessage: String = "Tap to Speak"

    public let speechRecognizer: SpeechRecognitionServiceProtocol
    public let speechService: SpeechServiceProtocol
    public let parser: VoiceCommandParser

    // Hands-Free loop & audio coordination internals
    private var silenceTask: Task<Void, Never>?
    private var reArmTask: Task<Void, Never>?
    private var isTransitioningAudio: Bool = false
    private var wasListeningBeforeBackground: Bool = false
    private var consecutiveErrors: Int = 0
    private let maxConsecutiveErrors: Int = 3

    public var onIntentCallback: ((VoiceCommandIntent) -> Void)?

    /// Trailing silence delay in seconds before auto-finalizing utterances
    public var silenceThreshold: TimeInterval = 1.2

    public init(
        speechRecognizer: SpeechRecognitionServiceProtocol,
        speechService: SpeechServiceProtocol,
        parser: VoiceCommandParser = VoiceCommandParser(),
        enableHandsFreeByDefault: Bool = false
    ) {
        self.speechRecognizer = speechRecognizer
        self.speechService = speechService
        self.parser = parser
        self.isHandsFreeModeEnabled = enableHandsFreeByDefault
    }

    // MARK: - Hands-Free Mode & Privacy Controls

    public func setHandsFreeMode(enabled: Bool, onIntentRecognized: ((VoiceCommandIntent) -> Void)? = nil) async {
        if let onIntent = onIntentRecognized {
            self.onIntentCallback = onIntent
        }
        isHandsFreeModeEnabled = enabled
        if enabled {
            isPaused = false
            statusMessage = "Hands-Free Enabled"
            AccessibilityHelper.announce("Hands-free voice mode enabled.")
            await startListeningLoop()
        } else {
            await stopListening()
            statusMessage = "Hands-Free Disabled"
            AccessibilityHelper.announce("Hands-free voice mode disabled.")
        }
    }

    public func toggleHandsFreeMode(onIntentRecognized: ((VoiceCommandIntent) -> Void)? = nil) async {
        await setHandsFreeMode(enabled: !isHandsFreeModeEnabled, onIntentRecognized: onIntentRecognized)
    }

    public func pauseListening() async {
        isPaused = true
        cancelSilenceTask()
        cancelReArmTask()
        speechRecognizer.stopListening()
        updateListeningState(.paused)
        self.statusMessage = "Voice Paused"
        AccessibilityHelper.announce("Voice listening paused for privacy.")
    }

    public func resumeListening(onIntentRecognized: ((VoiceCommandIntent) -> Void)? = nil) async {
        if let onIntent = onIntentRecognized {
            self.onIntentCallback = onIntent
        }
        isPaused = false
        consecutiveErrors = 0
        self.statusMessage = "Resuming Voice..."
        AccessibilityHelper.announce("Voice listening resumed.")
        await startListeningLoop()
    }

    public func toggleListening(onIntentRecognized: @escaping (VoiceCommandIntent) -> Void) async {
        if isListening || listeningState == .listening {
            await stopListeningAndProcess(onIntentRecognized: onIntentRecognized)
        } else if isPaused {
            await resumeListening(onIntentRecognized: onIntentRecognized)
        } else {
            await startListening(onIntentRecognized: onIntentRecognized)
        }
    }

    // MARK: - Speech Recognition Lifecycle

    public func startListening(onIntentRecognized: @escaping (VoiceCommandIntent) -> Void) async {
        self.onIntentCallback = onIntentRecognized
        self.isPaused = false
        self.consecutiveErrors = 0
        await startListeningLoop()
    }

    private func startListeningLoop() async {
        guard !isTransitioningAudio else { return }
        guard !isListening else { return }
        guard !isPaused else {
            updateListeningState(.paused)
            return
        }
        guard !speechService.isSpeaking else { return }

        isTransitioningAudio = true
        defer { isTransitioningAudio = false }

        errorMessage = nil
        liveTranscription = ""

        // Ensure TTS is stopped before opening microphone to prevent audio feedback
        speechService.stopSpeaking()

        let authorized = await speechRecognizer.requestAuthorization()
        guard authorized else {
            consecutiveErrors += 1
            self.errorMessage = "Microphone or Speech Recognition permission was denied. Please enable in Settings."
            self.statusMessage = "Permission Denied: Enable in Settings"
            updateListeningState(.error("Permission Denied"))
            AccessibilityHelper.announce("Microphone or speech recognition permission was denied. Please enable in Settings.")
            return
        }

        do {
            updateListeningState(.listening)
            self.statusMessage = isHandsFreeModeEnabled ? "Listening (Hands-Free)..." : "Listening... speak now"
            AccessibilityHelper.playListeningStartCue()
            AccessibilityHelper.announce("I'm listening. You can speak now.")

            try await speechRecognizer.startListening { [weak self] transcription in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.handleIncomingTranscription(transcription)
                }
            } onError: { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.handleRecognitionError(error)
                }
            }
        } catch {
            handleRecognitionError(error)
        }
    }

    private func handleIncomingTranscription(_ transcription: String) {
        guard listeningState == .listening || listeningState == .awaitingAnswer else { return }

        let cleanText = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        self.liveTranscription = cleanText
        self.statusMessage = "\"\(cleanText)\""

        cancelSilenceTask()

        silenceTask = Task { [weak self, threshold = silenceThreshold] in
            try? await Task.sleep(nanoseconds: UInt64(threshold * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.autoFinalizeUtterance()
        }
    }

    private func autoFinalizeUtterance() async {
        guard (listeningState == .listening || listeningState == .awaitingAnswer), !liveTranscription.isEmpty else { return }
        await stopListeningAndProcess(onIntentRecognized: onIntentCallback ?? { _ in })
    }

    private func handleRecognitionError(_ error: Error) {
        cancelSilenceTask()
        speechRecognizer.stopListening()
        consecutiveErrors += 1

        self.errorMessage = error.localizedDescription
        self.statusMessage = "Recognition Error"
        updateListeningState(.error(error.localizedDescription))

        if consecutiveErrors >= maxConsecutiveErrors {
            isPaused = true
            statusMessage = "Voice paused after errors. Tap mic to retry."
            updateListeningState(.paused)
            let recoveryPrompt = "I didn't catch that. Say 'help' for available commands, or tap the microphone to try again."
            AccessibilityHelper.announce(recoveryPrompt)
            return
        }

        if isHandsFreeModeEnabled && !isPaused {
            scheduleSafeReArm(delayNanoseconds: UInt64(Double(consecutiveErrors) * 1_500_000_000))
        }
    }

    public func stopListeningAndProcess(onIntentRecognized: @escaping (VoiceCommandIntent) -> Void) async {
        cancelSilenceTask()
        guard listeningState == .listening || listeningState == .awaitingAnswer || isListening else { return }

        AccessibilityHelper.playListeningStopCue()
        speechRecognizer.stopListening()
        isListening = false
        updateListeningState(.processing)

        let phrase = liveTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phrase.isEmpty else {
            statusMessage = "No speech detected"
            updateListeningState(.idle)
            if isHandsFreeModeEnabled && !isPaused {
                scheduleSafeReArm(delayNanoseconds: 800_000_000)
            }
            return
        }

        consecutiveErrors = 0
        let intent = parser.parse(phrase: phrase)
        self.lastExecutedIntent = intent
        let currentLang = LanguageManager.shared.currentLanguage
        let feedback = intent.localizedSpokenConfirmation(for: currentLang)
        self.statusMessage = feedback

        switch intent {
        case .pauseListening:
            await pauseListening()
            await speakUtterance(feedback)
            onIntentRecognized(intent)
            return

        case .resumeListening:
            isPaused = false
            await speakUtterance(feedback)
            onIntentRecognized(intent)
            if isHandsFreeModeEnabled {
                scheduleSafeReArm(delayNanoseconds: 400_000_000)
            }
            return

        case .toggleHandsFree:
            isHandsFreeModeEnabled.toggle()
            let status = isHandsFreeModeEnabled ? "Hands-free voice mode enabled." : "Hands-free voice mode disabled."
            statusMessage = status
            await speakUtterance(status)
            onIntentRecognized(intent)
            if isHandsFreeModeEnabled && !isPaused {
                scheduleSafeReArm(delayNanoseconds: 400_000_000)
            }
            return

        case .switchLanguage(let localeCode):
            guard let targetLang = AppLanguage.standardLanguages.first(where: { $0.id == localeCode || $0.id.hasPrefix(localeCode) }) else {
                let err = LanguageManager.shared.localizedUnsupportedFeedback(for: localeCode)
                statusMessage = err
                await speakUtterance(err)
                if isHandsFreeModeEnabled && !isPaused {
                    scheduleSafeReArm(delayNanoseconds: 400_000_000)
                }
                return
            }

            // Apply new language to manager, speech recognizer, and speech synthesizer
            LanguageManager.shared.setLanguage(targetLang)
            speechRecognizer.setLocale(targetLang.verifiedSpeechLocaleIdentifier)
            speechService.defaultLanguage = targetLang.id

            let confirmation = LanguageManager.shared.localizedAnnouncementForSwitch(to: targetLang)
            statusMessage = confirmation
            await speakUtterance(confirmation)
            onIntentRecognized(intent)

            if isHandsFreeModeEnabled && !isPaused {
                scheduleSafeReArm(delayNanoseconds: 400_000_000)
            }
            return

        case .unsupportedLanguage(let requested):
            let err = LanguageManager.shared.localizedUnsupportedFeedback(for: requested)
            statusMessage = err
            await speakUtterance(err)
            if isHandsFreeModeEnabled && !isPaused {
                scheduleSafeReArm(delayNanoseconds: 400_000_000)
            }
            return

        default:
            break
        }

        await speakUtterance(feedback)
        onIntentRecognized(intent)

        if isHandsFreeModeEnabled && !isPaused {
            scheduleSafeReArm(delayNanoseconds: 400_000_000)
        } else {
            updateListeningState(.idle)
        }
    }

    public func speakUtterance(_ text: String) async {
        speechRecognizer.stopListening()
        updateListeningState(.speaking)
        AccessibilityHelper.announce(text)
        await speechService.speak(text: text)

        // Settle buffer to allow speaker audio to dissipate before re-arming
        try? await Task.sleep(nanoseconds: 300_000_000)

        if isHandsFreeModeEnabled && !isPaused {
            scheduleSafeReArm(delayNanoseconds: 100_000_000)
        } else {
            updateListeningState(.idle)
        }
    }

    public func dispatchDirectIntent(_ intent: VoiceCommandIntent, onExecute: (VoiceCommandIntent) -> Void) async {
        self.lastExecutedIntent = intent
        let currentLang = LanguageManager.shared.currentLanguage
        let feedback = intent.localizedSpokenConfirmation(for: currentLang)
        self.statusMessage = feedback
        await speakUtterance(feedback)
        onExecute(intent)
    }

    public func stopListening() async {
        cancelSilenceTask()
        cancelReArmTask()
        speechRecognizer.stopListening()
        isListening = false
        updateListeningState(.idle)
    }

    private func scheduleSafeReArm(delayNanoseconds: UInt64) {
        cancelReArmTask()
        reArmTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else { return }
            guard let self = self, self.isHandsFreeModeEnabled, !self.isPaused, !self.speechService.isSpeaking else { return }
            await self.startListeningLoop()
        }
    }

    private func cancelSilenceTask() {
        silenceTask?.cancel()
        silenceTask = nil
    }

    private func cancelReArmTask() {
        reArmTask?.cancel()
        reArmTask = nil
    }

    private func updateListeningState(_ newState: VoiceListeningState) {
        self.listeningState = newState
        self.isListening = (newState == .listening || newState == .awaitingAnswer)
    }

    // MARK: - Lifecycle & Audio Interruptions

    public func handleAppDidEnterBackground() {
        wasListeningBeforeBackground = isListening || isHandsFreeModeEnabled
        cancelSilenceTask()
        cancelReArmTask()
        speechRecognizer.stopListening()
        speechService.stopSpeaking()
        updateListeningState(.paused)
    }

    public func handleAppWillEnterForeground() {
        if wasListeningBeforeBackground && isHandsFreeModeEnabled && !isPaused {
            statusMessage = "Resuming hands-free..."
            scheduleSafeReArm(delayNanoseconds: 600_000_000)
        } else {
            updateListeningState(.idle)
            statusMessage = isHandsFreeModeEnabled ? "Hands-Free Ready" : "Tap to Speak"
        }
        wasListeningBeforeBackground = false
    }

    public func handleAudioInterruption(began: Bool, shouldResume: Bool) {
        if began {
            cancelSilenceTask()
            cancelReArmTask()
            speechRecognizer.stopListening()
            speechService.stopSpeaking()
            updateListeningState(.paused)
        } else if shouldResume && isHandsFreeModeEnabled && !isPaused {
            scheduleSafeReArm(delayNanoseconds: 800_000_000)
        }
    }
}
