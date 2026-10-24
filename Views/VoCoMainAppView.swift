import SwiftUI
import AVFoundation

/// Main container and root coordinator for VoCoNative
public struct VoCoMainAppView: View {
    public typealias RootScreen = AppRootScreen
    public typealias Destination = AppDestination

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var container: ServiceContainer
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var pronunciationViewModel: PronunciationViewModel
    @StateObject private var quizViewModel: QuizViewModel
    @StateObject private var voiceCommandViewModel: VoiceCommandViewModel
    @StateObject private var navigationStateMachine: AppNavigationStateMachine
    @StateObject private var guidanceCoordinator: VoiceGuidanceCoordinator

    @State private var currentRoot: RootScreen = .splash
    @State private var navigationPath = NavigationPath()

    public init(container: ServiceContainer = .mock()) {
        let authVM = AuthViewModel(
            authService: container.authService,
            biometricService: container.biometricService,
            tokenStore: container.tokenStore
        )
        let pronVM = PronunciationViewModel(
            sentenceService: container.sentenceService,
            speechService: container.speechService,
            audioRecorder: container.audioRecorder,
            audioPlayer: container.audioPlayer
        )
        let quizVM = QuizViewModel()
        let voiceVM = VoiceCommandViewModel(
            speechRecognizer: container.speechRecognizer,
            speechService: container.speechService
        )
        let navSM = AppNavigationStateMachine(
            initialRoot: .splash,
            isAuthenticated: authVM.isAuthenticated
        )
        let guidanceCoord = VoiceGuidanceCoordinator(
            speechService: container.speechService,
            isMockBackend: container.isMockBackend
        )

        _container = StateObject(wrappedValue: container)
        _authViewModel = StateObject(wrappedValue: authVM)
        _pronunciationViewModel = StateObject(wrappedValue: pronVM)
        _quizViewModel = StateObject(wrappedValue: quizVM)
        _voiceCommandViewModel = StateObject(wrappedValue: voiceVM)
        _navigationStateMachine = StateObject(wrappedValue: navSM)
        _guidanceCoordinator = StateObject(wrappedValue: guidanceCoord)
        LanguageManager.shared.applyLanguage(to: container)
    }

    public var body: some View {
        Group {
            if currentRoot == .splash {
                SplashScreenView {
                    withAnimation {
                        if authViewModel.isAuthenticated {
                            currentRoot = .dashboard
                            navigationStateMachine.setRoot(.dashboard)
                        } else {
                            currentRoot = .authWelcome
                            navigationStateMachine.setRoot(.authWelcome)
                        }
                    }
                }
            } else {
                VStack(spacing: 0) {
                    rootContentView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Persistent Voice Navigation Bar for hands-free audio control across all screens
                    VoiceCommandBarView(viewModel: voiceCommandViewModel) { intent in
                        handleVoiceCommand(intent)
                    }
                }
            }
        }
        .onAppear {
            LanguageManager.shared.applyLanguage(to: container)
            guidanceCoordinator.onSpeakGuidance = { [weak voiceCommandViewModel] text in
                if let voiceVM = voiceCommandViewModel {
                    await voiceVM.speakUtterance(text)
                } else {
                    await container.speechService.speak(text: text)
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                voiceCommandViewModel.handleAppDidEnterBackground()
            case .active:
                voiceCommandViewModel.handleAppWillEnterForeground()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            if type == .began {
                voiceCommandViewModel.handleAudioInterruption(began: true, shouldResume: false)
            } else if type == .ended {
                let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                voiceCommandViewModel.handleAudioInterruption(began: false, shouldResume: options.contains(.shouldResume))
            }
        }
        #endif
    }

    @ViewBuilder
    private var rootContentView: some View {
        switch currentRoot {
        case .splash:
            EmptyView()

        case .authWelcome:
            NavigationStack {
                LoginHomeView(
                    viewModel: authViewModel,
                    onNavigateToSignIn: {
                        currentRoot = .signIn
                        navigationStateMachine.setRoot(.signIn)
                    },
                    onNavigateToSignUp: {
                        currentRoot = .signUp
                        navigationStateMachine.setRoot(.signUp)
                    },
                    onBiometricSignInCompleted: {
                        withAnimation {
                            currentRoot = .dashboard
                            navigationStateMachine.setRoot(.dashboard)
                        }
                    }
                )
                .task {
                    await guidanceCoordinator.provideLaunchOnboarding()
                }
            }

        case .signIn:
            NavigationStack {
                SignInView(
                    viewModel: authViewModel,
                    onNavigateToSignUp: {
                        currentRoot = .signUp
                        navigationStateMachine.setRoot(.signUp)
                    },
                    onSignInCompleted: {
                        withAnimation {
                            currentRoot = .dashboard
                            navigationStateMachine.setRoot(.dashboard)
                        }
                    }
                )
                .task {
                    await guidanceCoordinator.provideScreenGuidance(root: .signIn, destination: nil)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            currentRoot = .authWelcome
                            navigationStateMachine.setRoot(.authWelcome)
                        }
                    }
                }
            }

        case .signUp:
            NavigationStack {
                SignUpView(
                    viewModel: authViewModel,
                    onNavigateToSignIn: {
                        currentRoot = .signIn
                        navigationStateMachine.setRoot(.signIn)
                    },
                    onSignUpCompleted: {
                        withAnimation {
                            currentRoot = .userProfile
                            navigationStateMachine.setRoot(.userProfile)
                        }
                    }
                )
                .task {
                    await guidanceCoordinator.provideScreenGuidance(root: .signUp, destination: nil)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            currentRoot = .authWelcome
                            navigationStateMachine.setRoot(.authWelcome)
                        }
                    }
                }
            }

