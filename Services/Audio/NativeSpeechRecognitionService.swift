import Foundation
import Speech
import AVFoundation

/// Native Speech-to-Text service utilizing Apple's Speech Framework (SFSpeechRecognizer) and AVAudioEngine
public final class NativeSpeechRecognitionService: NSObject, SpeechRecognitionServiceProtocol, @unchecked Sendable {
    public private(set) var isListening: Bool = false
    public private(set) var isAuthorized: Bool = false

    #if os(iOS)
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    #endif

    public override init() {
        super.init()
        #if os(iOS)
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.isAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        #else
        self.isAuthorized = true
        #endif
    }

    public func requestAuthorization() async -> Bool {
        #if os(iOS)
        // 1. Request Speech Recognition Authorization
        let speechStatus: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            self.isAuthorized = false
            return false
        }

        // 2. Request Microphone Authorization
        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        self.isAuthorized = micGranted
        return micGranted
        #else
        self.isAuthorized = true
        return true
        #endif
    }

    public func startListening(
        onTranscription: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) async throws {
        stopListening()

        #if os(iOS)
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            let error = NSError(
                domain: "VoCoSpeechRecognition",
                code: 503,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognition service is temporarily unavailable."]
            )
            onError(error)
            throw error
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        self.isListening = true

        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                onTranscription(transcription)
            }

            if let error = error {
                self?.stopListening()
                onError(error)
            } else if result?.isFinal == true {
                self?.stopListening()
            }
        }
        #else
        // Fallback for non-iOS platforms
        self.isListening = true
        #endif
    }

    public func stopListening() {
        #if os(iOS)
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        #endif
        isListening = false
    }
}
