import Foundation
import Combine

/// Dependency Injection container providing services to SwiftUI Views and ViewModels
public final class ServiceContainer: ObservableObject, @unchecked Sendable {
    public let authService: AuthServiceProtocol
    public let biometricService: BiometricAuthServiceProtocol
    public let tokenStore: SecureTokenStoreProtocol
    public let sentenceService: SentenceServiceProtocol
    public let speechService: SpeechServiceProtocol
    public let speechRecognizer: SpeechRecognitionServiceProtocol
    public let audioRecorder: AudioRecordingServiceProtocol
    public let audioPlayer: AudioPlaybackServiceProtocol
    public let aiService: AIServiceProtocol

    public var isMockBackend: Bool {
        authService is MockAuthService
    }

    public init(
        authService: AuthServiceProtocol,
        biometricService: BiometricAuthServiceProtocol = NativeBiometricAuthService(),
        tokenStore: SecureTokenStoreProtocol = KeychainTokenStore(),
        sentenceService: SentenceServiceProtocol,
        speechService: SpeechServiceProtocol,
        speechRecognizer: SpeechRecognitionServiceProtocol = NativeSpeechRecognitionService(),
        audioRecorder: AudioRecordingServiceProtocol,
        audioPlayer: AudioPlaybackServiceProtocol,
        aiService: AIServiceProtocol = GeminiAIService()
    ) {
        self.authService = authService
        self.biometricService = biometricService
        self.tokenStore = tokenStore
        self.sentenceService = sentenceService
        self.speechService = speechService
        self.speechRecognizer = speechRecognizer
        self.audioRecorder = audioRecorder
        self.audioPlayer = audioPlayer
        self.aiService = aiService
    }

    /// Offline demo / local container ready for immediate previewing, local development, and on-device testing.
    public static func mock(
        preAuthenticated: Bool = false,
        speechRecognizer: SpeechRecognitionServiceProtocol = NativeSpeechRecognitionService(),
        aiService: AIServiceProtocol = MockAIService()
    ) -> ServiceContainer {
        let auth = MockAuthService(preAuthenticateWithEmail: preAuthenticated ? "learner@voco.app" : nil)
        let biometric = MockBiometricAuthService()
        let tokenStore = MockTokenStore()
        let sentences = MockSentenceService()
        let speech = NativeSpeechService()
        let recorder = NativeAudioRecorder()
        let player = NativeAudioPlayer()

        return ServiceContainer(
            authService: auth,
            biometricService: biometric,
            tokenStore: tokenStore,
            sentenceService: sentences,
            speechService: speech,
            speechRecognizer: speechRecognizer,
            audioRecorder: recorder,
            audioPlayer: player,
            aiService: aiService
        )
    }

    /// Production / Live service container
    public static func live(aiService: AIServiceProtocol = GeminiAIService()) -> ServiceContainer {
        let auth = FirebaseAuthService()
        let biometric = NativeBiometricAuthService()
        let tokenStore = KeychainTokenStore()
        let sentences = FirestoreSentenceService()
        let speech = NativeSpeechService()
        let recognizer = NativeSpeechRecognitionService()
        let recorder = NativeAudioRecorder()
        let player = NativeAudioPlayer()

        return ServiceContainer(
            authService: auth,
            biometricService: biometric,
            tokenStore: tokenStore,
            sentenceService: sentences,
            speechService: speech,
            speechRecognizer: recognizer,
            audioRecorder: recorder,
            audioPlayer: player,
            aiService: aiService
        )
    }
}
