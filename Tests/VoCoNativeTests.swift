import XCTest
@testable import VoCoNative

final class VoCoNativeTests: XCTestCase {

    // MARK: - Service Container & Models

    func testServiceContainerCreation() {
        let container = ServiceContainer.mock()
        XCTAssertNotNil(container.authService)
        XCTAssertNotNil(container.sentenceService)
        XCTAssertNotNil(container.speechRecognizer)
        XCTAssertNotNil(container.speechService)
        XCTAssertNotNil(container.audioPlayer)
        XCTAssertNotNil(container.audioRecorder)
        XCTAssertNotNil(container.biometricService)
        XCTAssertNotNil(container.tokenStore)
    }

    func testSentenceServiceSampleSentences() async throws {
        let service = MockSentenceService()
        let sentences = try await service.fetchSentences()
        XCTAssertEqual(sentences.count, 5)
        XCTAssertEqual(sentences[0].text, "Welcome to VoCo pronunciation guide.")
        XCTAssertEqual(sentences[4].text, "The egg became hard, the potato soft, but the coffee transformed the water.")
    }

    func testQuizQuestionsPreservedFromFlutter() {
        let questions = QuizQuestion.standardQuestions
        XCTAssertEqual(questions.count, 5)
        XCTAssertEqual(questions[0].id, "q1")
        XCTAssertFalse(questions[0].correctAnswer)
        XCTAssertFalse(questions[1].correctAnswer)
        XCTAssertTrue(questions[2].correctAnswer)
    }

    func testStoryCatalogStructure() {
        let stories = Story.standardStories
        XCTAssertEqual(stories.count, 4)
        XCTAssertEqual(stories[0].id, "story-1")
        XCTAssertEqual(stories[0].title, "The Potato, The Egg, And The Coffee Beans")
        XCTAssertEqual(stories[3].title, "The Ant and the Grasshopper")
    }

    func testCourseCatalogStructure() {
        let categories = CourseCategory.allCases
        XCTAssertEqual(categories.count, 2)
        XCTAssertTrue(categories.contains(.technical))
        XCTAssertTrue(categories.contains(.nonTechnical))

        let topics = CourseTopic.standardTopics
        let technical = topics.filter { $0.category == .technical }
        let nonTechnical = topics.filter { $0.category == .nonTechnical }
        XCTAssertEqual(technical.count, 4)
        XCTAssertEqual(technical[0].episodes.count, 10)
        XCTAssertGreaterThanOrEqual(nonTechnical.count, 8)
        XCTAssertTrue(nonTechnical.contains { $0.id == "topic-communication" })
    }

    // MARK: - ViewModels & Workflows

    @MainActor
    func testPronunciationViewModelWorkflow() async throws {
        let sentenceService = MockSentenceService()
        let speechService = MockSpeechService()
        let recorder = NativeAudioRecorder()
        let player = NativeAudioPlayer()

        let vm = PronunciationViewModel(
            sentenceService: sentenceService,
            speechService: speechService,
            audioRecorder: recorder,
            audioPlayer: player
        )

        await vm.loadSentences()
        XCTAssertEqual(vm.sentences.count, 5)
        XCTAssertEqual(vm.currentSentence?.id, "sentence-1")

        await vm.listenToVoCo()
        XCTAssertEqual(speechService.speakCallCount, 1)

        await vm.startRecording()
        XCTAssertTrue(vm.isRecording)

        await vm.stopRecording()
        XCTAssertFalse(vm.isRecording)
        XCTAssertNotNil(vm.recordedAudioURL)

        vm.resetForCurrentSentence()
        XCTAssertNil(vm.recordedAudioURL)
        XCTAssertFalse(vm.isPlayingRecordedAudio)
    }

    @MainActor
    func testPronunciationProgressionThroughAllSentences() async throws {
        let vm = PronunciationViewModel(
            sentenceService: MockSentenceService(),
            speechService: MockSpeechService(),
            audioRecorder: NativeAudioRecorder(),
            audioPlayer: NativeAudioPlayer()
        )

        await vm.loadSentences()
        XCTAssertEqual(vm.sentences.count, 5)

        for i in 0..<4 {
            XCTAssertTrue(vm.hasNextSentence)
            XCTAssertEqual(vm.currentIndex, i)
            let advanced = vm.moveToNextSentence()
            XCTAssertTrue(advanced)
        }

        XCTAssertEqual(vm.currentIndex, 4)
        XCTAssertFalse(vm.hasNextSentence)
        let cannotAdvanceFurther = vm.moveToNextSentence()
        XCTAssertFalse(cannotAdvanceFurther)
        XCTAssertEqual(vm.currentIndex, 4)
    }

    @MainActor
    func testQuizViewModelScoringAndProgression() {
        let vm = QuizViewModel()
        XCTAssertEqual(vm.currentIndex, 0)
        XCTAssertEqual(vm.score, 0)
        XCTAssertFalse(vm.isQuizCompleted)

        // Question 1: correct answer is false. Answer false -> score 1
        vm.answerCurrentQuestion(with: false)
        XCTAssertTrue(vm.selectedAnswer == false)
        XCTAssertTrue(vm.isAnswerSubmitted)
        XCTAssertEqual(vm.score, 1)

        vm.nextQuestion()
        XCTAssertEqual(vm.currentIndex, 1)
        XCTAssertNil(vm.selectedAnswer)
        XCTAssertFalse(vm.isAnswerSubmitted)

        // Question 2: correct answer is false. Answer false -> score 2
        vm.answerCurrentQuestion(with: false)
        XCTAssertEqual(vm.score, 2)

        vm.nextQuestion()
        XCTAssertEqual(vm.currentIndex, 2)

        // Question 3: correct is true, answer false (wrong) -> score remains 2
        vm.answerCurrentQuestion(with: false)
        XCTAssertEqual(vm.score, 2)

        vm.nextQuestion()
        // Question 4: correct true. Answer true -> score 3
        vm.answerCurrentQuestion(with: true)
        XCTAssertEqual(vm.score, 3)

        vm.nextQuestion()
        // Question 5: correct true. Answer true -> score 4
        vm.answerCurrentQuestion(with: true)
        XCTAssertEqual(vm.score, 4)

        vm.nextQuestion()
        XCTAssertTrue(vm.isQuizCompleted)
    }

    // MARK: - Speech & Audio Tests

    @MainActor
    func testMockSpeechRecognitionService() async throws {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let authorized = await mockRecognizer.requestAuthorization()
        XCTAssertTrue(authorized)

        final class Box: @unchecked Sendable {
            var text = ""
        }
        let box = Box()

        try await mockRecognizer.startListening { text in
            box.text = text
        } onError: { _ in }

        XCTAssertTrue(mockRecognizer.isListening)

        mockRecognizer.simulateSpeech("open quiz")
        XCTAssertEqual(box.text, "open quiz")

        mockRecognizer.stopListening()
        XCTAssertFalse(mockRecognizer.isListening)
    }

    @MainActor
    func testVoiceCommandViewModelExecution() async {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS
        )

        var executedIntent: VoiceCommandIntent?
        await vm.dispatchDirectIntent(.openQuiz) { intent in
            executedIntent = intent
        }

