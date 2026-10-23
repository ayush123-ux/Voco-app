import Foundation
import Combine

/// Centralized coordinator for contextual spoken guidance, onboarding, accessibility announcements,
/// and interactive audio feedback throughout the VoCo user journey.
public final class VoiceGuidanceCoordinator: ObservableObject, @unchecked Sendable {
    private let speechService: SpeechServiceProtocol
    public let isMockBackend: Bool

    /// Prevents repeated spoken onboarding on minor view re-renders
    public var hasSpokenOnboarding: Bool = false
    public private(set) var lastSpokenGuidance: String = ""

    public init(
        speechService: SpeechServiceProtocol,
        isMockBackend: Bool = false
    ) {
        self.speechService = speechService
        self.isMockBackend = isMockBackend
    }

    // MARK: - App Launch & Onboarding

    /// Spoken welcome and onboarding instructions provided on first launch
    /// Explains voice navigation, listening status indicators, and pause/resume controls.
    /// Never engages the microphone tap without explicit user permission/consent.
    @discardableResult
    public func provideLaunchOnboarding(force: Bool = false) async -> String? {
        guard !hasSpokenOnboarding || force else { return nil }
        hasSpokenOnboarding = true

        let message = "Welcome to VoCo, your voice-first fluency guide. You can navigate the entire app by speaking commands like 'open pronunciation', 'start quiz', or 'help' at any time. Look at the voice bar at the bottom for listening status. To pause listening, say 'pause listening' or tap pause. To begin, please sign in or create an account."
        await speak(message)
        return message
    }

    // MARK: - Screen-Specific Guidance

    /// Delivers contextual audio guidance when entering a root screen or navigated destination
    @discardableResult
    public func provideScreenGuidance(root: AppRootScreen, destination: AppDestination?) async -> String {
        let message: String

        if let destination = destination {
            switch destination {
            case .pronunciationRecord:
                message = "Pronunciation Practice. Listen to the target sentence or say 'start recording' when ready to practice."
            case .pronunciationReview:
                message = "Pronunciation Review. Listen to your recording, say 're-record' to try again, or say 'next sentence' to continue."
            case .quiz:
                message = "Interactive Quiz. Listen to each question prompt, then say 'True' or 'False' to answer."
            case .gamesHub:
                message = "Games and Challenges. Say 'open stories' to practice reading, or 'open quiz' to test your knowledge."
            case .stories:
                message = "Moral Story Catalog. Say 'read story 1' through 'read story 4' to explore a story."
            case .storyDetail(let story):
                message = "Reading '\(story.title)'. Listen to the audio narrative or say 'take quiz' to test your understanding."
            case .voCoGyan:
                message = "VoCo Gyan. Say 'open courses' to explore technical and non-technical lessons."
            case .technicalCourses(let category):
                message = "\(category.rawValue) Courses. Select a topic to view its episodes."
            case .dsaEpisodes(let topic):
                message = "\(topic.title). Select an episode to start your audio lesson."
            case .episodeDetail(let episode):
                message = "Episode \(episode.episodeNumber): \(episode.title). Listen to the lesson or say 'take quiz'."
            case .talkWithVoCo:
                message = "Talk with VoCo. Say 'start conversation' to chat with the VoCo bot."
            case .talkBot:
                message = "VoCo Bot Conversation. Speak naturally to chat. Say 'go back' or 'cancel' to exit."
            case .comingSoon(let name):
                message = "\(name) is currently under development. Say 'go back' to return."
            }
        } else {
            switch root {
            case .splash:
                message = ""
            case .authWelcome:
                message = "Welcome to VoCo. Say 'open sign in', 'open sign up', or use your device biometrics to log in."
            case .signIn:
                let backendNote = isMockBackend ? " Operating in offline demo mode." : ""
                message = "Sign In.\(backendNote) Say 'spell email' or type your email. For your security, passwords must be entered securely on screen or via biometrics and cannot be spoken."
            case .signUp:
                let backendNote = isMockBackend ? " Operating in offline demo mode." : ""
                message = "Create Account.\(backendNote) Enter your email and password to register. For security, passwords must be entered securely on screen."
            case .userProfile:
                message = "Profile Setup. Enter your name and target accent to complete your profile."
            case .dashboard:
                message = "Home Dashboard. Say 'open pronunciation', 'talk with voco', 'open courses', 'open games', 'read my progress', or 'sign out'."
            }
        }

        if !message.isEmpty {
            await speak(message)
        }
        return message
    }

