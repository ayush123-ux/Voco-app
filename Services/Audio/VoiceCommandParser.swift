import Foundation

/// Defines all recognized voice command intents across VoCoNative
public enum VoiceCommandIntent: Equatable, Hashable {
    // Screen Navigation
    case openPronunciation
    case openTalkWithVoCo
    case openVoCoGyan
    case openTechnicalCourses
    case openNonTechnicalCourses
    case openCourseTopic(topicId: String)
    case openGames
    case openStories
    case readStory(identifier: String?)
    case openQuiz
    case openLogin
    case openSignUp
    case openUserProfile
    case goHome
    case goBack
    case signOut

    // Pronunciation Guide Actions
    case startRecording
    case stopRecording
    case nextSentence
    case reRecord
    case listenToVoCo

    // Quiz Actions
    case answerTrue
    case answerFalse
    case selectQuizOption(index: Int)
    case nextQuestion

    // Utility & General Actions
    case repeatSpoken
    case cancel
    case readProgress
    case help
    case helpWithTopic(String)
    case unknown(String)

    // Hands-Free & Privacy Actions
    case pauseListening
    case resumeListening
    case toggleHandsFree

    // Multilingual & Disambiguation
    case switchLanguage(localeCode: String)
    case clarificationNeeded(prompt: String, suggestedOptions: [String])

    /// Spoken confirmation feedback to speak back to the user
    public var spokenConfirmation: String {
        switch self {
        case .openPronunciation:
            return "Opening Pronunciation Guide."
        case .openTalkWithVoCo:
            return "Opening Talk with VoCo."
        case .openVoCoGyan:
            return "Opening VoCo Gyan lessons."
        case .openTechnicalCourses:
            return "Opening Technical Courses."
        case .openNonTechnicalCourses:
            return "Opening Non-Technical Courses."
        case .openCourseTopic(let topicId):
            if let topic = CourseTopic.standardTopics.first(where: { $0.id == topicId || $0.id.contains(topicId) }) {
                return "Opening \(topic.title)."
            }
            return "Opening course."
        case .openGames:
            return "Opening Games and Challenges."
        case .openStories:
            return "Opening Story Catalog."
        case .readStory(let identifier):
            if let id = identifier, !id.isEmpty {
                return "Opening story \(id)."
            } else {
                return "Opening story."
            }
        case .openQuiz:
            return "Starting VoCo Quiz."
        case .openLogin:
            return "Opening Sign In."
        case .openSignUp:
            return "Opening Sign Up."
        case .openUserProfile:
            return "Opening User Profile."
        case .goHome:
            return "Returning to Dashboard."
        case .goBack:
            return "Going back."
        case .signOut:
            return "Signing out."
        case .startRecording:
            return "Recording started. Speak now."
        case .stopRecording:
            return "Recording stopped."
        case .nextSentence:
            return "Moving to next sentence."
        case .reRecord:
            return "Ready to re-record."
        case .listenToVoCo:
            return "Playing pronunciation."
        case .answerTrue:
            return "Selected True."
        case .answerFalse:
            return "Selected False."
        case .selectQuizOption(let index):
            return "Selected Option \(index)."
        case .nextQuestion:
            return "Advancing to next question."
        case .repeatSpoken:
            return "Repeating."
        case .cancel:
            return "Cancelled."
        case .readProgress:
            return "Checking your learning progress."
        case .help:
            return "VoCo Voice Help: You can navigate to Pronunciation, Talk, Gyan, Games, Quiz, or say Go Back, Repeat, Cancel, or Pause Listening."
        case .helpWithTopic(let topic):
            return "Help for \(topic)."
        case .unknown(let query):
            if query.isEmpty {
                return "No speech detected. Please try speaking again."
            }
            return "Command not recognized: \(query). Say 'help' for available commands."
        case .pauseListening:
            return "Voice listening paused. Tap Resume or speak to continue."
        case .resumeListening:
            return "Voice listening resumed."
        case .toggleHandsFree:
            return "Hands-free voice mode updated."
        case .switchLanguage(let localeCode):
            if let lang = AppLanguage.standardLanguages.first(where: { $0.id == localeCode || $0.id.hasPrefix(localeCode) }) {
                return "Switching language to \(lang.name)."
            }
            return "Language switched."
        case .clarificationNeeded(let prompt, _):
            return prompt
        }
    }
}