        case .userProfile:
            NavigationStack {
                UserProfileFormView { _ in
                    withAnimation {
                        currentRoot = .dashboard
                        navigationStateMachine.setRoot(.dashboard)
                    }
                }
                .task {
                    await guidanceCoordinator.provideScreenGuidance(root: .userProfile, destination: nil)
                }
            }

        case .dashboard:
            NavigationStack(path: $navigationPath) {
                HomeDashboardView(
                    container: container,
                    authViewModel: authViewModel,
                    onSelectPronunciation: {
                        navigationStateMachine.push(.pronunciationRecord)
                        navigationPath.append(Destination.pronunciationRecord)
                    },
                    onSelectTalkWithVoCo: {
                        navigationStateMachine.push(.talkWithVoCo)
                        navigationPath.append(Destination.talkWithVoCo)
                    },
                    onSelectVoCoGyan: {
                        navigationStateMachine.push(.voCoGyan)
                        navigationPath.append(Destination.voCoGyan)
                    },
                    onSelectGames: {
                        navigationStateMachine.push(.gamesHub)
                        navigationPath.append(Destination.gamesHub)
                    },
                    onSignOut: {
                        Task {
                            await authViewModel.signOut()
                            navigationStateMachine.setRoot(.authWelcome)
                            navigationStateMachine.isAuthenticated = false
                            navigationPath = NavigationPath()
                            withAnimation {
                                currentRoot = .authWelcome
                            }
                        }
                    }
                )
                .task {
                    if navigationPath.isEmpty {
                        await guidanceCoordinator.provideScreenGuidance(root: .dashboard, destination: nil)
                    }
                }
                .navigationDestination(for: Destination.self) { destination in
                    destinationView(for: destination)
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .pronunciationRecord:
            PronunciationRecordView(
                viewModel: pronunciationViewModel,
                onProceedToReview: {
                    navigationStateMachine.push(.pronunciationReview)
                    navigationPath.append(Destination.pronunciationReview)
                },
                onBackToDashboard: {
                    navigationStateMachine.pop()
                    navigationPath.removeLast()
                }
            )

        case .pronunciationReview:
            PronunciationReviewView(
                viewModel: pronunciationViewModel,
                onReRecord: {
                    navigationStateMachine.pop()
                    navigationPath.removeLast()
                },
                onCompletedAllSentences: {
                    navigationStateMachine.popToRoot()
                    navigationPath = NavigationPath()
                }
            )

        case .talkWithVoCo:
            TalkWithVoCoHubView(
                onSelectBot: {
                    navigationStateMachine.push(.talkBot)
                    navigationPath.append(Destination.talkBot)
                },
                onSelectLocked: { feature in
                    navigationStateMachine.push(.comingSoon(feature))
                    navigationPath.append(Destination.comingSoon(feature))
                }
            )

        case .talkBot:
            VoCoBotConversationView(container: container)

        case .voCoGyan:
            VoCoGyanHubView { category in
                navigationStateMachine.push(.technicalCourses(category))
                navigationPath.append(Destination.technicalCourses(category))
            }

        case .technicalCourses(let category):
            TechnicalCoursesView(category: category) { topic in
                navigationStateMachine.push(.dsaEpisodes(topic))
                navigationPath.append(Destination.dsaEpisodes(topic))
            }

        case .dsaEpisodes(let topic):
            DSAEpisodesView(topic: topic, container: container) { episode in
                navigationStateMachine.push(.episodeDetail(episode))
                navigationPath.append(Destination.episodeDetail(episode))
            }

        case .episodeDetail(let episode):
            EpisodeDetailView(
                episode: episode,
                container: container,
                onTakeQuiz: {
                    quizViewModel.resetQuiz()
                    navigationStateMachine.push(.quiz)
                    navigationPath.append(Destination.quiz)
                }
            )

        case .gamesHub:
            GamesHubView(
                onSelectStories: {
                    navigationStateMachine.push(.stories)
                    navigationPath.append(Destination.stories)
                },
                onSelectQuiz: {
                    quizViewModel.resetQuiz()
                    navigationStateMachine.push(.quiz)
                    navigationPath.append(Destination.quiz)
                }
            )

        case .stories:
            StoryCatalogView { story in
                navigationStateMachine.push(.storyDetail(story))
                navigationPath.append(Destination.storyDetail(story))
            }

        case .storyDetail(let story):
            StoryReaderView(
                story: story,
                container: container,
                onTakeQuiz: {
                    quizViewModel.resetQuiz()
                    navigationStateMachine.push(.quiz)
                    navigationPath.append(Destination.quiz)
                }
            )

        case .quiz:
            InteractiveQuizView(viewModel: quizViewModel, container: container) {
                navigationStateMachine.popToRoot()
                navigationPath = NavigationPath()
            }

        case .comingSoon(let feature):
            ComingSoonView(title: feature) {
                navigationStateMachine.pop()
                navigationPath.removeLast()
            }
        }
    }