    // MARK: - Contextual Help

    /// Returns available spoken commands depending on the user's current screen location
    public func provideContextualHelp(root: AppRootScreen, destination: AppDestination?) -> String {
        if let destination = destination {
            switch destination {
            case .pronunciationRecord:
                return "In Pronunciation, say 'listen to voco', 'start recording', 'stop recording', 'repeat', or 'go back'."
            case .pronunciationReview:
                return "In Review, say 're-record', 'next sentence', 'listen to voco', or 'go back'."
            case .quiz:
                return "In the Quiz, say 'true', 'false', 'next question', 'read progress', or 'cancel'."
            case .stories:
                return "In Stories, say 'read story 1' through 'read story 4', or 'go back'."
            case .storyDetail:
                return "In Story Reader, say 'take quiz', 'repeat', or 'go back'."
            case .gamesHub:
                return "In Games, say 'open stories', 'start quiz', or 'go back'."
            case .voCoGyan, .technicalCourses, .dsaEpisodes, .episodeDetail:
                return "In VoCo Gyan, you can select lessons, say 'take quiz', or 'go back'."
            case .talkWithVoCo, .talkBot:
                return "In Talk with VoCo, speak freely or say 'go back' to return to the dashboard."
            case .comingSoon:
                return "Say 'go back' or 'cancel' to return."
            }
        } else {
            switch root {
            case .authWelcome:
                return "Say 'open sign in', 'open sign up', or use your biometric login."
            case .signIn:
                return "Say 'spell email', or tap password to type securely. Say 'cancel' to return."
            case .signUp:
                return "Enter your email and type your password securely. Say 'cancel' to return."
            case .userProfile:
                return "Fill in your profile details or tap save. Say 'cancel' to return."
            case .dashboard:
                return "From Dashboard, say 'open pronunciation', 'talk with voco', 'open courses', 'open games', 'read my progress', or 'sign out'."
            case .splash:
                return "VoCo is starting..."
            }
        }
    }

    /// Provides in-depth help for a specific requested topic
    public func provideTopicHelp(_ topic: String) -> String {
        switch topic.lowercased() {
        case "pronunciation", "pronounce", "speech":
            return "Pronunciation Help: Listen to the target sentence, then speak clearly when recording. Say 'start recording' to begin, and 'stop recording' when done."
        case "quiz", "questions", "test":
            return "Quiz Help: Listen to the question prompt, then say 'True' or 'False'. Say 'next question' to proceed to the next item."
        case "stories", "story":
            return "Stories Help: Say 'read story' followed by a number 1 through 4 to open an inspiring narrative with audio narration."
        case "auth", "login", "password", "security":
            return "Security Policy: Passwords must be typed or authenticated with Face ID or Touch ID. VoCo never records, speaks, or logs passwords aloud."
        case "voice", "hands free", "controls", "mic":
            return "Voice Controls: Say 'pause listening' to pause, 'resume listening' to resume, or toggle hands-free mode on the bottom voice bar."
        default:
            return "Help for \(topic): You can say 'go back', ask for 'help', or speak screen commands."
        }
    }

    // MARK: - Status & Error Announcements

    /// Announces learning progress summary
    @discardableResult
    public func announceProgress(completedSentences: Int, totalSentences: Int, quizScore: Int, totalQuestions: Int) async -> String {
        let message = "Your progress: You have completed \(completedSentences) of \(totalSentences) pronunciation sentences, and scored \(quizScore) of \(totalQuestions) on the quiz."
        await speak(message)
        return message
    }

    /// Announces authentication errors clearly and securely
    @discardableResult
    public func announceAuthError(_ error: String) async -> String {
        let message = "Authentication error: \(error). Please check your credentials and try again."
        await speak(message)
        return message
    }

    /// Announces backend status (mock vs live)
    @discardableResult
    public func announceBackendNotice() async -> String {
        let message = isMockBackend
            ? "VoCo is currently running in offline demo mode with local mock services."
            : "VoCo is connected to live cloud services."
        await speak(message)
        return message
    }

    // MARK: - Speech Output Coordination

    /// Optional delegate to route speech through VoiceCommandViewModel for echo prevention and hands-free re-arming
    public var onSpeakGuidance: ((String) async -> Void)?

    private func speak(_ text: String) async {
        lastSpokenGuidance = text
        AccessibilityHelper.announce(text)
        if let onSpeak = onSpeakGuidance {
            await onSpeak(text)
        } else {
            await speechService.speak(text: text)
        }
    }
}
