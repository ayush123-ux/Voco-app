import Foundation

/// Defines all recognized voice command intents across VoCoNative
public enum VoiceCommandIntent: Equatable, Hashable {
    // Screen Navigation
    case openPronunciation
    case openTalkWithVoCo
    case openVoCoGyan
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

    /// Spoken confirmation feedback to speak back to the user
    public var spokenConfirmation: String {
        switch self {
        case .openPronunciation:
            return "Opening Pronunciation Guide."
        case .openTalkWithVoCo:
            return "Opening Talk with VoCo."
        case .openVoCoGyan:
            return "Opening VoCo Gyan lessons."
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
        }
    }
}

/// Pure Swift parser converting speech-recognized text into structured VoiceCommandIntents
public struct VoiceCommandParser {
    public init() {}

    /// Parses spoken transcriptions into structured intents with normalization and parameter extraction
    public func parse(phrase: String) -> VoiceCommandIntent {
        let clean = normalize(phrase: phrase)

        guard !clean.isEmpty else {
            return .unknown("")
        }

        // Hands-Free & Privacy commands
        if clean == "pause listening" || clean == "pause voice" || clean == "pause" || clean == "hold on" || clean == "stop listening" {
            return .pauseListening
        }
        if clean == "resume listening" || clean == "resume voice" || clean == "resume" || clean == "start listening" || clean == "continue listening" {
            return .resumeListening
        }
        if clean == "toggle hands free" || clean == "enable hands free" || clean == "disable hands free" || clean == "hands free mode" || clean == "hands free" {
            return .toggleHandsFree
        }

        // Help commands
        if clean == "help" || clean == "what can i say" || clean == "commands" || clean == "instructions" || clean == "options" {
            return .help
        }
        if clean.hasPrefix("help with ") || clean.hasPrefix("help for ") {
            let topic = clean
                .replacingOccurrences(of: "help with ", with: "")
                .replacingOccurrences(of: "help for ", with: "")
                .trimmingCharacters(in: .whitespaces)
            return .helpWithTopic(topic)
        }

        // General: Repeat that / Say again
        if clean == "repeat that" || clean == "say again" || clean == "repeat" || clean == "pardon" || clean == "what did you say" || clean == "say that again" {
            return .repeatSpoken
        }

        // General: Cancel / Dismiss
        if clean == "cancel" || clean == "dismiss" || clean == "nevermind" || clean == "abort" || clean == "never mind" {
            return .cancel
        }

        // General: Read my progress
        if clean == "read my progress" || clean == "my progress" || clean == "what is my progress" || clean == "check progress" || clean == "progress" || clean == "read progress" {
            return .readProgress
        }

        // Authentication & Account Navigation
        if clean == "open login" || clean == "go to login" || clean == "login" || clean == "sign in" || clean == "open sign in" || clean == "go to sign in" || clean == "login screen" || clean == "sign in screen" {
            return .openLogin
        }
        if clean == "open sign up" || clean == "go to sign up" || clean == "sign up" || clean == "register" || clean == "create account" || clean == "new account" || clean == "open registration" || clean == "registration screen" {
            return .openSignUp
        }
        if clean == "open profile" || clean == "my profile" || clean == "user profile" || clean == "edit profile" {
            return .openUserProfile
        }
        if clean == "sign out" || clean == "log out" || clean == "logout" || clean == "sign off" {
            return .signOut
        }

        // Quiz Option Selection ("select option one", "option 1", "choose option 2", etc.)
        if let optionIndex = parseQuizOptionIndex(from: clean) {
            return .selectQuizOption(index: optionIndex)
        }

        // Quiz True / False
        if clean == "true" || clean == "select true" || clean == "choose true" || clean == "answer true" {
            return .answerTrue
        }
        if clean == "false" || clean == "select false" || clean == "choose false" || clean == "answer false" {
            return .answerFalse
        }

        // Quiz Progression
        if clean.contains("next question") || clean == "skip question" || clean == "proceed question" {
            return .nextQuestion
        }

        // Pronunciation Recording actions
        if clean == "start recording" || clean == "start record" || clean == "begin recording" || clean == "record" || clean == "start pronunciation practice" {
            if clean == "start pronunciation practice" {
                return .openPronunciation
            }
            return .startRecording
        }
        if clean == "stop recording" || clean == "stop record" || clean == "finish recording" || clean == "done recording" || clean == "stop" {
            return .stopRecording
        }
        if clean.contains("re-record") || clean.contains("rerecord") || clean.contains("re record") || clean.contains("try again") || clean.contains("record again") {
            return .reRecord
        }
        if clean.contains("next sentence") || clean == "next practice sentence" {
            return .nextSentence
        }
        if clean.contains("listen to voco") || clean.contains("listen voco") || clean == "listen" || clean == "play pronunciation" {
            return .listenToVoCo
        }

        // Stories Navigation & Actions
        if clean == "stories" || clean == "open stories" || clean == "story catalog" || clean == "tell me a story" || clean == "view stories" {
            return .openStories
        }
        if clean.hasPrefix("read story") || clean.hasPrefix("read this story") || clean.hasPrefix("open story") || clean == "read this story" || clean == "read story" {
            let identifier = parseStoryIdentifier(from: clean)
            return .readStory(identifier: identifier)
        }

        // Learning Navigation: Quadrants & Modules
        if clean.contains("pronunciation") || clean.contains("quadrant 1") || clean.contains("practice sentence") || clean == "sentences" {
            return .openPronunciation
        }
        if clean.contains("talk") || clean.contains("bot") || clean.contains("quadrant 2") || clean.contains("conversation") || clean == "chat" {
            return .openTalkWithVoCo
        }
        if clean.contains("gyan") || clean.contains("courses") || clean.contains("lessons") || clean.contains("quadrant 3") || clean.contains("tutorials") {
            return .openVoCoGyan
        }
        if clean.contains("game") || clean.contains("quadrant 4") || clean.contains("challenges") {
            return .openGames
        }
        if clean.contains("quiz") || clean == "take quiz" || clean == "start quiz" || clean == "interactive quiz" {
            return .openQuiz
        }

        // Global Navigation
        if clean == "go home" || clean == "home" || clean == "dashboard" || clean == "main screen" || clean == "go to dashboard" || clean == "take me to dashboard" {
            return .goHome
        }
        if clean == "go back" || clean == "back" || clean == "previous screen" || clean == "previous" || clean == "return" {
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
        if text.contains("option 1") || text.contains("option one") || text == "first option" || text == "select 1" || text == "choose 1" {
            return 1
        }
        if text.contains("option 2") || text.contains("option two") || text == "second option" || text == "select 2" || text == "choose 2" {
            return 2
        }
        if text.contains("option 3") || text.contains("option three") || text == "third option" || text == "select 3" || text == "choose 3" {
            return 3
        }
        if text.contains("option 4") || text.contains("option four") || text == "fourth option" || text == "select 4" || text == "choose 4" {
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
            if remainder == "one" { return "1" }
            if remainder == "two" { return "2" }
            if remainder == "three" { return "3" }
            if remainder == "four" { return "4" }
            return remainder
        }
        return nil
    }
}
