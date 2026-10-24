import Foundation

/// Represents the top-level root screen presentation
public enum AppRootScreen: Equatable, Hashable {
    case splash
    case authWelcome
    case signIn
    case signUp
    case userProfile
    case dashboard
}

/// Represents push destinations in the app navigation hierarchy
public enum AppDestination: Equatable, Hashable {
    case pronunciationRecord
    case pronunciationReview
    case talkWithVoCo
    case talkBot
    case voCoGyan
    case technicalCourses(CourseCategory)
    case dsaEpisodes(CourseTopic)
    case episodeDetail(CourseEpisode)
    case gamesHub
    case stories
    case storyDetail(Story)
    case quiz
    case comingSoon(String)

    public var title: String {
        switch self {
        case .pronunciationRecord: return "Pronunciation Practice"
        case .pronunciationReview: return "Pronunciation Review"
        case .talkWithVoCo: return "Talk with VoCo"
        case .talkBot: return "VoCo Bot"
        case .voCoGyan: return "VoCo Gyan"
        case .technicalCourses(let cat): return cat.rawValue
        case .dsaEpisodes(let topic): return topic.title
        case .episodeDetail(let ep): return ep.title
        case .gamesHub: return "Games & Challenges"
        case .stories: return "Story Catalog"
        case .storyDetail(let story): return story.title
        case .quiz: return "Interactive Quiz"
        case .comingSoon(let feature): return feature
        }
    }
}

/// Result of evaluating a voice command against current app navigation state
public enum NavigationTransitionResult: Equatable {
    case navigated(destination: AppDestination, spokenFeedback: String)
    case rootChanged(root: AppRootScreen, spokenFeedback: String)
    case wentBack(toDestination: AppDestination?, root: AppRootScreen, spokenFeedback: String)
    case actionExecuted(actionName: String, spokenFeedback: String)
    case rejected(reason: String, spokenFeedback: String)
    case unhandled(reason: String, spokenFeedback: String)

    public var spokenFeedback: String {
        switch self {
        case .navigated(_, let spoken),
             .rootChanged(_, let spoken),
             .wentBack(_, _, let spoken),
             .actionExecuted(_, let spoken),
             .rejected(_, let spoken),
             .unhandled(_, let spoken):
            return spoken
        }
    }
}

/// Pure state machine coordinating navigation rules, authentication guards, and voice feedback
@MainActor
public final class AppNavigationStateMachine: ObservableObject {
    @Published public private(set) var currentRoot: AppRootScreen
    @Published public private(set) var navigationStack: [AppDestination] = []
    @Published public var isAuthenticated: Bool

    /// Announcement history for repeats and VoiceOver status
    public private(set) var lastSpokenAnnouncement: String = ""

    public init(initialRoot: AppRootScreen = .splash, isAuthenticated: Bool = false) {
        self.currentRoot = initialRoot
        self.isAuthenticated = isAuthenticated
    }

    public func setRoot(_ root: AppRootScreen) {
        self.currentRoot = root
        if root != .dashboard {
            navigationStack.removeAll()
        }
    }

    public func push(_ destination: AppDestination) {
        if navigationStack.last != destination {
            navigationStack.append(destination)
        }
    }