    private func handleVoiceCommand(_ intent: VoiceCommandIntent) {
        navigationStateMachine.isAuthenticated = authViewModel.isAuthenticated
        let result = navigationStateMachine.process(intent: intent)

        switch result {
        case .navigated(let destination, _):
            navigationPath.append(destination)
            if destination == .quiz {
                quizViewModel.resetQuiz()
            }
            Task {
                await guidanceCoordinator.provideScreenGuidance(root: currentRoot, destination: destination)
            }

        case .rootChanged(let root, _):
            withAnimation {
                currentRoot = root
            }
            navigationPath = NavigationPath()
            if root == .authWelcome && intent == .signOut {
                Task {
                    await authViewModel.signOut()
                    await voiceCommandViewModel.speakUtterance("You have been signed out successfully.")
                }
            } else {
                Task {
                    await guidanceCoordinator.provideScreenGuidance(root: root, destination: nil)
                }
            }

        case .wentBack(_, let root, _):
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
            if currentRoot != root {
                currentRoot = root
            }
            Task {
                await guidanceCoordinator.provideScreenGuidance(root: currentRoot, destination: navigationStateMachine.navigationStack.last)
            }

        case .actionExecuted(let actionName, let spokenFeedback):
            switch actionName {
            case "AcknowledgeOK":
                Task { await voiceCommandViewModel.speakUtterance("OK.") }
            case "Continue":
                Task { await voiceCommandViewModel.speakUtterance("Continuing.") }
            case "PauseListening":
                Task { await voiceCommandViewModel.pauseListening() }
            case "ResumeListening":
                Task { await voiceCommandViewModel.resumeListening() }
            case "ToggleHandsFree":
                Task { await voiceCommandViewModel.toggleHandsFreeMode() }
            case "StartRecording":
                Task {
                    await voiceCommandViewModel.speakUtterance("Recording started. Please speak now.")
                    await pronunciationViewModel.startRecording()
                }
            case "StopRecording":
                Task {
                    await pronunciationViewModel.stopRecording()
                    if pronunciationViewModel.recordedAudioURL != nil {
                        navigationPath.append(Destination.pronunciationReview)
                        await voiceCommandViewModel.speakUtterance("Recording saved. You can listen, re-record, or move to the next sentence.")
                    }
                }
            case "ReRecord":
                pronunciationViewModel.resetForCurrentSentence()
                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
                Task {
                    await voiceCommandViewModel.speakUtterance("Ready to re-record. Speak when ready.")
                }
            case "NextSentence":
                if pronunciationViewModel.moveToNextSentence() {
                    if !navigationPath.isEmpty {
                        navigationPath.removeLast()
                    }
                    if let currentS = pronunciationViewModel.currentSentence {
                        let feedback = "Sentence \(pronunciationViewModel.currentIndex + 1): \(currentS.text)"
                        Task { await voiceCommandViewModel.speakUtterance(feedback) }
                    }
                } else {
                    navigationPath = NavigationPath()
                    navigationStateMachine.popToRoot()
                    Task {
                        await voiceCommandViewModel.speakUtterance("All pronunciation practice sentences completed! Returning to dashboard.")
                    }
                }
            case "ListenToVoCo":
                Task { await pronunciationViewModel.listenToVoCo() }
            case "AnswerTrue", "SelectOption1":
                if let q = quizViewModel.currentQuestion {
                    let isCorrect = q.correctAnswer == true
                    quizViewModel.answerCurrentQuestion(with: true)
                    let explanation = q.explanation ?? ""
                    let feedback = isCorrect ? "Correct! \(explanation)" : "Incorrect. \(explanation)"
                    Task { await voiceCommandViewModel.speakUtterance(feedback) }
                }
            case "AnswerFalse", "SelectOption2":
                if let q = quizViewModel.currentQuestion {
                    let isCorrect = q.correctAnswer == false
                    quizViewModel.answerCurrentQuestion(with: false)
                    let explanation = q.explanation ?? ""
                    let feedback = isCorrect ? "Correct! \(explanation)" : "Incorrect. \(explanation)"
                    Task { await voiceCommandViewModel.speakUtterance(feedback) }
                }
            case "SelectOption3", "SelectOption4":
                let feedback = "This quiz only has two options: True or False."
                Task { await voiceCommandViewModel.speakUtterance(feedback) }
            case "NextQuestion":
                quizViewModel.nextQuestion()
                if let nextQ = quizViewModel.currentQuestion {
                    let feedback = "Question \(quizViewModel.currentIndex + 1) of \(quizViewModel.questions.count): \(nextQ.prompt)"
                    Task { await voiceCommandViewModel.speakUtterance(feedback) }
                } else if quizViewModel.isQuizCompleted {
                    let feedback = "Quiz completed! You scored \(quizViewModel.score) out of \(quizViewModel.questions.count)."
                    Task { await voiceCommandViewModel.speakUtterance(feedback) }
                }
            case "Cancel":
                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
                Task {
                    await voiceCommandViewModel.speakUtterance("Action cancelled.")
                }
            case "ReadProgress":
                Task {
                    await guidanceCoordinator.announceProgress(
                        completedSentences: pronunciationViewModel.currentIndex,
                        totalSentences: pronunciationViewModel.sentences.count,
                        quizScore: quizViewModel.score,
                        totalQuestions: quizViewModel.questions.count
                    )
                }
            case "Repeat", "Help", "HelpTopic", "ClarificationNeeded":
                Task { await voiceCommandViewModel.speakUtterance(spokenFeedback) }
            case let act where act.starts(with: "SwitchLanguage"):
                LanguageManager.shared.applyLanguage(to: container)
            default:
                break
            }

        case .rejected(_, let spokenFeedback):
            Task { await voiceCommandViewModel.speakUtterance(spokenFeedback) }

        case .unhandled(_, let spokenFeedback):
            Task { await voiceCommandViewModel.speakUtterance(spokenFeedback) }
        }
    }
}
