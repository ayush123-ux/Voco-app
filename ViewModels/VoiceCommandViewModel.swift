import Foundation
import SwiftUI
import Combine
import AVFoundation

/// State representing the voice listening lifecycle and privacy status
public enum VoiceListeningState: Equatable {
    case idle
    case listening
    case processing
    case speaking
    case paused
    case error(String)

    public var statusDescription: String {
        switch self {
        case .idle: return "Idle"
        case .listening: return "Listening"
        case .processing: return "Processing"
        case .speaking: return "Speaking"
        case .paused: return "Paused"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .idle: return "Voice assistant idle. Tap microphone to speak."
        case .listening: return "Voice listening active. Speak your command now."
        case .processing: return "Evaluating recognized command."
        case .speaking: return "VoCo is speaking. Microphone paused."
        case .paused: return "Voice listening paused. Tap resume to continue."
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

    /// Trailing silence delay in seconds before auto-finalizing in hands-free mode
    public var silenceThreshold: TimeInterval = 1.4

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

    /// Explicitly enables or disables hands-free continuous listening
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

    /// User-initiated or voice-command pause
    public func pauseListening() async {
        isPaused = true
        cancelSilenceTask()
        cancelReArmTask()
        speechRecognizer.stopListening()
        updateListeningState(.paused)
        statusMessage = "Listening Paused"
        AccessibilityHelper.announce("Voice listening paused. Manual tap or resume button required to continue.")
    }

    /// Resumes listening after a pause
    public func resumeListening(onIntentRecognized: ((VoiceCommandIntent) -> Void)? = nil) async {
        if let onIntent = onIntentRecognized {
            self.onIntentCallback = onIntent
        }
        isPaused = false
        consecutiveErrors = 0
        statusMessage = "Listening Resumed"
        AccessibilityHelper.announce("Voice listening resumed.")
        await startListeningLoop()
    }

    /// Primary toggle button on voice bar
    public func toggleListening(onIntentRecognized: @escaping (VoiceCommandIntent) -> Void) async {
        self.onIntentCallback = onIntentRecognized
        if isListening {
            await stopListeningAndProcess(onIntentRecognized: onIntentRecognized)
        } else if isPaused {
            await resumeListening(onIntentRecognized: onIntentRecognized)
        } else {
            await startListening(onIntentRecognized: onIntentRecognized)
        }
    }

    // MARK: - Speech Recognition Lifecycle

    /// Starts streaming microphone audio with overlap guard
    public func startListening(onIntentRecognized: @escaping (VoiceCommandIntent) -> Void) async {
        self.onIntentCallback = onIntentRecognized
        await startListeningLoop()
    }

    private func startListeningLoop() async {
        // Prevent duplicate calls or listening during pause/speech/transition
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

        // Ensure TTS is stopped before opening microphone
        speechService.stopSpeaking()

        let authorized = await speechRecognizer.requestAuthorization()
        guard authorized else {
            consecutiveErrors += 1
            self.errorMessage = "Microphone or Speech Recognition permission was denied. Please enable in Settings."
            self.statusMessage = "Permission Denied"
            updateListeningState(.error("Permission Denied"))
            AccessibilityHelper.announce("Microphone or speech permission denied.")
            return
        }

        do {
            updateListeningState(.listening)
            self.statusMessage = isHandsFreeModeEnabled ? "Listening (Hands-Free)..." : "Listening... speak now"

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
        // Echo prevention: ignore input if currently in speaking state
        guard listeningState == .listening else { return }

        let cleanText = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        self.liveTranscription = cleanText
        self.statusMessage = "\"\(cleanText)\""

        // Reset silence detection debounce
        cancelSilenceTask()

        if isHandsFreeModeEnabled {
            silenceTask = Task { [weak self, threshold = silenceThreshold] in
                try? await Task.sleep(nanoseconds: UInt64(threshold * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await self?.autoFinalizeHandsFreeUtterance()
            }
        }
    }

    private func autoFinalizeHandsFreeUtterance() async {
        guard listeningState == .listening, !liveTranscription.isEmpty else { return }
        await stopListeningAndProcess(onIntentRecognized: onIntentCallback ?? { _ in })
    }

    private func handleRecognitionError(_ error: Error) {
        cancelSilenceTask()
        speechRecognizer.stopListening()
        consecutiveErrors += 1

        self.errorMessage = error.localizedDescription
        self.statusMessage = "Recognition Error"
        updateListeningState(.error(error.localizedDescription))

        // Backoff and safety check to avoid infinite rapid battery drain loops
        if consecutiveErrors >= maxConsecutiveErrors {
            isPaused = true
            statusMessage = "Voice paused after errors. Tap mic to retry."
            AccessibilityHelper.announce("Voice recognition encountered repeated errors. Listening has been paused.")
            return
        }

        // Safe retry after delay in hands-free mode if still active
        if isHandsFreeModeEnabled && !isPaused {
            scheduleSafeReArm(delayNanoseconds: UInt64(Double(consecutiveErrors) * 1_500_000_000))
        }
    }

    /// Stops listening and processes the utterance into structured intent
    public func stopListeningAndProcess(onIntentRecognized: @escaping (VoiceCommandIntent) -> Void) async {
        cancelSilenceTask()
        guard listeningState == .listening || isListening else { return }

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
        self.statusMessage = intent.spokenConfirmation

        // Handle internal privacy/hands-free commands directly
        switch intent {
        case .pauseListening:
            await pauseListening()
            await speakUtterance(intent.spokenConfirmation)
            onIntentRecognized(intent)
            return

        case .resumeListening:
            isPaused = false
            await speakUtterance(intent.spokenConfirmation)
            onIntentRecognized(intent)
            if isHandsFreeModeEnabled {
                scheduleSafeReArm(delayNanoseconds: 400_000_000)
            }
            return

        case .toggleHandsFree:
            isHandsFreeModeEnabled.toggle()
            let feedback = isHandsFreeModeEnabled ? "Hands-free voice mode enabled." : "Hands-free voice mode disabled."
            statusMessage = feedback
            await speakUtterance(feedback)
            onIntentRecognized(intent)
            if isHandsFreeModeEnabled && !isPaused {
                scheduleSafeReArm(delayNanoseconds: 400_000_000)
            }
            return

        default:
            break
        }

        // Speak confirmation with echo avoidance
        await speakUtterance(intent.spokenConfirmation)

        // Dispatch action to coordinator
        onIntentRecognized(intent)

        // Re-arm hands-free loop safely after speech finishes
        if isHandsFreeModeEnabled && !isPaused {
            scheduleSafeReArm(delayNanoseconds: 400_000_000)
        } else {
            updateListeningState(.idle)
        }
    }

    /// Plays spoken feedback while keeping the microphone off to prevent hearing itself
    public func speakUtterance(_ text: String) async {
        // Guarantee recognizer is stopped before audio output starts
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

    public func stopListening() async {
        cancelSilenceTask()
        cancelReArmTask()
        speechRecognizer.stopListening()
        updateListeningState(.idle)
        self.statusMessage = isHandsFreeModeEnabled ? "Hands-Free Paused" : "Tap to Speak"
    }

    /// Schedules an automatic re-arm after delay, ensuring no active speech or background state
    private func scheduleSafeReArm(delayNanoseconds: UInt64) {
        cancelReArmTask()
        guard isHandsFreeModeEnabled, !isPaused else { return }

        reArmTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else { return }
            guard let self = self, self.isHandsFreeModeEnabled, !self.isPaused else { return }
            await self.startListeningLoop()
        }
    }

    private func updateListeningState(_ state: VoiceListeningState) {
        self.listeningState = state
        self.isListening = (state == .listening)
    }

    private func cancelSilenceTask() {
        silenceTask?.cancel()
        silenceTask = nil
    }

    private func cancelReArmTask() {
        reArmTask?.cancel()
        reArmTask = nil
    }

    // MARK: - App Lifecycle & Audio Interruption Coordination

    public func handleAppDidEnterBackground() {
        cancelSilenceTask()
        cancelReArmTask()
        wasListeningBeforeBackground = isListening || (isHandsFreeModeEnabled && !isPaused)
        speechRecognizer.stopListening()
        speechService.stopSpeaking()
        updateListeningState(.paused)
        statusMessage = "Suspended in background"
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
            statusMessage = "Audio Interrupted"
        } else if shouldResume && isHandsFreeModeEnabled && !isPaused {
            scheduleSafeReArm(delayNanoseconds: 800_000_000)
        }
    }

    /// Directly dispatches an intent (e.g. for testing or accessibility shortcuts)
    public func dispatchDirectIntent(_ intent: VoiceCommandIntent, onExecute: (VoiceCommandIntent) -> Void) async {
        self.lastExecutedIntent = intent
        self.statusMessage = intent.spokenConfirmation
        await speakUtterance(intent.spokenConfirmation)
        onExecute(intent)
    }
}