/// Pure Swift semantic parser converting speech-recognized text into structured VoiceCommandIntents
public struct VoiceCommandParser {
    public init() {}

    /// Parses spoken transcriptions into structured intents with multilingual normalization and semantic entity extraction
    public func parse(phrase: String) -> VoiceCommandIntent {
        let clean = normalize(phrase: phrase)

        guard !clean.isEmpty else {
            return .unknown("")
        }

        // MARK: - Hands-Free & Privacy commands (English & Multilingual)
        if clean == "pause listening" || clean == "pause voice" || clean == "pause" || clean == "hold on" || clean == "stop listening" ||
           clean == "awaaz roko" || clean == "suno mat" || clean == "ruko" || clean == "shant raho" || clean == "pausa" || clean == "arrêter d'écouter" {
            return .pauseListening
        }
        if clean == "resume listening" || clean == "resume voice" || clean == "resume" || clean == "start listening" || clean == "continue listening" ||
           clean == "suno" || clean == "chalu karo" || clean == "shuru karo" || clean == "reanudar" || clean == "continuer" {
            return .resumeListening
        }
        if clean == "toggle hands free" || clean == "enable hands free" || clean == "disable hands free" || clean == "hands free mode" || clean == "hands free" ||
           clean == "bina hath ke" || clean == "manos libres" {
            return .toggleHandsFree
        }

        // MARK: - Help commands (English, Hindi, Spanish, French)
        if clean == "help" || clean == "what can i say" || clean == "commands" || clean == "instructions" || clean == "options" ||
           clean == "madad" || clean == "madad chahiye" || clean == "sahayata" || clean == "ayuda" || clean == "aide" {
            return .help
        }
        if clean.hasPrefix("help with ") || clean.hasPrefix("help for ") {
            let topic = clean
                .replacingOccurrences(of: "help with ", with: "")
                .replacingOccurrences(of: "help for ", with: "")
                .trimmingCharacters(in: .whitespaces)
            return .helpWithTopic(topic)
        }

        // MARK: - Repeat & Cancel
        if clean == "repeat that" || clean == "say again" || clean == "repeat" || clean == "pardon" || clean == "what did you say" || clean == "say that again" ||
           clean == "phir se bolo" || clean == "dobara bolo" || clean == "repetir" || clean == "répéter" {
            return .repeatSpoken
        }
        if clean == "cancel" || clean == "dismiss" || clean == "nevermind" || clean == "abort" || clean == "never mind" ||
           clean == "radd karo" || clean == "cancel karo" || clean == "cancelar" || clean == "annuler" {
            return .cancel
        }

        // MARK: - Read Learning Progress
        if clean == "read my progress" || clean == "my progress" || clean == "what is my progress" || clean == "check progress" || clean == "progress" || clean == "read progress" ||
           clean == "mera progress" || clean == "pragati batao" || clean == "progreso" {
            return .readProgress
        }

        // MARK: - Authentication & Account Navigation
        if clean == "open login" || clean == "go to login" || clean == "login" || clean == "sign in" || clean == "open sign in" || clean == "go to sign in" || clean == "login screen" || clean == "sign in screen" ||
           clean == "iniciar sesión" || clean == "connexion" {
            return .openLogin
        }
        if clean == "open sign up" || clean == "go to sign up" || clean == "sign up" || clean == "register" || clean == "create account" || clean == "new account" || clean == "open registration" || clean == "registration screen" ||
           clean == "khata banao" || clean == "nayi id banao" || clean == "registrarse" || clean == "créer un compte" {
            return .openSignUp
        }
        if clean == "open profile" || clean == "my profile" || clean == "user profile" || clean == "edit profile" ||
           clean == "meri profile" || clean == "profile kholo" || clean == "mi perfil" || clean == "mon profil" {
            return .openUserProfile
        }
        if clean == "sign out" || clean == "log out" || clean == "logout" || clean == "sign off" ||
           clean == "bahar niklo" || clean == "sign out karo" || clean == "log out karo" || clean == "cerrar sesión" || clean == "déconnexion" {
            return .signOut
        }

        // MARK: - Dynamic Language Switching via Voice
        if clean.contains("switch to hindi") || clean.contains("hindi me baat") || clean == "hindi bhasha" || clean == "hindi language" {
            return .switchLanguage(localeCode: "hi-IN")
        }
        if clean.contains("switch to spanish") || clean.contains("cambiar a español") || clean == "spanish language" {
            return .switchLanguage(localeCode: "es-ES")
        }
        if clean.contains("switch to french") || clean.contains("langue française") || clean == "french language" {
            return .switchLanguage(localeCode: "fr-FR")
        }
        if clean.contains("switch to tamil") || clean == "tamil language" {
            return .switchLanguage(localeCode: "ta-IN")
        }
        if clean.contains("switch to telugu") || clean == "telugu language" {
            return .switchLanguage(localeCode: "te-IN")
        }
        if clean.contains("switch to bengali") || clean == "bengali language" || clean == "bangla bhasha" {
            return .switchLanguage(localeCode: "bn-IN")
        }
        if clean.contains("switch to marathi") || clean == "marathi language" {
            return .switchLanguage(localeCode: "mr-IN")
        }
        if clean.contains("switch to gujarati") || clean == "gujarati language" {
            return .switchLanguage(localeCode: "gu-IN")
        }
        if clean.contains("switch to english") || clean == "speak english" || clean == "english language" || clean == "angrezi bhasha" {
            return .switchLanguage(localeCode: "en-IN")
        }

        // MARK: - Quiz Option Selection & True/False
        if let optionIndex = parseQuizOptionIndex(from: clean) {
            return .selectQuizOption(index: optionIndex)
        }
        if clean == "true" || clean == "select true" || clean == "choose true" || clean == "answer true" ||
           clean == "sahi" || clean == "haan" || clean == "sahi hai" || clean == "correct" || clean == "right" || clean == "verdadero" || clean == "vrai" {
            return .answerTrue
        }
        if clean == "false" || clean == "select false" || clean == "choose false" || clean == "answer false" ||
           clean == "galat" || clean == "nahi" || clean == "galat hai" || clean == "incorrect" || clean == "wrong" || clean == "falso" || clean == "faux" {
            return .answerFalse
        }
        if clean.contains("next question") || clean == "skip question" || clean == "proceed question" ||
           clean == "agla prashna" || clean == "agla question" || clean == "siguiente pregunta" {
            return .nextQuestion
        }

        // MARK: - Pronunciation Recording Actions
        if clean == "start recording" || clean == "start record" || clean == "begin recording" || clean == "record" || clean == "start pronunciation practice" ||
           clean == "recording shuru karo" || clean == "abhyas shuru karo" || clean == "grabar" || clean == "enregistrer" {
            if clean == "start pronunciation practice" {
                return .openPronunciation
            }
            return .startRecording
        }
        if clean == "stop recording" || clean == "stop record" || clean == "finish recording" || clean == "done recording" || clean == "stop" ||
           clean == "recording roko" || clean == "parar" || clean == "arrêter" {
            return .stopRecording
        }
        if clean.contains("re-record") || clean.contains("rerecord") || clean.contains("re record") || clean.contains("try again") || clean.contains("record again") ||
           clean == "phir se record karo" || clean == "dobara record karo" {
            return .reRecord
        }
        if clean.contains("next sentence") || clean == "next practice sentence" || clean == "agla vakya" || clean == "agla sentence" {
            return .nextSentence
        }
        if clean.contains("listen to voco") || clean.contains("listen voco") || clean == "listen" || clean == "play pronunciation" ||
           clean == "voco ko suno" || clean == "uchharan suno" || clean == "escuchar" || clean == "écouter" {
            return .listenToVoCo
        }

        // MARK: - Stories Navigation & Actions
        if clean == "stories" || clean == "open stories" || clean == "story catalog" || clean == "tell me a story" || clean == "view stories" ||
           clean == "kahani" || clean == "kahani sunao" || clean == "kahania" || clean == "historias" || clean == "contar una historia" || clean == "histoires" {
            return .openStories
        }
        if clean.hasPrefix("read story") || clean.hasPrefix("read this story") || clean.hasPrefix("open story") || clean == "read this story" || clean == "read story" ||
           clean.hasPrefix("kahani padho") || clean.hasPrefix("kahani ") {
            let identifier = parseStoryIdentifier(from: clean)
            return .readStory(identifier: identifier)
        }

        // MARK: - Non-Technical Courses & Specific Topic Semantic Matching
        if clean.contains("non-technical") || clean.contains("non technical") || clean.contains("nontech") || clean.contains("non tech") ||
           clean.contains("soft skills") || clean.contains("life skills") || clean.contains("non-technical courses dikhao") || clean.contains("non technical courses") {
            return .openNonTechnicalCourses
        }
        if clean.contains("interview") || clean.contains("star method") || clean.contains("elevator pitch") ||
           clean.contains("interview prepare karwao") || clean.contains("interview ki tayari") {
            return .openCourseTopic(topicId: "topic-interview")
        }
        if clean.contains("communication") || clean.contains("spoken english") || clean.contains("english speaking") ||
           clean.contains("angrezi bolna") || clean.contains("prep method") || clean.contains("hesitation") {
            return .openCourseTopic(topicId: "topic-communication")
        }
        if clean.contains("personality") || clean.contains("presence") || clean.contains("growth mindset") ||
           clean.contains("body language") {
            return .openCourseTopic(topicId: "topic-personality")
        }
        if clean.contains("leadership") || clean.contains("teamwork") || clean.contains("leader") ||
           clean.contains("sbi feedback") {
            return .openCourseTopic(topicId: "topic-leadership")
        }
        if clean.contains("time management") || clean.contains("productivity") || clean.contains("eisenhower") ||
           clean.contains("deep work") || clean.contains("samay prabandhan") {
            return .openCourseTopic(topicId: "topic-productivity")
        }
        if clean.contains("critical thinking") || clean.contains("problem solving") || clean.contains("first principles") ||
           clean.contains("5 whys") {
            return .openCourseTopic(topicId: "topic-criticalthinking")
        }
        if clean.contains("career") || clean.contains("networking") || clean.contains("job readiness") ||
           clean.contains("career readiness") {
            return .openCourseTopic(topicId: "topic-career")
        }
        if clean.contains("financial") || clean.contains("financial literacy") || clean.contains("finance") ||
           clean.contains("budgeting") || clean.contains("compound interest") || clean.contains("paisa") {
            return .openCourseTopic(topicId: "topic-financial")
        }

        // MARK: - Learning Quadrants & Modules
        if clean.contains("pronunciation") || clean.contains("quadrant 1") || clean.contains("practice sentence") || clean == "sentences" ||
           clean == "uchharan" || clean == "uchharan abhyas" || clean == "bolna seekho" || clean == "pronunciación" || clean == "prononciation" {
            return .openPronunciation
        }
        if clean.contains("talk") || clean.contains("bot") || clean.contains("quadrant 2") || clean.contains("conversation") || clean == "chat" ||
           clean == "baat karo" || clean == "voco se baat" || clean == "hablar con voco" || clean == "parler avec voco" {
            return .openTalkWithVoCo
        }
        if clean.contains("gyan") || clean.contains("courses") || clean.contains("lessons") || clean.contains("quadrant 3") || clean.contains("tutorials") ||
           clean == "padhai shuru karo" || clean == "courses kholo" || clean.contains("cursos") || clean.contains("cours") {
            return .openVoCoGyan
        }
        if clean.contains("game") || clean.contains("quadrant 4") || clean.contains("challenges") ||
           clean == "khel" || clean == "juegos" || clean == "jeux" {
            return .openGames
        }
        if clean.contains("quiz") || clean == "take quiz" || clean == "start quiz" || clean == "interactive quiz" ||
           clean == "prashnottari" || clean == "cuestionario" {
            return .openQuiz
        }

        // MARK: - Global Navigation (English, Hindi, Spanish, French)
        if clean == "go home" || clean == "home" || clean == "dashboard" || clean == "main screen" || clean == "go to dashboard" || clean == "take me to dashboard" ||
           clean == "ghar jao" || clean == "home jao" || clean == "dashboard jao" || clean == "inicio" || clean == "accueil" {
            return .goHome
        }
        if clean == "go back" || clean == "back" || clean == "previous screen" || clean == "previous" || clean == "return" ||
           clean == "piche jao" || clean == "wapas jao" || clean == "pichhe" || clean == "atrás" || clean == "retour" {
            return .goBack
        }

        return .unknown(phrase.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Normalization Helpers

    public func normalize(phrase: String) -> String {
        var lower = phrase.lowercased()

        // Replace common phonetic homophones or transcription variations
        lower = lower.replacingOccurrences(of: "voko", with: "voco")
        lower = lower.replacingOccurrences(of: "vocal", with: "voco")
        lower = lower.replacingOccurrences(of: "log in", with: "login")
        lower = lower.replacingOccurrences(of: "sign in", with: "login")
        lower = lower.replacingOccurrences(of: "re record", with: "re-record")
        lower = lower.replacingOccurrences(of: "handsfree", with: "hands free")

        // Remove punctuation characters except hyphens in numbers/words
        let punctuationToDrop: CharacterSet = CharacterSet.punctuationCharacters.subtracting(CharacterSet(charactersIn: "-"))
        let cleanedScalars = lower.unicodeScalars.filter { !punctuationToDrop.contains($0) }
        let cleanedString = String(cleanedScalars)

        // Collapse multiple whitespaces
        let components = cleanedString.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return components.joined(separator: " ")
    }

    // MARK: - Parameter Extraction Helpers

    private func parseQuizOptionIndex(from text: String) -> Int? {
        let words = text.components(separatedBy: " ")
        if text.contains("option 1") || text.contains("option one") || text == "first option" || text == "select 1" || text == "choose 1" || text == "pehla option" || text == "opción 1" {
            return 1
        }
        if text.contains("option 2") || text.contains("option two") || text == "second option" || text == "select 2" || text == "choose 2" || text == "doosra option" || text == "opción 2" {
            return 2
        }
        if text.contains("option 3") || text.contains("option three") || text == "third option" || text == "select 3" || text == "choose 3" || text == "teesra option" || text == "opción 3" {
            return 3
        }
        if text.contains("option 4") || text.contains("option four") || text == "fourth option" || text == "select 4" || text == "choose 4" || text == "chautha option" || text == "opción 4" {
            return 4
        }
        if let idx = words.firstIndex(of: "option"), idx + 1 < words.count {
            let nextWord = words[idx + 1]
            if let num = Int(nextWord), num >= 1 && num <= 4 {
                return num
            }
        }
        return nil
    }

    private func parseStoryIdentifier(from text: String) -> String? {
        let words = text.components(separatedBy: " ")
        if let idx = words.firstIndex(of: "story"), idx + 1 < words.count {
            let remainder = words[(idx + 1)...].joined(separator: " ")
            if remainder == "one" || remainder == "pehli" { return "1" }
            if remainder == "two" || remainder == "doosri" { return "2" }
            if remainder == "three" || remainder == "teesri" { return "3" }
            if remainder == "four" || remainder == "chauthi" { return "4" }
            return remainder
        }
        if let idx = words.firstIndex(of: "kahani"), idx + 1 < words.count {
            let remainder = words[(idx + 1)...].joined(separator: " ")
            if remainder == "one" || remainder == "pehli" || remainder == "ek" { return "1" }
            if remainder == "two" || remainder == "doosri" || remainder == "do" { return "2" }
            if remainder == "three" || remainder == "teesri" || remainder == "teen" { return "3" }
            if remainder == "four" || remainder == "chauthi" || remainder == "char" { return "4" }
            return remainder
        }
        return nil
    }
}
