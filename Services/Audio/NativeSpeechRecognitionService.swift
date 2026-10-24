import Foundation
import Speech
import AVFoundation
import OSLog

private let speechLogger = Logger(subsystem: "com.voco.app", category: "SpeechRecognition")

/// Native Speech-to-Text service utilizing Apple's Speech Framework (SFSpeechRecognizer) and AVAudioEngine
public final class NativeSpeechRecognitionService: NSObject, SpeechRecognitionServiceProtocol, SFSpeechRecognizerDelegate, @unchecked Sendable {
    public private(set) var isListening: Bool = false
    public private(set) var isAuthorized: Bool = false
    public private(set) var currentLocaleIdentifier: String = "en-IN"

    #if os(iOS)
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isIntentionalStop: Bool = false
    #endif

    public init(localeIdentifier: String = "en-IN") {
        super.init()
        self.currentLocaleIdentifier = localeIdentifier
        #if os(iOS)
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        recognizer?.delegate = self
        self.speechRecognizer = recognizer

        let speechAuth = SFSpeechRecognizer.authorizationStatus() == .authorized
        let micAuth: Bool
        if #available(iOS 17.0, *) {
            micAuth = AVAudioApplication.shared.recordPermission == .granted
        } else {
            micAuth = AVAudioSession.sharedInstance().recordPermission == .granted
        }
        self.isAuthorized = speechAuth && micAuth
        speechLogger.info("[NativeSpeechRecognitionService] Initialized with locale: \(localeIdentifier). speechAuth: \(speechAuth), micAuth: \(micAuth)")
        #else
        self.isAuthorized = true
        #endif
    }

    /// Sets or updates the active locale used for speech recognition dynamically
    public func setLocale(_ localeIdentifier: String) {
        self.currentLocaleIdentifier = localeIdentifier
        #if os(iOS)
        let newLocale = Locale(identifier: localeIdentifier)
        let recognizer = SFSpeechRecognizer(locale: newLocale)
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        recognizer?.delegate = self
        self.speechRecognizer = recognizer
        speechLogger.info("[NativeSpeechRecognitionService] Switched speech recognition locale to \(localeIdentifier)")
        #endif
    }

    public func requestAuthorization() async -> Bool {
        #if os(iOS)
        // 1. Fast path: check if already fully authorized
        let currentSpeechStatus = SFSpeechRecognizer.authorizationStatus()
        let currentMicStatus: Bool
        if #available(iOS 17.0, *) {
            currentMicStatus = AVAudioApplication.shared.recordPermission == .granted
        } else {
            currentMicStatus = AVAudioSession.sharedInstance().recordPermission == .granted
        }

        if currentSpeechStatus == .authorized && currentMicStatus {
            self.isAuthorized = true
            return true
        }

        // 2. Request Speech Recognition Authorization if needed
        let speechGranted: Bool
        if currentSpeechStatus == .authorized {
            speechGranted = true
        } else if currentSpeechStatus == .denied || currentSpeechStatus == .restricted {
            speechGranted = false
        } else {
            speechGranted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        }

        // 3. Request Microphone Access if needed
        let micGranted: Bool
        if currentMicStatus {
            micGranted = true
        } else {
            if #available(iOS 17.0, *) {
                micGranted = await AVAudioApplication.requestRecordPermission()
            } else {
                micGranted = await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            }
        }

        let totalAuth = speechGranted && micGranted
        self.isAuthorized = totalAuth
        speechLogger.info("[NativeSpeechRecognitionService] Authorization result: speech=\(speechGranted), mic=\(micGranted), total=\(totalAuth)")
        return totalAuth
        #else
        self.isAuthorized = true
        return true
        #endif
    }

    public func startListening(
        onTranscription: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) async throws {
        #if os(iOS)
        guard isAuthorized else {
            let authSuccess = await requestAuthorization()
            guard authSuccess else {
                speechLogger.error("[NativeSpeechRecognitionService] Authorization failed or denied")
                throw NSError(
                    domain: "com.voco.app.speech",
                    code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "Microphone and speech recognition permissions are required. Please enable them in iPhone Settings > VoCo."]
                )
            }
            return
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            speechLogger.error("[NativeSpeechRecognitionService] SFSpeechRecognizer is unavailable for locale \(self.currentLocaleIdentifier)")
            throw NSError(
                domain: "com.voco.app.speech",
                code: 503,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognition service is currently unavailable for \(self.currentLocaleIdentifier). Check device settings or try another language."]
            )
        }

        if isListening {
            stopListening()
        }

        isIntentionalStop = false

        // Configure Audio Session for Recording
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            throw NSError(domain: "com.voco.app.speech", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unable to create speech recognition request."])
        }

        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = false
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0 else {
            speechLogger.error("[NativeSpeechRecognitionService] Invalid audio input hardware sample rate")
            throw NSError(domain: "com.voco.app.speech", code: 501, userInfo: [NSLocalizedDescriptionKey: "Audio hardware is not ready."])
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcription = result.bestTranscription.formattedString
                onTranscription(transcription)
            }

            if let error = error {
                let nsError = error as NSError
                // Ignore intentional cancellations or stop requests
                let isCancelled = self.isIntentionalStop ||
                    (nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 216 || nsError.code == 203)) ||
                    (nsError.domain == "kLSRErrorDomain" && (nsError.code == 301 || nsError.code == 102))

                if isCancelled {
                    speechLogger.debug("[NativeSpeechRecognitionService] Ignored expected cancellation: \(nsError.code)")
                } else {
                    speechLogger.error("[NativeSpeechRecognitionService] Recognition error: \(error.localizedDescription) (Code: \(nsError.code))")
                    onError(error)
                }
                self.stopListening()
            }
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
        speechLogger.info("[NativeSpeechRecognitionService] Started listening with locale: \(self.currentLocaleIdentifier)")
        #else
        isListening = true
        #endif
    }

    public func stopListening() {
        #if os(iOS)
        isIntentionalStop = true
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.reset()
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        #endif
        isListening = false
        speechLogger.info("[NativeSpeechRecognitionService] Stopped listening")
    }

    // MARK: - SFSpeechRecognizerDelegate

    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        speechLogger.info("[NativeSpeechRecognitionService] SFSpeechRecognizer availability changed: \(available)")
        if !available && isListening {
            stopListening()
        }
    }
}