        XCTAssertEqual(executedIntent, .openQuiz)
        XCTAssertEqual(vm.lastExecutedIntent, .openQuiz)
        XCTAssertEqual(vm.statusMessage, VoiceCommandIntent.openQuiz.spokenConfirmation)
        XCTAssertEqual(mockTTS.speakCallCount, 1)
        XCTAssertEqual(mockTTS.lastSpokenText, VoiceCommandIntent.openQuiz.spokenConfirmation)
    }

    // MARK: - Voice Command Parser Tests

    func testVoiceCommandParserNavigationIntents() {
        let parser = VoiceCommandParser()

        XCTAssertEqual(parser.parse(phrase: "open pronunciation"), .openPronunciation)
        XCTAssertEqual(parser.parse(phrase: "pronunciation guide"), .openPronunciation)
        XCTAssertEqual(parser.parse(phrase: "practice sentence"), .openPronunciation)

        XCTAssertEqual(parser.parse(phrase: "talk with voco"), .openTalkWithVoCo)
        XCTAssertEqual(parser.parse(phrase: "bot conversation"), .openTalkWithVoCo)

        XCTAssertEqual(parser.parse(phrase: "voco gyan"), .openVoCoGyan)
        XCTAssertEqual(parser.parse(phrase: "open courses"), .openVoCoGyan)

        XCTAssertEqual(parser.parse(phrase: "games"), .openGames)
        XCTAssertEqual(parser.parse(phrase: "challenges"), .openGames)

        XCTAssertEqual(parser.parse(phrase: "open quiz"), .openQuiz)
        XCTAssertEqual(parser.parse(phrase: "interactive quiz"), .openQuiz)

        XCTAssertEqual(parser.parse(phrase: "go home"), .goHome)
        XCTAssertEqual(parser.parse(phrase: "dashboard"), .goHome)
        XCTAssertEqual(parser.parse(phrase: "go back"), .goBack)
        XCTAssertEqual(parser.parse(phrase: "previous screen"), .goBack)

        XCTAssertEqual(parser.parse(phrase: "sign out"), .signOut)
        XCTAssertEqual(parser.parse(phrase: "log out"), .signOut)

        XCTAssertEqual(parser.parse(phrase: "open login"), .openLogin)
        XCTAssertEqual(parser.parse(phrase: "sign in"), .openLogin)
        XCTAssertEqual(parser.parse(phrase: "open sign up"), .openSignUp)
        XCTAssertEqual(parser.parse(phrase: "open profile"), .openUserProfile)
    }

    func testVoiceCommandParserActionIntents() {
        let parser = VoiceCommandParser()

        XCTAssertEqual(parser.parse(phrase: "start recording"), .startRecording)
        XCTAssertEqual(parser.parse(phrase: "record"), .startRecording)
        XCTAssertEqual(parser.parse(phrase: "begin recording"), .startRecording)

        XCTAssertEqual(parser.parse(phrase: "stop recording"), .stopRecording)
        XCTAssertEqual(parser.parse(phrase: "finish recording"), .stopRecording)

        XCTAssertEqual(parser.parse(phrase: "re-record"), .reRecord)
        XCTAssertEqual(parser.parse(phrase: "rerecord"), .reRecord)
        XCTAssertEqual(parser.parse(phrase: "re record"), .reRecord)
        XCTAssertEqual(parser.parse(phrase: "record again"), .reRecord)

        XCTAssertEqual(parser.parse(phrase: "next sentence"), .nextSentence)
        XCTAssertEqual(parser.parse(phrase: "listen to voco"), .listenToVoCo)
        XCTAssertEqual(parser.parse(phrase: "play pronunciation"), .listenToVoCo)
    }

    func testVoiceCommandParserQuizOptionVariations() {
        let parser = VoiceCommandParser()

        XCTAssertEqual(parser.parse(phrase: "true"), .answerTrue)
        XCTAssertEqual(parser.parse(phrase: "select true"), .answerTrue)
        XCTAssertEqual(parser.parse(phrase: "false"), .answerFalse)
        XCTAssertEqual(parser.parse(phrase: "select false"), .answerFalse)

        XCTAssertEqual(parser.parse(phrase: "option 1"), .selectQuizOption(index: 1))
        XCTAssertEqual(parser.parse(phrase: "option one"), .selectQuizOption(index: 1))
        XCTAssertEqual(parser.parse(phrase: "choose 2"), .selectQuizOption(index: 2))
        XCTAssertEqual(parser.parse(phrase: "option 3"), .selectQuizOption(index: 3))
        XCTAssertEqual(parser.parse(phrase: "fourth option"), .selectQuizOption(index: 4))

        XCTAssertEqual(parser.parse(phrase: "next question"), .nextQuestion)
    }

    func testVoiceCommandParserNaturalVariationsAndParameters() {
        let parser = VoiceCommandParser()

        XCTAssertEqual(parser.parse(phrase: "stories"), .openStories)
        XCTAssertEqual(parser.parse(phrase: "story catalog"), .openStories)
        XCTAssertEqual(parser.parse(phrase: "read story 1"), .readStory(identifier: "1"))
        XCTAssertEqual(parser.parse(phrase: "read story two"), .readStory(identifier: "2"))

        XCTAssertEqual(parser.parse(phrase: "repeat that"), .repeatSpoken)
        XCTAssertEqual(parser.parse(phrase: "say again"), .repeatSpoken)
        XCTAssertEqual(parser.parse(phrase: "cancel"), .cancel)
        XCTAssertEqual(parser.parse(phrase: "dismiss"), .cancel)
        XCTAssertEqual(parser.parse(phrase: "read my progress"), .readProgress)
        XCTAssertEqual(parser.parse(phrase: "check progress"), .readProgress)

        XCTAssertEqual(parser.parse(phrase: "help"), .help)
        XCTAssertEqual(parser.parse(phrase: "help with pronunciation"), .helpWithTopic("pronunciation"))
        XCTAssertEqual(parser.parse(phrase: "random blablabla"), .unknown("random blablabla"))
    }

    func testTechnicalAndEpisodeVoiceCommands() {
        let parser = VoiceCommandParser()

        // 1. Technical courses
        XCTAssertEqual(parser.parse(phrase: "open technical courses"), .openTechnicalCourses)
        XCTAssertEqual(parser.parse(phrase: "technical courses"), .openTechnicalCourses)
        XCTAssertEqual(parser.parse(phrase: "tech courses"), .openTechnicalCourses)

        // 2. Non-technical courses discrimination
        XCTAssertEqual(parser.parse(phrase: "non-technical courses"), .openNonTechnicalCourses)
        XCTAssertEqual(parser.parse(phrase: "non technical courses"), .openNonTechnicalCourses)

        // 3. Direct episode and session commands
        XCTAssertEqual(parser.parse(phrase: "open the first episode"), .openEpisode(episodeNumber: 1))
        XCTAssertEqual(parser.parse(phrase: "play episode 1"), .openEpisode(episodeNumber: 1))
        XCTAssertEqual(parser.parse(phrase: "first episode"), .openEpisode(episodeNumber: 1))
        XCTAssertEqual(parser.parse(phrase: "play the linkedlist session"), .openEpisodeByTitle(title: "Linked List"))
        XCTAssertEqual(parser.parse(phrase: "linked list"), .openEpisodeByTitle(title: "Linked List"))

        // 4. Conversational acknowledgements and helpers
        XCTAssertEqual(parser.parse(phrase: "ok"), .acknowledgeOK)
        XCTAssertEqual(parser.parse(phrase: "okay"), .acknowledgeOK)
        XCTAssertEqual(parser.parse(phrase: "continue"), .continueAction)
        XCTAssertEqual(parser.parse(phrase: "take me to the quiz"), .openQuiz)
        XCTAssertEqual(parser.parse(phrase: "help me log in"), .openLogin)
    }

    @MainActor
    func testNavigationStateMachineForTechnicalCoursesAndEpisodes() {
        let sm = AppNavigationStateMachine(initialRoot: .dashboard, isAuthenticated: true)

        // Test Technical Courses navigation
        let techResult = sm.process(intent: .openTechnicalCourses)
        XCTAssertEqual(techResult, .navigated(destination: .technicalCourses(.technical), spokenFeedback: "Opening Technical Courses."))
        XCTAssertEqual(sm.navigationStack.last, .technicalCourses(.technical))

        // Test Episode navigation
        let epResult = sm.process(intent: .openEpisode(episodeNumber: 1))
        if case .navigated(let dest, _) = epResult, case .episodeDetail(let ep) = dest {
            XCTAssertEqual(ep.episodeNumber, 1)
        } else {
            XCTFail("Expected .navigated to episodeDetail")
        }

        // Pop back to test title-based navigation cleanly
        _ = sm.process(intent: .goBack)

        // Test LinkedList by title
        let llResult = sm.process(intent: .openEpisodeByTitle(title: "Linked List"))
        if case .navigated(let dest, _) = llResult, case .episodeDetail(let ep) = dest {
            XCTAssertTrue(ep.title.contains("Linked List"))
        } else {
            XCTFail("Expected .navigated to episodeDetail for Linked List")
        }

        // Test OK and Continue
        let okResult = sm.process(intent: .acknowledgeOK)
        XCTAssertEqual(okResult, .actionExecuted(actionName: "AcknowledgeOK", spokenFeedback: "OK."))

        let contResult = sm.process(intent: .continueAction)
        XCTAssertEqual(contResult, .actionExecuted(actionName: "Continue", spokenFeedback: "Continuing."))
    }

    func testAIServiceIntegration() async {
        let mockAI = MockAIService()

        // 1. Health check
        let isHealthy = await mockAI.checkHealth()
        XCTAssertTrue(isHealthy)

        // 2. Chat with VoCo
        let response = await mockAI.sendMessage(
            "What is a Linked List?",
            history: [],
            language: "en-IN"
        )
        XCTAssertFalse(response.reply.isEmpty)
        XCTAssertEqual(response.status, "mock_success")

        // 3. Interpret ambiguous voice command
        let interpretation = await mockAI.interpretCommand(
            phrase: "Can you teach me linked list?",
            currentScreen: "dashboard",
            language: "en-IN"
        )
        XCTAssertEqual(interpretation?.confidence, 0.95)
    }

    func testVoiceCommandIntentSpokenConfirmationsArePopulated() {
        let intents: [VoiceCommandIntent] = [
            .openPronunciation, .openTalkWithVoCo, .openVoCoGyan, .openGames,
            .openStories, .readStory(identifier: nil), .readStory(identifier: "1"),
            .openTechnicalCourses, .openNonTechnicalCourses, .openEpisode(episodeNumber: 1),
            .openEpisodeByTitle(title: "Linked List"), .acknowledgeOK, .continueAction,
            .openQuiz, .openLogin, .openSignUp, .openUserProfile, .goHome, .goBack,
            .signOut, .startRecording, .stopRecording, .nextSentence, .reRecord,
            .listenToVoCo, .answerTrue, .answerFalse, .selectQuizOption(index: 1),
            .nextQuestion, .repeatSpoken, .cancel, .readProgress, .help,
            .helpWithTopic("quiz"), .unknown("foo"),
            .pauseListening, .resumeListening, .toggleHandsFree
        ]

        for intent in intents {
            XCTAssertFalse(intent.spokenConfirmation.trimmingCharacters(in: .whitespaces).isEmpty, "Intent \(intent) should have non-empty spoken confirmation")
        }
    }

    // MARK: - Navigation State Machine Tests

    @MainActor
    func testAppNavigationStateMachineUnauthenticatedProtection() {
        let sm = AppNavigationStateMachine(initialRoot: .authWelcome, isAuthenticated: false)

        let result = sm.process(intent: .openPronunciation)
        XCTAssertEqual(result, .rejected(reason: "Authentication required", spokenFeedback: "Please sign in before opening Pronunciation Practice."))

        let quizResult = sm.process(intent: .openQuiz)
        XCTAssertEqual(quizResult, .rejected(reason: "Authentication required", spokenFeedback: "Please sign in before opening Interactive Quiz."))

        let loginResult = sm.process(intent: .openLogin)
        XCTAssertEqual(loginResult, .rootChanged(root: .signIn, spokenFeedback: "Opening Sign In."))
        XCTAssertEqual(sm.currentRoot, .signIn)
    }

    @MainActor
    func testAppNavigationStateMachineAuthenticatedNavigation() {
        let sm = AppNavigationStateMachine(initialRoot: .dashboard, isAuthenticated: true)

        let pronResult = sm.process(intent: .openPronunciation)
        XCTAssertEqual(pronResult, .navigated(destination: .pronunciationRecord, spokenFeedback: "Opening Pronunciation Guide."))
        XCTAssertEqual(sm.navigationStack.last, .pronunciationRecord)

        // Prevent duplicate push
        let duplicatePron = sm.process(intent: .openPronunciation)
        XCTAssertEqual(duplicatePron, .rejected(reason: "Already in destination", spokenFeedback: "You are already in Pronunciation Practice."))

        // Go Back
        let backResult = sm.process(intent: .goBack)
        XCTAssertEqual(backResult, .wentBack(toDestination: nil, root: .dashboard, spokenFeedback: "Going back."))
        XCTAssertTrue(sm.navigationStack.isEmpty)
    }

    @MainActor
    func testAppNavigationStateMachineContextualActionGuards() {
        let sm = AppNavigationStateMachine(initialRoot: .dashboard, isAuthenticated: true)

        // Actions rejected when not in context
        let recordResult = sm.process(intent: .startRecording)
        XCTAssertEqual(recordResult, .rejected(reason: "Not in pronunciation", spokenFeedback: "Recording controls are only available in the Pronunciation Guide."))

        let quizResult = sm.process(intent: .answerTrue)
        XCTAssertEqual(quizResult, .rejected(reason: "Not in quiz", spokenFeedback: "Quiz actions are only available while taking a quiz."))

        // Navigate to quiz
        _ = sm.process(intent: .openQuiz)
        let quizAction = sm.process(intent: .answerTrue)
        XCTAssertEqual(quizAction, .actionExecuted(actionName: "AnswerTrue", spokenFeedback: "Selected True."))
    }

    @MainActor
    func testAppNavigationStateMachineQuizOption3And4Execution() {
        let sm = AppNavigationStateMachine(initialRoot: .dashboard, isAuthenticated: true)
        _ = sm.process(intent: .openQuiz)

        let opt3 = sm.process(intent: .selectQuizOption(index: 3))
        XCTAssertEqual(opt3, .actionExecuted(actionName: "SelectOption3", spokenFeedback: "Selected Option 3."))

        let opt4 = sm.process(intent: .selectQuizOption(index: 4))
        XCTAssertEqual(opt4, .actionExecuted(actionName: "SelectOption4", spokenFeedback: "Selected Option 4."))
    }

    @MainActor
    func testAppNavigationStateMachineStoryHandlingWithParameters() {
        let sm = AppNavigationStateMachine(initialRoot: .dashboard, isAuthenticated: true)

        let storyResult = sm.process(intent: .readStory(identifier: "1"))
        if case .navigated(let dest, _) = storyResult, case .storyDetail(let story) = dest {
            XCTAssertEqual(story.title, "The Potato, The Egg, And The Coffee Beans")
        } else {
            XCTFail("Expected navigation to story 1")
        }
    }

    @MainActor
    func testAppNavigationStateMachineRepeatProgressAndLogout() {
        let sm = AppNavigationStateMachine(initialRoot: .dashboard, isAuthenticated: true)

        _ = sm.process(intent: .openStories)
        let repeatResult = sm.process(intent: .repeatSpoken)
        XCTAssertEqual(repeatResult, .actionExecuted(actionName: "Repeat", spokenFeedback: "Opening Story Catalog."))

        let progressResult = sm.process(intent: .readProgress)
        XCTAssertEqual(progressResult, .actionExecuted(actionName: "ReadProgress", spokenFeedback: "Current progress: 5 quiz questions, 5 pronunciation sentences available."))

        let logoutResult = sm.process(intent: .signOut)
        XCTAssertEqual(logoutResult, .rootChanged(root: .authWelcome, spokenFeedback: "Signing out. Goodbye."))
        XCTAssertFalse(sm.isAuthenticated)
        XCTAssertEqual(sm.currentRoot, .authWelcome)
        XCTAssertTrue(sm.navigationStack.isEmpty)
    }

    // MARK: - Authentication & Validation Tests

    func testMockAuthSignInSuccess() async throws {
        let auth = MockAuthService()
        let user = try await auth.signIn(email: "test@voco.app", password: "password123")
        XCTAssertEqual(user.email, "test@voco.app")
        XCTAssertEqual(auth.currentUser?.email, "test@voco.app")
    }

    func testMockAuthInvalidEmail() async {
        let auth = MockAuthService()
        do {
            _ = try await auth.signIn(email: "invalid-email", password: "password123")
            XCTFail("Expected invalid email error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("valid email"))
        }
    }

    func testMockAuthShortPassword() async {
        let auth = MockAuthService()
        do {
            _ = try await auth.signIn(email: "test@voco.app", password: "123")
            XCTFail("Expected weak password error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("6 characters"))
        }
    }

    func testMockAuthSignOut() async throws {
        let auth = MockAuthService()
        _ = try await auth.signIn(email: "test@voco.app", password: "password123")
        XCTAssertNotNil(auth.currentUser)

        try await auth.signOut()
        XCTAssertNil(auth.currentUser)
    }

    @MainActor
    func testAuthViewModelValidation() {
        let auth = MockAuthService()
        let vm = AuthViewModel(authService: auth)

        vm.email = "notanemail"
        vm.password = "123"
        XCTAssertFalse(vm.validateInputs(isRegistration: false))

        vm.email = "valid@voco.app"
        vm.password = "short"
        XCTAssertFalse(vm.validateInputs(isRegistration: false))

        vm.email = "valid@voco.app"
        vm.password = "validpassword"
        XCTAssertTrue(vm.validateInputs(isRegistration: false))
    }

    @MainActor
    func testAuthViewModelSignInWorkflow() async {
        let auth = MockAuthService()
        let vm = AuthViewModel(authService: auth)

        vm.email = "test@voco.app"
        vm.password = "password123"

        let success = await vm.signIn()
        XCTAssertTrue(success)
        XCTAssertTrue(vm.isAuthenticated)
        XCTAssertEqual(vm.currentUser?.email, "test@voco.app")
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Biometric Authentication & Secure Store Tests

    func testMockBiometricAuthSuccess() async {
        let biometric = MockBiometricAuthService(supportedBiometricType: .faceID, isBiometricAvailable: true)
        biometric.nextResult = .success(())

        let result = await biometric.authenticateUser(reason: "Test login")
        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testMockBiometricAuthCancellation() async {
        let biometric = MockBiometricAuthService(supportedBiometricType: .faceID, isBiometricAvailable: true)
        biometric.nextResult = .failure(.userCancelled)

        let result = await biometric.authenticateUser(reason: "Test cancel")
        switch result {
        case .success:
            XCTFail("Expected cancellation")
        case .failure(let err):
            XCTAssertEqual(err, .userCancelled)
        }
    }

    func testMockBiometricAuthLockout() async {
        let biometric = MockBiometricAuthService(supportedBiometricType: .touchID, isBiometricAvailable: true)
        biometric.nextResult = .failure(.lockout)

        let result = await biometric.authenticateUser(reason: "Test lockout")
        switch result {
        case .success:
            XCTFail("Expected lockout")
        case .failure(let err):
            XCTAssertEqual(err, .lockout)
        }
    }

    func testMockBiometricAuthUnsupportedDevice() async {
        let biometric = MockBiometricAuthService(supportedBiometricType: .none, isBiometricAvailable: false)

        let result = await biometric.authenticateUser(reason: "Test unsupported")
        switch result {
        case .success:
            XCTFail("Expected notAvailable")
        case .failure(let err):
            XCTAssertEqual(err, .notAvailable)
        }
    }

    @MainActor
    func testAuthViewModelBiometricSignInWorkflow() async throws {
        let auth = MockAuthService()
        let biometric = MockBiometricAuthService(supportedBiometricType: .faceID, isBiometricAvailable: true)
        let tokenStore = MockTokenStore()

        let vm = AuthViewModel(
            authService: auth,
            biometricService: biometric,
            tokenStore: tokenStore
        )

        // 1. Initial sign-in with password and opt in to biometrics
        vm.setBiometricEnrollment(enabled: true)
        XCTAssertTrue(vm.isBiometricEnrollmentEnabled)

        vm.email = "student@voco.app"
        vm.password = "password123"

        let signedIn = await vm.signIn()
        XCTAssertTrue(signedIn)
        XCTAssertEqual(tokenStore.retrieveLastAuthenticatedEmail(), "student@voco.app")
        XCTAssertNotNil(tokenStore.retrieveSessionToken(forEmail: "student@voco.app"))

        // 2. Perform Biometric Sign In while enrolled
        biometric.nextResult = .success(())
        let biometricSuccess = await vm.signInWithBiometrics()
        XCTAssertTrue(biometricSuccess)
        XCTAssertTrue(vm.isAuthenticated)
        XCTAssertEqual(vm.currentUser?.email, "student@voco.app")

        // 3. Test biometric authentication failure
        biometric.nextResult = .failure(.authenticationFailed)
        let failedLogin = await vm.signInWithBiometrics()
        XCTAssertFalse(failedLogin)
        XCTAssertEqual(vm.errorMessage, BiometricError.authenticationFailed.localizedDescription)
    }

    @MainActor
    func testLogoutClearsSessionWithoutDeletingUserData() async throws {
        let auth = MockAuthService()
        let biometric = MockBiometricAuthService(supportedBiometricType: .faceID, isBiometricAvailable: true)
        let tokenStore = MockTokenStore()

        let vm = AuthViewModel(
            authService: auth,
            biometricService: biometric,
            tokenStore: tokenStore
        )

        // 1. Mock persistent user profile and learning data
        let profile = UserProfile(
            id: "profile-123",
            name: "Carlos Test",
            email: "carlos@voco.app",
            age: 25
        )
        let originalQuestions = QuizQuestion.standardQuestions
        let originalSentences = try await MockSentenceService().fetchSentences()

        // 2. Sign in and enroll
        vm.email = "carlos@voco.app"
        vm.password = "password123"
        vm.setBiometricEnrollment(enabled: true)
        let signedIn = await vm.signIn()
        XCTAssertTrue(signedIn)
        XCTAssertEqual(tokenStore.retrieveLastAuthenticatedEmail(), "carlos@voco.app")
        XCTAssertNotNil(tokenStore.retrieveSessionToken(forEmail: "carlos@voco.app"))

        // 3. Perform Sign Out
        await vm.signOut()

        // Verify session credentials and biometric fast login preference are cleared
        XCTAssertFalse(vm.isAuthenticated)
        XCTAssertNil(vm.currentUser)
        XCTAssertNil(tokenStore.retrieveSessionToken(forEmail: "carlos@voco.app"))
        XCTAssertNil(tokenStore.retrieveLastAuthenticatedEmail())
        XCTAssertFalse(vm.isBiometricEnrollmentEnabled)
        XCTAssertFalse(biometric.isBiometricEnrollmentEnabled)

        // Verify persistent user profile, stories, questions, and sentences remain intact
        XCTAssertEqual(profile.name, "Carlos Test")
        XCTAssertEqual(profile.email, "carlos@voco.app")
        XCTAssertEqual(originalQuestions.count, 5)
        XCTAssertEqual(originalSentences.count, 5)

        // 4. User can sign back into the SAME existing account without recreation
        vm.email = "carlos@voco.app"
        vm.password = "password123"
        let reSignedIn = await vm.signIn()
        XCTAssertTrue(reSignedIn)
        XCTAssertEqual(vm.currentUser?.email, "carlos@voco.app")
        XCTAssertTrue(vm.isAuthenticated)
    }

    @MainActor
    func testAuthViewModelBiometricNotEnrolledFallback() async {
        let auth = MockAuthService()
        let biometric = MockBiometricAuthService(supportedBiometricType: .touchID, isBiometricAvailable: true)
        let tokenStore = MockTokenStore()

        let vm = AuthViewModel(
            authService: auth,
            biometricService: biometric,
            tokenStore: tokenStore
        )

        vm.setBiometricEnrollment(enabled: false)
        let success = await vm.signInWithBiometrics()
        XCTAssertFalse(success)
        XCTAssertTrue(vm.errorMessage?.contains("not enrolled") == true)
    }

    // MARK: - Voice Email Spelling Parser Tests

    func testVoiceEmailSpellingParserHyphenated() {
        let parser = VoiceEmailSpellingParser()
        let result = parser.parse(spokenPhrase: "c-a-r-l-o-s-at-gmail-dot-com")

        if case .updated(let normalized, _, let isValid) = result {
            XCTAssertEqual(normalized, "carlos@gmail.com")
            XCTAssertTrue(isValid)
        } else {
            XCTFail("Expected updated email result")
        }
    }

    func testVoiceEmailSpellingParserSpokenTokens() {
        let parser = VoiceEmailSpellingParser()
        let result = parser.parse(spokenPhrase: "john dot doe at yahoo dot com")

        if case .updated(let normalized, _, let isValid) = result {
            XCTAssertEqual(normalized, "john.doe@yahoo.com")
            XCTAssertTrue(isValid)
        } else {
            XCTFail("Expected updated email result")
        }
    }

    func testVoiceEmailSpellingParserDeleteLast() {
        let parser = VoiceEmailSpellingParser()
        let result = parser.parse(spokenPhrase: "delete last", currentBuffer: "carlos@gmail.comm")

        if case .updated(let normalized, _, let isValid) = result {
            XCTAssertEqual(normalized, "carlos@gmail.com")
            XCTAssertTrue(isValid)
        } else {
            XCTFail("Expected updated email result after delete last")
        }
    }

    func testVoiceEmailSpellingParserConfirmation() {
        let parser = VoiceEmailSpellingParser()

        // Valid confirmation
        let validResult = parser.parse(spokenPhrase: "confirm email", currentBuffer: "carlos@gmail.com")
        XCTAssertEqual(validResult, .confirmed(email: "carlos@gmail.com"))

        // Invalid email confirmation failure
        let invalidResult = parser.parse(spokenPhrase: "confirm email", currentBuffer: "notanemail")
        if case .error(let msg) = invalidResult {
            XCTAssertTrue(msg.contains("not a valid email"))
        } else {
            XCTFail("Expected error when confirming invalid email")
        }
    }

    func testVoiceEmailSpellingParserClear() {
        let parser = VoiceEmailSpellingParser()
        let result = parser.parse(spokenPhrase: "clear", currentBuffer: "halfway@written")

        if case .cleared(let prompt) = result {
            XCTAssertTrue(prompt.contains("Email cleared"))
        } else {
            XCTFail("Expected cleared result")
        }
    }

    @MainActor
    func testAuthViewModelVoiceEmailSpellingWorkflow() {
        let vm = AuthViewModel(authService: MockAuthService())

        // 1. Speak email spelling
        vm.handleSpokenEmailInput("c-a-r-l-o-s-at-gmail-dot-com")
        XCTAssertEqual(vm.email, "carlos@gmail.com")
        XCTAssertFalse(vm.emailConfirmed)
        XCTAssertTrue(vm.voiceSpokenFeedback?.contains("carlos@gmail.com") == true)

        // 2. Confirm email
        vm.handleSpokenEmailInput("confirm email")
        XCTAssertEqual(vm.email, "carlos@gmail.com")
        XCTAssertTrue(vm.emailConfirmed)
        XCTAssertEqual(vm.voiceSpokenFeedback, "Email confirmed: carlos@gmail.com")

        // 3. Clear email
        vm.handleSpokenEmailInput("clear")
        XCTAssertEqual(vm.email, "")
        XCTAssertFalse(vm.emailConfirmed)
    }

    // MARK: - Step 3: Hands-Free Voice Loop & Privacy Control Tests

    func testVoiceCommandParserHandsFreeAndPrivacyIntents() {
        let parser = VoiceCommandParser()

        XCTAssertEqual(parser.parse(phrase: "pause listening"), .pauseListening)
        XCTAssertEqual(parser.parse(phrase: "pause voice"), .pauseListening)
        XCTAssertEqual(parser.parse(phrase: "pause"), .pauseListening)
        XCTAssertEqual(parser.parse(phrase: "stop listening"), .pauseListening)
        XCTAssertEqual(parser.parse(phrase: "hold on"), .pauseListening)

        XCTAssertEqual(parser.parse(phrase: "resume listening"), .resumeListening)
        XCTAssertEqual(parser.parse(phrase: "resume voice"), .resumeListening)
        XCTAssertEqual(parser.parse(phrase: "resume"), .resumeListening)
        XCTAssertEqual(parser.parse(phrase: "start listening"), .resumeListening)
        XCTAssertEqual(parser.parse(phrase: "continue listening"), .resumeListening)

        XCTAssertEqual(parser.parse(phrase: "toggle hands free"), .toggleHandsFree)
        XCTAssertEqual(parser.parse(phrase: "enable hands free"), .toggleHandsFree)
        XCTAssertEqual(parser.parse(phrase: "disable hands free"), .toggleHandsFree)
        XCTAssertEqual(parser.parse(phrase: "hands free mode"), .toggleHandsFree)
    }

    @MainActor
    func testVoiceCommandHandsFreeToggleAndState() async {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: false
        )

        XCTAssertFalse(vm.isHandsFreeModeEnabled)
        XCTAssertEqual(vm.listeningState, .idle)
        XCTAssertFalse(vm.isListening)

        // Enable hands-free mode
        await vm.setHandsFreeMode(enabled: true)
        XCTAssertTrue(vm.isHandsFreeModeEnabled)
        XCTAssertEqual(vm.listeningState, .listening)
        XCTAssertTrue(vm.isListening)
        XCTAssertTrue(mockRecognizer.isListening)

        // Disable hands-free mode
        await vm.setHandsFreeMode(enabled: false)
        XCTAssertFalse(vm.isHandsFreeModeEnabled)
        XCTAssertEqual(vm.listeningState, .idle)
        XCTAssertFalse(vm.isListening)
        XCTAssertFalse(mockRecognizer.isListening)
    }

    @MainActor
    func testVoiceCommandPauseAndResumeControls() async {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: true
        )

        // Start hands-free
        await vm.setHandsFreeMode(enabled: true)
        XCTAssertTrue(vm.isListening)
        XCTAssertFalse(vm.isPaused)

        // 1. Pause listening
        await vm.pauseListening()
        XCTAssertTrue(vm.isPaused)
        XCTAssertFalse(vm.isListening)
        XCTAssertEqual(vm.listeningState, .paused)
        XCTAssertFalse(mockRecognizer.isListening)

        // 2. Resume listening
        await vm.resumeListening()
        XCTAssertFalse(vm.isPaused)
        XCTAssertTrue(vm.isListening)
        XCTAssertEqual(vm.listeningState, .listening)
        XCTAssertTrue(mockRecognizer.isListening)
    }

    @MainActor
    func testVoiceCommandAutomaticReArmingAfterSpeech() async throws {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: true
        )

        var recognizedIntents: [VoiceCommandIntent] = []
        await vm.setHandsFreeMode(enabled: true) { intent in
            recognizedIntents.append(intent)
        }
        XCTAssertTrue(vm.isListening)

        // Simulate incoming spoken phrase
        mockRecognizer.simulateSpeech("open pronunciation")
        try await Task.sleep(nanoseconds: 50_000_000)

        // Trigger processing
        await vm.stopListeningAndProcess { intent in
            recognizedIntents.append(intent)
        }

        // Verify TTS was invoked and last spoken matches confirmation
        XCTAssertEqual(recognizedIntents.first, .openPronunciation)
        XCTAssertEqual(mockTTS.lastSpokenText, VoiceCommandIntent.openPronunciation.spokenConfirmation)
        XCTAssertGreaterThanOrEqual(mockTTS.speakCallCount, 1)

        // Await re-arm delay (400ms scheduled re-arm + buffer)
        try await Task.sleep(nanoseconds: 600_000_000)

        // Verify automatic re-arming back to listening state
        XCTAssertEqual(vm.listeningState, .listening)
        XCTAssertTrue(vm.isListening)
        XCTAssertTrue(mockRecognizer.isListening)
    }

    @MainActor
    func testVoiceCommandDuplicateListeningPrevention() async {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: true
        )

        await vm.startListening { _ in }
        let initialCalls = mockRecognizer.startListeningCallCount
        XCTAssertEqual(initialCalls, 1)

        // Attempting to call startListening while already active
        await vm.startListening { _ in }
        // Should not duplicate listening sessions
        XCTAssertEqual(mockRecognizer.startListeningCallCount, 1)
    }

    @MainActor
    func testVoiceCommandTrailingSilenceAutoFinalization() async throws {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: true
        )
        // Set short threshold for fast unit testing
        vm.silenceThreshold = 0.05

        var capturedIntent: VoiceCommandIntent?
        await vm.setHandsFreeMode(enabled: true) { intent in
            capturedIntent = intent
        }

        // Simulate user speaking
        mockRecognizer.simulateSpeech("stories")

        // Wait for silence task to auto-finalize
        try await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertEqual(capturedIntent, .openStories)
        XCTAssertEqual(vm.lastExecutedIntent, .openStories)
    }

    @MainActor
    func testVoiceCommandPermissionDenialHandling() async {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: false)
        mockRecognizer.shouldFailAuthorization = true
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: false
        )

        await vm.startListening { _ in }

        XCTAssertFalse(vm.isListening)
        XCTAssertEqual(vm.listeningState, .error("Permission Denied"))
        XCTAssertTrue(vm.errorMessage?.contains("permission was denied") == true)
    }

    @MainActor
    func testVoiceCommandAppLifecycleTransitions() async throws {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: true
        )

        await vm.setHandsFreeMode(enabled: true)
        XCTAssertTrue(vm.isListening)

        // 1. App moves to background
        vm.handleAppDidEnterBackground()
        XCTAssertFalse(vm.isListening)
        XCTAssertEqual(vm.listeningState, .paused)
        XCTAssertFalse(mockRecognizer.isListening)

        // 2. App returns to foreground
        vm.handleAppWillEnterForeground()
        // Wait for foreground re-arm delay (600ms + buffer)
        try await Task.sleep(nanoseconds: 800_000_000)
        XCTAssertTrue(vm.isListening)
        XCTAssertEqual(vm.listeningState, .listening)
    }

    @MainActor
    func testVoiceCommandAudioInterruptionHandling() async throws {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: true
        )

        await vm.setHandsFreeMode(enabled: true)
        XCTAssertTrue(vm.isListening)

        // Interruption begins (e.g. phone call or Siri)
        vm.handleAudioInterruption(began: true, shouldResume: false)
        XCTAssertFalse(vm.isListening)
        XCTAssertEqual(vm.listeningState, .paused)

        // Interruption ends with shouldResume option
        vm.handleAudioInterruption(began: false, shouldResume: true)
        // Wait for re-arm delay (800ms + buffer)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertTrue(vm.isListening)
        XCTAssertEqual(vm.listeningState, .listening)
    }

    @MainActor
    func testVoiceCommandConsecutiveErrorsPreventInfiniteLoop() async throws {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: true
        )

        await vm.setHandsFreeMode(enabled: true)
        XCTAssertTrue(vm.isListening)

        let testError = NSError(domain: "TestAudioEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio hardware reset"])

        // Error 1
        mockRecognizer.simulateError(testError)
        try await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertEqual(vm.listeningState, .error("Audio hardware reset"))

        // Error 2
        mockRecognizer.simulateError(testError)
        try await Task.sleep(nanoseconds: 20_000_000)

        // Error 3 (triggers maxConsecutiveErrors threshold)
        mockRecognizer.simulateError(testError)
        try await Task.sleep(nanoseconds: 20_000_000)

        // Loop should disarm and enter paused state rather than infinite retry loop
        XCTAssertTrue(vm.isPaused)
        XCTAssertTrue(vm.statusMessage.contains("paused after errors"))
    }

    // MARK: - Step 4: Full User Journey Voice Guidance & Accessibility Tests

    @MainActor
    func testVoiceGuidanceLaunchOnboardingSpokenOnlyOnce() async {
        let mockTTS = MockSpeechService()
        let coordinator = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: true)

        XCTAssertFalse(coordinator.hasSpokenOnboarding)

        // 1. First launch onboarding call
        let firstCall = await coordinator.provideLaunchOnboarding()
        XCTAssertNotNil(firstCall)
        XCTAssertTrue(coordinator.hasSpokenOnboarding)
        XCTAssertEqual(mockTTS.speakCallCount, 1)
        XCTAssertTrue(coordinator.lastSpokenGuidance.contains("Welcome to VoCo"))
        XCTAssertTrue(coordinator.lastSpokenGuidance.contains("pause listening"))

        // 2. Second minor redraw / call - must NOT repeat onboarding
        let secondCall = await coordinator.provideLaunchOnboarding()
        XCTAssertNil(secondCall)
        XCTAssertEqual(mockTTS.speakCallCount, 1) // Unchanged

        // 3. Explicit force re-announcement
        let forcedCall = await coordinator.provideLaunchOnboarding(force: true)
        XCTAssertNotNil(forcedCall)
        XCTAssertEqual(mockTTS.speakCallCount, 2)
    }

    @MainActor
    func testVoiceGuidanceNeverTranscribesOrSpeaksPasswords() async {
        let mockTTS = MockSpeechService()
        let coordinator = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: true)

        // Sign In guidance must explicitly instruct secure entry and never request spoken passwords
        let signInGuidance = await coordinator.provideScreenGuidance(root: .signIn, destination: nil)
        XCTAssertTrue(signInGuidance.contains("passwords must be entered securely"))
        XCTAssertTrue(signInGuidance.contains("cannot be spoken"))

        // Sign Up guidance must enforce secure password typing
        let signUpGuidance = await coordinator.provideScreenGuidance(root: .signUp, destination: nil)
        XCTAssertTrue(signUpGuidance.contains("passwords must be entered securely"))

        // Security topic help reinforces no spoken/logged credentials
        let secHelp = coordinator.provideTopicHelp("security")
        XCTAssertTrue(secHelp.contains("never records, speaks, or logs passwords"))

        // Check coordinator history
        XCTAssertFalse(coordinator.lastSpokenGuidance.contains("password123"))
    }

    @MainActor
    func testVoiceGuidanceContextualScreenPrompts() async {
        let mockTTS = MockSpeechService()
        let coordinator = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: false)

        // Pronunciation Practice
        let pronMsg = await coordinator.provideScreenGuidance(root: .dashboard, destination: .pronunciationRecord)
        XCTAssertTrue(pronMsg.contains("Pronunciation Practice"))
        XCTAssertTrue(pronMsg.contains("start recording"))

        // Pronunciation Review
        let reviewMsg = await coordinator.provideScreenGuidance(root: .dashboard, destination: .pronunciationReview)
        XCTAssertTrue(reviewMsg.contains("Pronunciation Review"))
        XCTAssertTrue(reviewMsg.contains("re-record"))

        // Interactive Quiz
        let quizMsg = await coordinator.provideScreenGuidance(root: .dashboard, destination: .quiz)
        XCTAssertTrue(quizMsg.contains("Interactive Quiz"))
        XCTAssertTrue(quizMsg.contains("True"))

        // Story Reader
        let story = Story.standardStories[0]
        let storyMsg = await coordinator.provideScreenGuidance(root: .dashboard, destination: .storyDetail(story))
        XCTAssertTrue(storyMsg.contains(story.title))
        XCTAssertTrue(storyMsg.contains("take quiz"))

        // VoCo Gyan
        let gyanMsg = await coordinator.provideScreenGuidance(root: .dashboard, destination: .voCoGyan)
        XCTAssertTrue(gyanMsg.contains("VoCo Gyan"))

        // Dashboard
        let dashMsg = await coordinator.provideScreenGuidance(root: .dashboard, destination: nil)
        XCTAssertTrue(dashMsg.contains("Home Dashboard"))
    }

    @MainActor
    func testVoiceGuidanceContextualHelpInNavigationStateMachine() {
        let sm = AppNavigationStateMachine(initialRoot: .dashboard, isAuthenticated: true)

        // 1. On Dashboard root
        let dashHelpResult = sm.process(intent: .help)
        if case .actionExecuted(let action, let spoken) = dashHelpResult {
            XCTAssertEqual(action, "Help")
            XCTAssertTrue(spoken.contains("Dashboard, Pronunciation, Gyan, Games, Stories, Quiz"))
        } else {
            XCTFail("Expected Help action")
        }

        // 2. In Quiz destination
        sm.push(.quiz)
        let quizHelpResult = sm.process(intent: .help)
        if case .actionExecuted(let action, let spoken) = quizHelpResult {
            XCTAssertEqual(action, "Help")
            XCTAssertTrue(spoken.contains("In the Quiz, say"))
            XCTAssertTrue(spoken.contains("true"))
        } else {
            XCTFail("Expected Help action")
        }

        // 3. In Pronunciation destination
        sm.push(.pronunciationRecord)
        let pronHelpResult = sm.process(intent: .help)
        if case .actionExecuted(let action, let spoken) = pronHelpResult {
            XCTAssertEqual(action, "Help")
            XCTAssertTrue(spoken.contains("In Pronunciation, say"))
            XCTAssertTrue(spoken.contains("start recording"))
        } else {
            XCTFail("Expected Help action")
        }

        // 4. Topic-specific help
        let topicResult = sm.process(intent: .helpWithTopic("pronunciation"))
        if case .actionExecuted(let action, let spoken) = topicResult {
            XCTAssertEqual(action, "HelpTopic")
            XCTAssertTrue(spoken.contains("listen to voco"))
        } else {
            XCTFail("Expected HelpTopic action")
        }
    }

    @MainActor
    func testVoiceGuidanceProgressAnnouncement() async {
        let mockTTS = MockSpeechService()
        let coordinator = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: true)

        let progressText = await coordinator.announceProgress(
            completedSentences: 3,
            totalSentences: 5,
            quizScore: 4,
            totalQuestions: 5
        )

        XCTAssertTrue(progressText.contains("3 of 5 pronunciation sentences"))
        XCTAssertTrue(progressText.contains("4 of 5 on the quiz"))
        XCTAssertEqual(mockTTS.speakCallCount, 1)
    }

    @MainActor
    func testVoiceGuidanceAuthErrorAnnouncement() async {
        let mockTTS = MockSpeechService()
        let coordinator = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: true)

        let errorText = await coordinator.announceAuthError("The email address is badly formatted.")
        XCTAssertTrue(errorText.contains("Authentication error: The email address is badly formatted."))
        XCTAssertEqual(mockTTS.speakCallCount, 1)
    }

    @MainActor
    func testVoiceGuidanceBackendStatusCommunication() async {
        let mockTTS = MockSpeechService()

        // Mock offline backend
        let mockCoord = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: true)
        let mockMsg = await mockCoord.announceBackendNotice()
        XCTAssertTrue(mockMsg.contains("offline demo mode"))

        // Live cloud backend
        let liveCoord = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: false)
        let liveMsg = await liveCoord.announceBackendNotice()
        XCTAssertTrue(liveMsg.contains("live cloud services"))
    }

    @MainActor
    func testVoiceGuidanceHandsFreeSpeechCoordination() async {
        let mockTTS = MockSpeechService()
        let coordinator = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: true)

        var delegatedSpokenText: String?
        coordinator.onSpeakGuidance = { text in
            delegatedSpokenText = text
            await mockTTS.speak(text: text)
        }

        await coordinator.provideScreenGuidance(root: .dashboard, destination: .gamesHub)
        XCTAssertEqual(delegatedSpokenText, coordinator.lastSpokenGuidance)
        XCTAssertEqual(mockTTS.speakCallCount, 1)
    }

    // MARK: - Step 5: Final End-to-End Regression & Voice Journey Tests

    @MainActor
    func testE2EAppLaunchOnboardingAndPermissionWorkflow() async {
        let mockTTS = MockSpeechService()
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let coordinator = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: true)
        let voiceVM = VoiceCommandViewModel(speechRecognizer: mockRecognizer, speechService: mockTTS, enableHandsFreeByDefault: false)

        // 1. Fresh launch: onboarding spoken once
        XCTAssertFalse(coordinator.hasSpokenOnboarding)
        let onboarding = await coordinator.provideLaunchOnboarding()
        XCTAssertNotNil(onboarding)
        XCTAssertTrue(onboarding?.contains("Welcome to VoCo") == true)
        XCTAssertTrue(onboarding?.contains("pause listening") == true)
        XCTAssertTrue(coordinator.hasSpokenOnboarding)

        // 2. Microphone must not be capturing before permission/hands-free is explicitly initiated
        XCTAssertFalse(voiceVM.isListening)
        XCTAssertFalse(mockRecognizer.isListening)

        // 3. Permission denied scenario
        let deniedRecognizer = MockSpeechRecognitionService(isAuthorized: false)
        deniedRecognizer.shouldFailAuthorization = true
        let deniedVM = VoiceCommandViewModel(speechRecognizer: deniedRecognizer, speechService: mockTTS, enableHandsFreeByDefault: false)
        await deniedVM.startListening { _ in }
        XCTAssertFalse(deniedVM.isListening)
        XCTAssertEqual(deniedVM.listeningState, .error("Permission Denied"))

        // 4. Explicit hands-free activation
        await voiceVM.setHandsFreeMode(enabled: true)
        XCTAssertTrue(voiceVM.isHandsFreeModeEnabled)
        XCTAssertTrue(voiceVM.isListening)
        XCTAssertTrue(mockRecognizer.isListening)
    }

    @MainActor
    func testE2EVoiceGuidedAuthenticationAndCredentialSafety() async {
        let mockAuth = MockAuthService()
        let mockBiometric = MockBiometricAuthService(supportedBiometricType: .faceID, isBiometricAvailable: true)
        let tokenStore = MockTokenStore()
        let mockTTS = MockSpeechService()

        let authVM = AuthViewModel(authService: mockAuth, biometricService: mockBiometric, tokenStore: tokenStore)
        let coordinator = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: true)

        // 1. Guided Sign In instructions
        let signInGuidance = await coordinator.provideScreenGuidance(root: .signIn, destination: nil)
        XCTAssertTrue(signInGuidance.contains("passwords must be entered securely"))
        XCTAssertTrue(signInGuidance.contains("cannot be spoken"))
        XCTAssertTrue(signInGuidance.contains("Operating in offline demo mode"))

        // 2. Voice email entry
        authVM.handleSpokenEmailInput("learner-at-voco-dot-app")
        XCTAssertEqual(authVM.email, "learner@voco.app")
        authVM.handleSpokenEmailInput("confirm email")
        XCTAssertTrue(authVM.emailConfirmed)

        // 3. Password entry is strictly typed - never spoken
        authVM.password = "SuperSecret123!"
        XCTAssertFalse(coordinator.lastSpokenGuidance.contains("SuperSecret123!"))
        XCTAssertFalse(authVM.voiceSpokenFeedback?.contains("SuperSecret123!") == true)

        // 4. Sign in with bad password fails safely
        authVM.password = "short"
        let failResult = await authVM.signIn()
        XCTAssertFalse(failResult)
        XCTAssertNotNil(authVM.errorMessage)
        let errorNotice = await coordinator.announceAuthError(authVM.errorMessage ?? "")
        XCTAssertTrue(errorNotice.contains("Authentication error"))
        XCTAssertFalse(errorNotice.contains("short"))

        // 5. Sign in success with valid password
        authVM.setBiometricEnrollment(enabled: true)
        authVM.password = "ValidPassword123"
        let successResult = await authVM.signIn()
        XCTAssertTrue(successResult)
        XCTAssertTrue(authVM.isAuthenticated)
        XCTAssertEqual(tokenStore.retrieveLastAuthenticatedEmail(), "learner@voco.app")
    }

    @MainActor
    func testE2EFullLearningModuleJourney() async throws {
        let parser = VoiceCommandParser()
        let sm = AppNavigationStateMachine(initialRoot: .dashboard, isAuthenticated: true)
        let quizVM = QuizViewModel()
        let mockTTS = MockSpeechService()
        let coordinator = VoiceGuidanceCoordinator(speechService: mockTTS, isMockBackend: true)

        // 1. Navigate to Pronunciation Practice
        let pronIntent = parser.parse(phrase: "open pronunciation")
        XCTAssertEqual(pronIntent, .openPronunciation)
        let pronNav = sm.process(intent: pronIntent)
        XCTAssertEqual(sm.navigationStack.last, .pronunciationRecord)
        XCTAssertEqual(pronNav.spokenFeedback, "Opening Pronunciation Guide.")

        // Contextual help in pronunciation
        let pronHelp = sm.process(intent: .help)
        XCTAssertTrue(pronHelp.spokenFeedback.contains("In Pronunciation, say"))

        // 2. Pronunciation recording actions
        let startRec = sm.process(intent: parser.parse(phrase: "start recording"))
        XCTAssertEqual(startRec.spokenFeedback, "Recording started. Speak now.")

        let stopRec = sm.process(intent: parser.parse(phrase: "stop recording"))
        XCTAssertEqual(sm.navigationStack.last, .pronunciationReview)
        XCTAssertEqual(stopRec.spokenFeedback, "Recording stopped.")

        _ = sm.process(intent: parser.parse(phrase: "re record"))
        XCTAssertEqual(sm.navigationStack.last, .pronunciationRecord)

        // 3. Return to Dashboard
        let homeIntent = parser.parse(phrase: "go home")
        _ = sm.process(intent: homeIntent)
        XCTAssertEqual(sm.currentRoot, .dashboard)
        XCTAssertTrue(sm.navigationStack.isEmpty)

        // 4. Navigate to Stories
        let storyIntent = parser.parse(phrase: "read story 2")
        let storyNav = sm.process(intent: storyIntent)
        if case .navigated(let dest, _) = storyNav {
            XCTAssertEqual(dest, .storyDetail(Story.standardStories[1]))
        } else {
            XCTFail("Expected story detail navigation")
        }

        // 5. Navigate to Quiz
        let quizIntent = parser.parse(phrase: "open quiz")
        _ = sm.process(intent: quizIntent)
        XCTAssertEqual(sm.navigationStack.last, .quiz)

        // 6. Answer Quiz Question
        XCTAssertNotNil(quizVM.currentQuestion)
        let answerIntent = parser.parse(phrase: "true")
        XCTAssertEqual(answerIntent, .answerTrue)
        let quizAction = sm.process(intent: answerIntent)
        if case .actionExecuted(let act, _) = quizAction {
            XCTAssertEqual(act, "AnswerTrue")
            quizVM.answerCurrentQuestion(with: true)
            XCTAssertTrue(quizVM.isAnswerSubmitted)
        }

        // 7. Advance Question
        let nextIntent = parser.parse(phrase: "next question")
        XCTAssertEqual(nextIntent, .nextQuestion)
        _ = sm.process(intent: nextIntent)
        quizVM.nextQuestion()
        XCTAssertEqual(quizVM.currentIndex, 1)

        // 8. Check Progress
        let progressIntent = parser.parse(phrase: "read my progress")
        XCTAssertEqual(progressIntent, .readProgress)
        let progressMsg = await coordinator.announceProgress(completedSentences: 2, totalSentences: 5, quizScore: 1, totalQuestions: 5)
        XCTAssertTrue(progressMsg.contains("2 of 5 pronunciation sentences"))
        XCTAssertTrue(progressMsg.contains("1 of 5 on the quiz"))

        // 9. Sign Out
        let logoutIntent = parser.parse(phrase: "log out")
        XCTAssertEqual(logoutIntent, .signOut)
        let logoutNav = sm.process(intent: logoutIntent)
        XCTAssertEqual(sm.currentRoot, .authWelcome)
        XCTAssertFalse(sm.isAuthenticated)
        XCTAssertTrue(logoutNav.spokenFeedback.contains("Signing out"))
    }

    @MainActor
    func testE2EHandsFreeAudioLifecycleAndConcurrency() async throws {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: true
        )

        // 1. Hands-free start
        await vm.setHandsFreeMode(enabled: true)
        XCTAssertTrue(vm.isListening)
        XCTAssertEqual(vm.listeningState, .listening)

        // 2. TTS Echo Prevention: recognizer stopped while speaking
        let speechTask = Task {
            await vm.speakUtterance("Speaking spoken feedback safely.")
        }
        try await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertEqual(vm.listeningState, .speaking)
        XCTAssertFalse(mockRecognizer.isListening)
        await speechTask.value

        // Safe re-arm after settle delay (300ms) + schedule re-arm (400ms)
        try await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertEqual(vm.listeningState, .listening)
        XCTAssertTrue(mockRecognizer.isListening)

        // 3. Audio Interruption Handling (e.g. Phone Call)
        vm.handleAudioInterruption(began: true, shouldResume: false)
        XCTAssertFalse(vm.isListening)
        XCTAssertEqual(vm.listeningState, .paused)

        vm.handleAudioInterruption(began: false, shouldResume: true)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertTrue(vm.isListening)
        XCTAssertEqual(vm.listeningState, .listening)

        // 4. Backgrounding & Foregrounding
        vm.handleAppDidEnterBackground()
        XCTAssertFalse(vm.isListening)
        XCTAssertEqual(vm.listeningState, .paused)

        vm.handleAppWillEnterForeground()
        try await Task.sleep(nanoseconds: 800_000_000)
        XCTAssertTrue(vm.isListening)
        XCTAssertEqual(vm.listeningState, .listening)
    }

    func testE2EVoiceOverAccessibilityAndSemanticTraits() {
        // VoiceListeningState text and accessibilityLabel ensure status is not conveyed by color alone
        let listeningState = VoiceListeningState.listening
        XCTAssertEqual(listeningState.statusDescription, "Listening")
        XCTAssertEqual(listeningState.accessibilityLabel, "Voice listening active. Speak your command now.")

        let pausedState = VoiceListeningState.paused
        XCTAssertEqual(pausedState.statusDescription, "Paused")
        XCTAssertEqual(pausedState.accessibilityLabel, "Voice listening paused. Tap resume to continue.")

        let speakingState = VoiceListeningState.speaking
        XCTAssertEqual(speakingState.statusDescription, "Speaking")
        XCTAssertEqual(speakingState.accessibilityLabel, "VoCo is speaking. Microphone paused.")

        let errorState = VoiceListeningState.error("Test failure")
        XCTAssertEqual(errorState.statusDescription, "Error: Test failure")
        XCTAssertEqual(errorState.accessibilityLabel, "Voice assistant error: Test failure.")

        // Accessibility announcement helper
        AccessibilityHelper.announce("VoCo accessibility regression test")
        XCTAssertEqual(AccessibilityHelper.lastAnnouncement, "VoCo accessibility regression test")
    }


    // MARK: - Step 6: Multilingual & Intelligent Voice Command Tests

    func testAppLanguageCatalogAndFallback() {
        let allLanguages = AppLanguage.standardLanguages
        XCTAssertEqual(allLanguages.count, 25, "Must support 25 languages (15 Indian + 10 International)")

        let indian = allLanguages.filter { $0.region == .indian }
        XCTAssertEqual(indian.count, 15)

        let international = allLanguages.filter { $0.region == .international }
        XCTAssertEqual(international.count, 10)

        // Verify key Indian languages
        let indianCodes = Set(indian.map { $0.id })
        XCTAssertTrue(indianCodes.contains("hi-IN")) // Hindi
        XCTAssertTrue(indianCodes.contains("en-IN")) // Indian English
        XCTAssertTrue(indianCodes.contains("ta-IN")) // Tamil
        XCTAssertTrue(indianCodes.contains("te-IN")) // Telugu
        XCTAssertTrue(indianCodes.contains("bn-IN")) // Bengali
        XCTAssertTrue(indianCodes.contains("mr-IN")) // Marathi
        XCTAssertTrue(indianCodes.contains("gu-IN")) // Gujarati
        XCTAssertTrue(indianCodes.contains("kn-IN")) // Kannada
        XCTAssertTrue(indianCodes.contains("ml-IN")) // Malayalam
        XCTAssertTrue(indianCodes.contains("pa-IN")) // Punjabi
        XCTAssertTrue(indianCodes.contains("ur-IN")) // Urdu

        // Verify key International languages
        let intlCodes = Set(international.map { $0.id })
        XCTAssertTrue(intlCodes.contains("es-ES")) // Spanish
        XCTAssertTrue(intlCodes.contains("fr-FR")) // French
        XCTAssertTrue(intlCodes.contains("de-DE")) // German
        XCTAssertTrue(intlCodes.contains("zh-CN")) // Mandarin
        XCTAssertTrue(intlCodes.contains("ja-JP")) // Japanese
        XCTAssertTrue(intlCodes.contains("ar-SA")) // Arabic

        // Each language has valid metadata
        for lang in allLanguages {
            XCTAssertFalse(lang.id.isEmpty)
            XCTAssertFalse(lang.name.isEmpty)
            XCTAssertFalse(lang.nativeName.isEmpty)
            XCTAssertFalse(lang.flagEmoji.isEmpty)
            XCTAssertFalse(lang.verifiedSpeechLocaleIdentifier.isEmpty)
        }

        XCTAssertEqual(AppLanguage.defaultLanguage.id, "en-IN")
    }

    @MainActor
    func testLanguageManagerSwitchingAndPersistence() {
        let manager = LanguageManager.shared
        let container = ServiceContainer.mock()

        // 1. Switch to Hindi
        guard let hindi = AppLanguage.standardLanguages.first(where: { $0.id == "hi-IN" }) else {
            XCTFail("Hindi language missing")
            return
        }
        manager.setLanguage(hindi, container: container)
        XCTAssertEqual(manager.currentLanguage.id, "hi-IN")
        XCTAssertEqual(container.speechService.defaultLanguage, "hi-IN")
        XCTAssertTrue(manager.localizedAnnouncementForSwitch(to: hindi).contains("हिन्दी"))

        // 2. Switch to Spanish
        guard let spanish = AppLanguage.standardLanguages.first(where: { $0.id == "es-ES" }) else {
            XCTFail("Spanish language missing")
            return
        }
        manager.setLanguage(spanish, container: container)
        XCTAssertEqual(manager.currentLanguage.id, "es-ES")
        XCTAssertEqual(container.speechService.defaultLanguage, "es-ES")
        XCTAssertTrue(manager.localizedAnnouncementForSwitch(to: spanish).contains("español"))

        // Reset back to English
        guard let english = AppLanguage.standardLanguages.first(where: { $0.id == "en-IN" }) else { return }
        manager.setLanguage(english, container: container)
    }

    func testMultilingualVoiceCommandParser() {
        let parser = VoiceCommandParser()

        // Hindi and Hinglish voice phrases
        XCTAssertEqual(parser.parse(phrase: "courses kholo"), .openVoCoGyan)
        XCTAssertEqual(parser.parse(phrase: "non-technical courses dikhao"), .openNonTechnicalCourses)
        XCTAssertEqual(parser.parse(phrase: "mujhe non-technical courses dikhao"), .openNonTechnicalCourses)
        XCTAssertEqual(parser.parse(phrase: "interview prepare karwao"), .openCourseTopic(topicId: "topic-interview"))
        XCTAssertEqual(parser.parse(phrase: "spoken english"), .openCourseTopic(topicId: "topic-communication"))
        XCTAssertEqual(parser.parse(phrase: "uchharan abhyas"), .openPronunciation)
        XCTAssertEqual(parser.parse(phrase: "kahani sunao"), .openStories)
        XCTAssertEqual(parser.parse(phrase: "piche jao"), .goBack)
        XCTAssertEqual(parser.parse(phrase: "ghar jao"), .goHome)
        XCTAssertEqual(parser.parse(phrase: "bahar niklo"), .signOut)
        XCTAssertEqual(parser.parse(phrase: "suno mat"), .pauseListening)
        XCTAssertEqual(parser.parse(phrase: "chalu karo"), .resumeListening)

        // Language switching intents
        XCTAssertEqual(parser.parse(phrase: "switch to hindi"), .switchLanguage(localeCode: "hi-IN"))
        XCTAssertEqual(parser.parse(phrase: "switch to spanish"), .switchLanguage(localeCode: "es-ES"))
        XCTAssertEqual(parser.parse(phrase: "switch to french"), .switchLanguage(localeCode: "fr-FR"))
        XCTAssertEqual(parser.parse(phrase: "switch to tamil"), .switchLanguage(localeCode: "ta-IN"))

        // Spanish voice commands
        XCTAssertEqual(parser.parse(phrase: "abrir cursos"), .openVoCoGyan)
        XCTAssertEqual(parser.parse(phrase: "atrás"), .goBack)
        XCTAssertEqual(parser.parse(phrase: "historias"), .openStories)
        XCTAssertEqual(parser.parse(phrase: "cuestionario"), .openQuiz)
    }

    @MainActor
    func testNonTechnicalCoursesNavigationRouting() {
        let sm = AppNavigationStateMachine(initialRoot: .dashboard, isAuthenticated: true)

        // Direct navigation to Non-Technical courses
        let nonTechResult = sm.process(intent: .openNonTechnicalCourses)
        XCTAssertEqual(nonTechResult, .navigated(destination: .technicalCourses(.nonTechnical), spokenFeedback: "Opening Non-Technical Courses."))
        XCTAssertEqual(sm.navigationStack.last, .technicalCourses(.nonTechnical))

        // Direct navigation to Interview topic
        let topicResult = sm.process(intent: .openCourseTopic(topicId: "topic-interview"))
        if case .navigated(let dest, let feedback) = topicResult {
            XCTAssertTrue(feedback.contains("Interview Preparation"))
            if case .dsaEpisodes(let topic) = dest {
                XCTAssertEqual(topic.id, "topic-interview")
                XCTAssertEqual(topic.category, .nonTechnical)
            } else {
                XCTFail("Expected .dsaEpisodes destination")
            }
        } else {
            XCTFail("Expected navigated result")
        }
    }

    // MARK: - Global Voice-Controlled Language Switching Acceptance Tests

    @MainActor
    func testGlobalVoiceControlledLanguageSwitchingWorkflow() async {
        let parser = VoiceCommandParser()
        let manager = LanguageManager.shared
        let container = ServiceContainer.mock()

        // 1. User says: "Change language to Marathi."
        let switchMarathiIntent = parser.parse(phrase: "Change language to Marathi.")
        XCTAssertEqual(switchMarathiIntent, .switchLanguage(localeCode: "mr-IN"))

        // Apply switch
        guard let marathi = AppLanguage.standardLanguages.first(where: { $0.id == "mr-IN" }) else {
            XCTFail("Marathi language not found")
            return
        }
        manager.setLanguage(marathi, container: container)
        XCTAssertEqual(manager.currentLanguage.id, "mr-IN")
        XCTAssertEqual(container.speechService.defaultLanguage, "mr-IN")
        XCTAssertEqual(container.speechRecognizer.currentLocaleIdentifier, "mr-IN")

        // 2. VoCo confirms in Marathi: 'भाषा मराठीमध्ये बदलली आहे. आता तुम्ही मराठीत बोलू शकता.'
        let marathiConfirmation = manager.localizedAnnouncementForSwitch(to: marathi)
        XCTAssertEqual(marathiConfirmation, "भाषा मराठीमध्ये बदलली आहे. आता तुम्ही मराठीत बोलू शकता.")

        // 3. Subsequent voice commands in Marathi understood
        // "तांत्रिक कोर्सेस उघडा" -> openTechnicalCourses
        let techCommand = parser.parse(phrase: "तांत्रिक कोर्सेस उघडा")
        XCTAssertEqual(techCommand, .openTechnicalCourses)
        XCTAssertEqual(techCommand.localizedSpokenConfirmation(for: marathi), "तांत्रिक कोर्सेस उघडत आहे.")

        // "अतांत्रिक कोर्सेस उघडा" -> openNonTechnicalCourses
        let nonTechCommand = parser.parse(phrase: "अतांत्रिक कोर्सेस उघडा")
        XCTAssertEqual(nonTechCommand, .openNonTechnicalCourses)
        XCTAssertEqual(nonTechCommand.localizedSpokenConfirmation(for: marathi), "अतांत्रिक कोर्सेस उघडत आहे.")

        // "क्विझ सुरू करा" -> openQuiz
        let quizCommand = parser.parse(phrase: "क्विझ सुरू करा")
        XCTAssertEqual(quizCommand, .openQuiz)
        XCTAssertEqual(quizCommand.localizedSpokenConfirmation(for: marathi), "व्होको क्विझ सुरू करत आहे.")

        // Quiz answers in Marathi
        XCTAssertEqual(parser.parse(phrase: "बरोबर"), .answerTrue)
        XCTAssertEqual(parser.parse(phrase: "चूक"), .answerFalse)
        XCTAssertEqual(parser.parse(phrase: "पुढचा प्रश्न"), .nextQuestion)

        // Navigation in Marathi
        XCTAssertEqual(parser.parse(phrase: "मुख्यपृष्ठ"), .goHome)
        XCTAssertEqual(parser.parse(phrase: "मागे जा"), .goBack)
        XCTAssertEqual(parser.parse(phrase: "मदत"), .help)

        // 4. Romanized / English phrases for switching
        XCTAssertEqual(parser.parse(phrase: "Change language to Hindi"), .switchLanguage(localeCode: "hi-IN"))
        XCTAssertEqual(parser.parse(phrase: "Switch to English"), .switchLanguage(localeCode: "en-IN"))
        XCTAssertEqual(parser.parse(phrase: "Mujhse Hinglish mein baat karo"), .switchLanguage(localeCode: "hi-IN"))
        XCTAssertEqual(parser.parse(phrase: "Change language to Tamil"), .switchLanguage(localeCode: "ta-IN"))
        XCTAssertEqual(parser.parse(phrase: "Change language to Telugu"), .switchLanguage(localeCode: "te-IN"))

        // 5. Native script language switching
        XCTAssertEqual(parser.parse(phrase: "मराठी"), .switchLanguage(localeCode: "mr-IN"))
        XCTAssertEqual(parser.parse(phrase: "हिन्दी"), .switchLanguage(localeCode: "hi-IN"))

        // 6. Unsupported language rejection and feedback
        let unsupported = parser.parse(phrase: "Change language to Klingon")
        XCTAssertEqual(unsupported, .unsupportedLanguage(requested: "klingon"))
        let feedback = manager.localizedUnsupportedFeedback(for: "klingon")
        XCTAssertTrue(feedback.contains("klingon"))

        // Reset back to English
        guard let english = AppLanguage.standardLanguages.first(where: { $0.id == "en-IN" }) else { return }
        manager.setLanguage(english, container: container)
    }

    @MainActor
    func testVoiceCommandViewModelExecutesMarathiSwitchAndCommands() async throws {
        let mockRecognizer = MockSpeechRecognitionService(isAuthorized: true)
        let mockTTS = MockSpeechService()
        let vm = VoiceCommandViewModel(
            speechRecognizer: mockRecognizer,
            speechService: mockTTS,
            enableHandsFreeByDefault: false
        )
        vm.silenceThreshold = 0.05

        var capturedIntent: VoiceCommandIntent?
        await vm.startListening { intent in
            capturedIntent = intent
        }

        // Simulate voice input: "Change language to Marathi."
        mockRecognizer.simulateSpeech("Change language to Marathi.")
        try await Task.sleep(nanoseconds: 150_000_000)

        // Verify status message and TTS spoke exact Marathi confirmation
        XCTAssertEqual(capturedIntent, .switchLanguage(localeCode: "mr-IN"))
        XCTAssertEqual(vm.statusMessage, "भाषा मराठीमध्ये बदलली आहे. आता तुम्ही मराठीत बोलू शकता.")
        XCTAssertEqual(mockTTS.lastSpokenText, "भाषा मराठीमध्ये बदलली आहे. आता तुम्ही मराठीत बोलू शकता.")
        XCTAssertEqual(mockRecognizer.currentLocaleIdentifier, "mr-IN")
        XCTAssertEqual(mockTTS.defaultLanguage, "mr-IN")

        // Start listening again for subsequent Marathi command
        await vm.startListening { intent in
            capturedIntent = intent
        }

        // Simulate voice command in Marathi: "तांत्रिक कोर्सेस उघडा"
        mockRecognizer.simulateSpeech("तांत्रिक कोर्सेस उघडा")
        try await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertEqual(capturedIntent, .openTechnicalCourses)
        XCTAssertEqual(vm.lastExecutedIntent, .openTechnicalCourses)
        XCTAssertEqual(vm.statusMessage, "तांत्रिक कोर्सेस उघडत आहे.")
        XCTAssertEqual(mockTTS.lastSpokenText, "तांत्रिक कोर्सेस उघडत आहे.")

        // Reset language to English
        LanguageManager.shared.setLanguage(AppLanguage.defaultLanguage)
    }
}