    public func pop() {
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
        }
    }

    public func popToRoot() {
        navigationStack.removeAll()
    }

    // MARK: - Intent Evaluation & State Transition

    /// Evaluates a voice command against the current view stack and returns the navigation or action result
    public func process(intent: VoiceCommandIntent) -> NavigationTransitionResult {
        switch intent {
        // MARK: Global Navigation
        case .goHome:
            return handleGoHome()

        case .goBack:
            return handleGoBack()

        case .signOut:
            return handleSignOut()

        // MARK: Authentication & Profile Navigation
        case .openLogin:
            if isAuthenticated {
                let feedback = "You are already signed in."
                recordAnnouncement(feedback)
                return .rejected(reason: "Already authenticated", spokenFeedback: feedback)
            }
            currentRoot = .signIn
            let feedback = "Opening Sign In."
            recordAnnouncement(feedback)
            return .rootChanged(root: .signIn, spokenFeedback: feedback)

        case .openSignUp:
            if isAuthenticated {
                let feedback = "You are already signed in."
                recordAnnouncement(feedback)
                return .rejected(reason: "Already authenticated", spokenFeedback: feedback)
            }
            currentRoot = .signUp
            let feedback = "Opening Sign Up."
            recordAnnouncement(feedback)
            return .rootChanged(root: .signUp, spokenFeedback: feedback)

        case .openUserProfile:
            guard isAuthenticated else {
                let feedback = "Please sign in before viewing your profile."
                recordAnnouncement(feedback)
                return .rejected(reason: "Authentication required", spokenFeedback: feedback)
            }
            currentRoot = .userProfile
            let feedback = "Opening User Profile."
            recordAnnouncement(feedback)
            return .rootChanged(root: .userProfile, spokenFeedback: feedback)

        // MARK: Learning Module Navigation
        case .openPronunciation:
            return navigateToProtectedDestination(.pronunciationRecord, announcement: "Opening Pronunciation Guide.")

        case .openTalkWithVoCo:
            return navigateToProtectedDestination(.talkWithVoCo, announcement: "Opening Talk with VoCo.")

        case .openVoCoGyan:
            return navigateToProtectedDestination(.voCoGyan, announcement: "Opening VoCo Gyan lessons.")

        case .openTechnicalCourses:
            return navigateToProtectedDestination(.technicalCourses(.technical), announcement: "Opening Technical Courses.")

        case .openNonTechnicalCourses:
            return navigateToProtectedDestination(.technicalCourses(.nonTechnical), announcement: "Opening Non-Technical Courses.")

        case .openEpisode(let number):
            guard isAuthenticated else {
                let feedback = "Please sign in before opening courses."
                recordAnnouncement(feedback)
                return .rejected(reason: "Authentication required", spokenFeedback: feedback)
            }
            if let topic = CourseTopic.standardTopics.first(where: { $0.id == "topic-dsa" }),
               let ep = topic.episodes.first(where: { $0.episodeNumber == number }) {
                return navigateToProtectedDestination(.episodeDetail(ep), announcement: "Opening Episode \(number): \(ep.title).")
            }
            return navigateToProtectedDestination(.voCoGyan, announcement: "Opening VoCo Gyan.")

        case .openEpisodeByTitle(let title):
            guard isAuthenticated else {
                let feedback = "Please sign in before opening courses."
                recordAnnouncement(feedback)
                return .rejected(reason: "Authentication required", spokenFeedback: feedback)
            }
            let lower = title.lowercased()
            for topic in CourseTopic.standardTopics {
                if let ep = topic.episodes.first(where: { $0.title.lowercased().contains(lower) }) {
                    return navigateToProtectedDestination(.episodeDetail(ep), announcement: "Opening \(ep.title).")
                }
            }
            return navigateToProtectedDestination(.voCoGyan, announcement: "Opening VoCo Gyan.")

        case .openCourseTopic(let topicId):
            guard isAuthenticated else {
                let feedback = "Please sign in before opening courses."
                recordAnnouncement(feedback)
                return .rejected(reason: "Authentication required", spokenFeedback: feedback)
            }
            if let topic = CourseTopic.standardTopics.first(where: { $0.id == topicId || $0.id.localizedCaseInsensitiveContains(topicId) }) {
                if navigationStack.last != .dsaEpisodes(topic) {
                    push(.dsaEpisodes(topic))
                }
                let feedback = "Opening \(topic.title)."
                recordAnnouncement(feedback)
                return .navigated(destination: .dsaEpisodes(topic), spokenFeedback: feedback)
            }
            return navigateToProtectedDestination(.voCoGyan, announcement: "Opening VoCo Gyan lessons.")

        case .openGames:
            return navigateToProtectedDestination(.gamesHub, announcement: "Opening Games and Challenges.")

        case .openStories:
            return navigateToProtectedDestination(.stories, announcement: "Opening Story Catalog.")

        case .readStory(let identifier):
            return handleReadStory(identifier: identifier)

        case .openQuiz:
            return navigateToProtectedDestination(.quiz, announcement: "Starting VoCo Quiz.")

        // MARK: Quiz Actions (Context-guarded)
        case .answerTrue:
            return handleQuizAction(actionName: "AnswerTrue", announcement: "Selected True.")

        case .answerFalse:
            return handleQuizAction(actionName: "AnswerFalse", announcement: "Selected False.")

        case .selectQuizOption(let index):
            return handleQuizAction(actionName: "SelectOption\(index)", announcement: "Selected Option \(index).")

        case .nextQuestion:
            return handleQuizAction(actionName: "NextQuestion", announcement: "Advancing to next question.")

        // MARK: Pronunciation Recording Actions (Context-guarded)
        case .startRecording:
            return handlePronunciationAction(actionName: "StartRecording", announcement: "Recording started. Speak now.")

        case .stopRecording:
            if navigationStack.last == .pronunciationRecord {
                navigationStack.append(.pronunciationReview)
            }
            return handlePronunciationAction(actionName: "StopRecording", announcement: "Recording stopped.")

        case .reRecord:
            if navigationStack.last == .pronunciationReview {
                navigationStack.removeLast()
            }
            return handlePronunciationAction(actionName: "ReRecord", announcement: "Ready to re-record.")

        case .nextSentence:
            return handlePronunciationAction(actionName: "NextSentence", announcement: "Moving to next sentence.")

        case .listenToVoCo:
            return handlePronunciationAction(actionName: "ListenToVoCo", announcement: "Playing native pronunciation.")

        // MARK: Hands-Free & Privacy Actions
        case .pauseListening:
            let feedback = "Voice listening paused. Tap Resume to continue."
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "PauseListening", spokenFeedback: feedback)

        case .resumeListening:
            let feedback = "Voice listening resumed."
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "ResumeListening", spokenFeedback: feedback)

        case .toggleHandsFree:
            let feedback = "Hands-free voice mode toggled."
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "ToggleHandsFree", spokenFeedback: feedback)

        case .switchLanguage(let localeCode):
            if let lang = AppLanguage.standardLanguages.first(where: { $0.id == localeCode || $0.id.hasPrefix(localeCode) }) {
                LanguageManager.shared.setLanguage(lang)
                let feedback = LanguageManager.shared.localizedAnnouncementForSwitch(to: lang)
                recordAnnouncement(feedback)
                return .actionExecuted(actionName: "SwitchLanguage_\(lang.id)", spokenFeedback: feedback)
            }
            let feedback = LanguageManager.shared.localizedUnsupportedFeedback(for: localeCode)
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "UnsupportedLanguage", spokenFeedback: feedback)

        case .unsupportedLanguage(let requested):
            let feedback = LanguageManager.shared.localizedUnsupportedFeedback(for: requested)
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "UnsupportedLanguage", spokenFeedback: feedback)

        case .acknowledgeOK:
            let feedback = "OK."
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "AcknowledgeOK", spokenFeedback: feedback)

        case .continueAction:
            let feedback = "Continuing."
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "Continue", spokenFeedback: feedback)

        case .clarificationNeeded(let prompt, _):
            recordAnnouncement(prompt)
            return .actionExecuted(actionName: "ClarificationNeeded", spokenFeedback: prompt)

        // MARK: General & Utility
        case .repeatSpoken:
            let announcement = lastSpokenAnnouncement.isEmpty ? "No recent announcement to repeat." : lastSpokenAnnouncement
            return .actionExecuted(actionName: "Repeat", spokenFeedback: announcement)

        case .cancel:
            return handleCancel()

        case .readProgress:
            let feedback = "Current progress: 5 quiz questions, 5 pronunciation sentences available."
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "ReadProgress", spokenFeedback: feedback)

        case .help:
            let feedback = contextualHelpText()
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "Help", spokenFeedback: feedback)

        case .helpWithTopic(let topic):
            let feedback = topicHelpText(for: topic)
            recordAnnouncement(feedback)
            return .actionExecuted(actionName: "HelpTopic", spokenFeedback: feedback)

        case .unknown(let query):
            let feedback = "Command '\(query)' not recognized. Say 'help' for available commands."
            recordAnnouncement(feedback)
            return .unhandled(reason: "Unrecognized command", spokenFeedback: feedback)
        }
    }

    private func contextualHelpText() -> String {
        if let current = navigationStack.last {
            switch current {
            case .pronunciationRecord:
                return "In Pronunciation, say 'listen to voco', 'start recording', 'stop recording', or 'go back'."
            case .pronunciationReview:
                return "In Review, say 're-record', 'next sentence', 'listen to voco', or 'go back'."
            case .quiz:
                return "In the Quiz, say 'true', 'false', 'next question', or 'cancel'."
            case .stories:
                return "In Stories, say 'read story 1' through 'read story 4', or 'go back'."
            case .storyDetail:
                return "In Story Reader, say 'take quiz' or 'go back'."
            case .gamesHub:
                return "In Games, say 'open stories', 'start quiz', or 'go back'."
            case .voCoGyan, .technicalCourses, .dsaEpisodes, .episodeDetail:
                return "In VoCo Gyan, you can explore lessons, say 'take quiz', or 'go back'."
            case .talkWithVoCo, .talkBot:
                return "In Talk with VoCo, speak freely or say 'go back' to return to the dashboard."
            case .comingSoon:
                return "Say 'go back' or 'cancel' to return."
            }
        }

        switch currentRoot {
        case .authWelcome:
            return "Say 'open sign in', 'open sign up', or use your biometric login."
        case .signIn:
            return "Say 'spell email', or tap password to type securely. Say 'cancel' to return."
        case .signUp:
            return "Enter your email and type your password securely. Say 'cancel' to return."
        case .userProfile:
            return "Fill in your profile details or tap save. Say 'cancel' to return."
        case .dashboard:
            return "Available voice commands: Dashboard, Pronunciation, Gyan, Games, Stories, Quiz, Go Back, Repeat, Cancel, or Log Out."
        case .splash:
            return "Loading VoCo..."
        }
    }

    private func topicHelpText(for topic: String) -> String {
        switch topic.lowercased() {
        case "pronunciation", "pronounce", "speech":
            return "Help for pronunciation: Say 'listen to voco' to hear the phrase, then 'start recording' to practice."
        case "quiz", "questions", "test":
            return "Help for quiz: Say 'true' or 'false' to submit answers, and 'next question' to continue."
        case "stories", "story":
            return "Help for stories: Say 'read story 1' through 'read story 4' to open and listen to stories."
        case "auth", "login", "password", "security":
            return "Help for security: Passwords must be typed securely or entered with biometrics. Passwords cannot be spoken."
        case "voice", "hands free", "mic":
            return "Help for voice: Say 'pause listening' to pause, 'resume listening' to resume, or toggle hands-free on the voice bar."
        default:
            return "Help for \(topic): You can say Go Back or ask for general commands."
        }
    }

    // MARK: - State Machine Handlers

    private func handleGoHome() -> NavigationTransitionResult {
        if currentRoot == .dashboard {
            if navigationStack.isEmpty {
                let feedback = "You are already on the home dashboard."
                recordAnnouncement(feedback)
                return .rejected(reason: "Already on dashboard", spokenFeedback: feedback)
            } else {
                navigationStack.removeAll()
                let feedback = "Returning to Dashboard."
                recordAnnouncement(feedback)
                return .rootChanged(root: .dashboard, spokenFeedback: feedback)
            }
        } else if isAuthenticated {
            currentRoot = .dashboard
            navigationStack.removeAll()
            let feedback = "Returning to Dashboard."
            recordAnnouncement(feedback)
            return .rootChanged(root: .dashboard, spokenFeedback: feedback)
        } else {
            let feedback = "Please sign in to access your dashboard."
            recordAnnouncement(feedback)
            return .rejected(reason: "Authentication required", spokenFeedback: feedback)
        }
    }

    private func handleGoBack() -> NavigationTransitionResult {
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
            let destination = navigationStack.last
            let feedback = "Going back."
            recordAnnouncement(feedback)
            return .wentBack(toDestination: destination, root: currentRoot, spokenFeedback: feedback)
        } else if currentRoot == .signIn || currentRoot == .signUp || currentRoot == .userProfile {
            currentRoot = .authWelcome
            let feedback = "Returning to welcome screen."
            recordAnnouncement(feedback)
            return .rootChanged(root: .authWelcome, spokenFeedback: feedback)
        } else if currentRoot == .dashboard {
            let feedback = "You are already on the home dashboard."
            recordAnnouncement(feedback)
            return .rejected(reason: "At root dashboard", spokenFeedback: feedback)
        } else {
            let feedback = "Cannot go back from this screen."
            recordAnnouncement(feedback)
            return .rejected(reason: "Cannot go back", spokenFeedback: feedback)
        }
    }

    private func handleSignOut() -> NavigationTransitionResult {
        isAuthenticated = false
        currentRoot = .authWelcome
        navigationStack.removeAll()
        let feedback = "Signing out. Goodbye."
        recordAnnouncement(feedback)
        return .rootChanged(root: .authWelcome, spokenFeedback: feedback)
    }

    private func navigateToProtectedDestination(_ destination: AppDestination, announcement: String) -> NavigationTransitionResult {
        guard isAuthenticated && (currentRoot == .dashboard || currentRoot == .userProfile) else {
            let feedback = "Please sign in before opening \(destination.title)."
            recordAnnouncement(feedback)
            return .rejected(reason: "Authentication required", spokenFeedback: feedback)
        }

        // Avoid pushing identical destination if already at top of stack
        if navigationStack.last == destination {
            let feedback = "You are already in \(destination.title)."
            recordAnnouncement(feedback)
            return .rejected(reason: "Already in destination", spokenFeedback: feedback)
        }

        navigationStack.append(destination)
        recordAnnouncement(announcement)
        return .navigated(destination: destination, spokenFeedback: announcement)
    }

    private func handleReadStory(identifier: String?) -> NavigationTransitionResult {
        guard isAuthenticated && currentRoot == .dashboard else {
            let feedback = "Please sign in before opening stories."
            recordAnnouncement(feedback)
            return .rejected(reason: "Authentication required", spokenFeedback: feedback)
        }

        let stories = Story.standardStories
        var targetStory: Story?

        if let identifier = identifier {
            if let index = Int(identifier), index >= 1, index <= stories.count {
                targetStory = stories[index - 1]
            } else {
                targetStory = stories.first(where: {
                    $0.title.lowercased().contains(identifier.lowercased())
                })
            }
        } else {
            // Default to first story if no parameter specified
            targetStory = stories.first
        }

        guard let selectedStory = targetStory else {
            let feedback = "Could not find story: \(identifier ?? "")."
            recordAnnouncement(feedback)
            return .rejected(reason: "Story not found", spokenFeedback: feedback)
        }

        navigationStack.append(.storyDetail(selectedStory))
        let feedback = "Opening story: \(selectedStory.title)."
        recordAnnouncement(feedback)
        return .navigated(destination: .storyDetail(selectedStory), spokenFeedback: feedback)
    }

    private func handleQuizAction(actionName: String, announcement: String) -> NavigationTransitionResult {
        guard navigationStack.last == .quiz else {
            let feedback = "Quiz actions are only available while taking a quiz."
            recordAnnouncement(feedback)
            return .rejected(reason: "Not in quiz", spokenFeedback: feedback)
        }
        recordAnnouncement(announcement)
        return .actionExecuted(actionName: actionName, spokenFeedback: announcement)
    }

    private func handlePronunciationAction(actionName: String, announcement: String) -> NavigationTransitionResult {
        guard navigationStack.last == .pronunciationRecord || navigationStack.last == .pronunciationReview else {
            let feedback = "Recording controls are only available in the Pronunciation Guide."
            recordAnnouncement(feedback)
            return .rejected(reason: "Not in pronunciation", spokenFeedback: feedback)
        }
        recordAnnouncement(announcement)
        return .actionExecuted(actionName: actionName, spokenFeedback: announcement)
    }

    private func handleCancel() -> NavigationTransitionResult {
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
            let feedback = "Cancelled."
            recordAnnouncement(feedback)
            return .wentBack(toDestination: navigationStack.last, root: currentRoot, spokenFeedback: feedback)
        } else if currentRoot == .signIn || currentRoot == .signUp {
            currentRoot = .authWelcome
            let feedback = "Cancelled."
            recordAnnouncement(feedback)
            return .rootChanged(root: .authWelcome, spokenFeedback: feedback)
        } else {
            let feedback = "Nothing to cancel."
            recordAnnouncement(feedback)
            return .rejected(reason: "Nothing to cancel", spokenFeedback: feedback)
        }
    }

    private func recordAnnouncement(_ text: String) {
        lastSpokenAnnouncement = text
    }
}
