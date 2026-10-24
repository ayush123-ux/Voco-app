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
    case openEpisode(episodeNumber: Int)
    case openEpisodeByTitle(title: String)
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
    case acknowledgeOK
    case continueAction
    case unknown(String)

    // Hands-Free & Privacy Actions
    case pauseListening
    case resumeListening
    case toggleHandsFree

    // Multilingual & Disambiguation
    case switchLanguage(localeCode: String)
    case unsupportedLanguage(requested: String)
    case clarificationNeeded(prompt: String, suggestedOptions: [String])

    /// Default spoken confirmation feedback in English (preserves test backwards-compatibility)
    public var spokenConfirmation: String {
        return localizedSpokenConfirmation(languageCode: "en-IN")
    }

    /// Localized spoken confirmation for a specific AppLanguage
    public func localizedSpokenConfirmation(for language: AppLanguage) -> String {
        return localizedSpokenConfirmation(languageCode: language.id)
    }

    /// Returns the localized spoken confirmation for any target language locale code
    public func localizedSpokenConfirmation(languageCode: String) -> String {
        let code = languageCode.lowercased()

        if code.hasPrefix("mr") {
            switch self {
            case .openPronunciation:
                return "उच्चार सराव उघडत आहे."
            case .openTalkWithVoCo:
                return "व्होको संभाषण सुरू करत आहे."
            case .openVoCoGyan:
                return "व्होको ज्ञान उघडत आहे."
            case .openTechnicalCourses:
                return "तांत्रिक कोर्सेस उघडत आहे."
            case .openNonTechnicalCourses:
                return "अतांत्रिक कोर्सेस उघडत आहे."
            case .openCourseTopic:
                return "अभ्यासक्रम उघडत आहे."
            case .openEpisode(let number):
                return "सत्र \(number) उघडत आहे."
            case .openEpisodeByTitle(let title):
                return "\(title) सत्र उघडत आहे."
            case .openGames:
                return "खेळ आणि आव्हाने उघडत आहे."
            case .openStories:
                return "गोष्टींची सूची उघडत आहे."
            case .readStory(let id):
                return id != nil ? "गोष्ट \(id!) उघडत आहे." : "गोष्ट उघडत आहे."
            case .openQuiz:
                return "व्होको क्विझ सुरू करत आहे."
            case .openLogin:
                return "साइन इन उघडत आहे."
            case .openSignUp:
                return "साइन अप उघडत आहे."
            case .openUserProfile:
                return "प्रोफाइल उघडत आहे."
            case .goHome:
                return "मुख्यपृष्ठावर परत जात आहे."
            case .goBack:
                return "मागे जात आहे."
            case .signOut:
                return "साइन आउट करत आहे."
            case .startRecording:
                return "रेकॉर्डिंग सुरू केले. आता बोला."
            case .stopRecording:
                return "रेकॉर्डिंग थांबवले."
            case .nextSentence:
                return "पुढच्या वाक्याकडे जात आहे."
            case .reRecord:
                return "पुन्हा रेकॉर्ड करण्यासाठी तयार."
            case .listenToVoCo:
                return "उच्चार ऐकवत आहे."
            case .answerTrue:
                return "बरोबर निवडले."
            case .answerFalse:
                return "चूक निवडले."
            case .selectQuizOption(let index):
                return "पर्याय \(index) निवडला."
            case .nextQuestion:
                return "पुढचा प्रश्न."
            case .repeatSpoken:
                return "पुन्हा सांगत आहे."
            case .cancel:
                return "रद्द केले."
            case .readProgress:
                return "तुमची प्रगती तपासत आहे."
            case .help, .helpWithTopic:
                return "व्होको मदत: तुम्ही तांत्रिक कोर्सेस, क्विझ, उच्चार, किंवा मागे जा असे बोलू शकता."
            case .acknowledgeOK:
                return "ठीक आहे."
            case .continueAction:
                return "पुढे चालू ठेवत आहे."
            case .unknown(let query):
                return query.isEmpty ? "आवाज ऐकू आला नाही. कृपया पुन्हा बोला." : "आज्ञा समजली नाही: '\(query)'. मदतीसाठी 'मदत' म्हणा."
            case .pauseListening:
                return "आवाज ऐकणे थांबवले आहे."
            case .resumeListening:
                return "आवाज ऐकणे पुन्हा सुरू केले आहे."
            case .toggleHandsFree:
                return "हँड्स-फ्री मोड बदलला आहे."
            case .switchLanguage:
                return "भाषा मराठीमध्ये बदलली आहे. आता तुम्ही मराठीत बोलू शकता."
            case .unsupportedLanguage(let req):
                return "ही भाषा '\(req)' उपलब्ध नाही. तुम्ही मराठी, हिन्दी किंवा इंग्रजी निवडू शकता."
            case .clarificationNeeded(let prompt, _):
                return prompt
            }
        }

        if code.hasPrefix("hi") {
            switch self {
            case .openPronunciation:
                return "उच्चारण अभ्यास खोल रहे हैं।"
            case .openTalkWithVoCo:
                return "वोको बातचीत शुरू कर रहे हैं।"
            case .openVoCoGyan:
                return "वोको ज्ञान खोल रहे हैं।"
            case .openTechnicalCourses:
                return "तकनीकी कोर्सेस खोल रहे हैं।"
            case .openNonTechnicalCourses:
                return "गैर-तकनीकी कोर्सेस खोल रहे हैं।"
            case .openCourseTopic:
                return "कोर्स खोल रहे हैं।"
            case .openEpisode(let number):
                return "एपिसोड \(number) खोल रहे हैं।"
            case .openEpisodeByTitle(let title):
                return "\(title) सत्र खोल रहे हैं।"
            case .openGames:
                return "खेल और चुनौतियाँ खोल रहे हैं।"
            case .openStories:
                return "कहानियों की सूची खोल रहे हैं।"
            case .readStory(let id):
                return id != nil ? "कहानी \(id!) खोल रहे हैं।" : "कहानी खोल रहे हैं।"
            case .openQuiz:
                return "वोको क्विज़ शुरू कर रहे हैं।"
            case .openLogin:
                return "साइन इन खोल रहे हैं।"
            case .openSignUp:
                return "साइन अप खोल रहे हैं।"
            case .openUserProfile:
                return "प्रोफ़ाइल खोल रहे हैं।"
            case .goHome:
                return "होम स्क्रीन पर वापस जा रहे हैं।"
            case .goBack:
                return "पीछे जा रहे हैं।"
            case .signOut:
                return "साइन आउट कर रहे हैं।"
            case .startRecording:
                return "रिकॉर्डिंग शुरू हो गई। अब बोलिए।"
            case .stopRecording:
                return "रिकॉर्डिंग रोक दी गई।"
            case .nextSentence:
                return "अगले वाक्य पर जा रहे हैं।"
            case .reRecord:
                return "फिर से रिकॉर्ड करने के लिए तैयार।"
            case .listenToVoCo:
                return "उच्चारण सुना रहे हैं।"
            case .answerTrue:
                return "सही चुना गया।"
            case .answerFalse:
                return "गलत चुना गया।"
            case .selectQuizOption(let index):
                return "विकल्प \(index) चुना गया।"
            case .nextQuestion:
                return "अगले प्रश्न पर जा रहे हैं।"
            case .repeatSpoken:
                return "फिर से बता रहे हैं।"
            case .cancel:
                return "रद्द कर दिया गया।"
            case .readProgress:
                return "आपकी सीखने की प्रगति जाँची जा रही है।"
            case .help, .helpWithTopic:
                return "वोको सहायता: आप तकनीकी कोर्सेस, क्विज़, उच्चारण, कहानियाँ या पीछे जाओ बोल सकते हैं।"
            case .acknowledgeOK:
                return "ठीक है।"
            case .continueAction:
                return "आगे बढ़ रहे हैं।"
            case .unknown(let query):
                return query.isEmpty ? "कोई आवाज़ नहीं मिली। कृपया दोबारा बोलें।" : "माफ़ कीजिए, '\(query)' समझ नहीं आया। 'मदद' कहें।"
            case .pauseListening:
                return "वॉइस सुनना रोक दिया गया है।"
            case .resumeListening:
                return "वॉइस सुनना फिर से शुरू किया गया है।"
            case .toggleHandsFree:
                return "हैंड्स-फ्री मोड बदल दिया गया है।"
            case .switchLanguage:
                return "भाषा अब हिन्दी में सेट कर दी गई है। अब आप हिन्दी में बोल सकते हैं।"
            case .unsupportedLanguage(let req):
                return "यह भाषा '\(req)' समर्थित नहीं है। आप हिन्दी, मराठी या अंग्रेज़ी चुन सकते हैं।"
            case .clarificationNeeded(let prompt, _):
                return prompt
            }
        }

        // Default English
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
            if let topic = CourseTopic.standardTopics.first(where: { $0.id == topicId }) {
                return "Opening \(topic.title)."
            }
            return "Opening course."
        case .openEpisode(let number):
            return "Opening Episode \(number)."
        case .openEpisodeByTitle(let title):
            return "Opening \(title) session."
        case .openGames:
            return "Opening Games and Challenges."
        case .openStories:
            return "Opening Moral Story Catalog."
        case .readStory(let identifier):
            if let id = identifier {
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
        case .acknowledgeOK:
            return "OK."
        case .continueAction:
            return "Continuing."
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
        case .unsupportedLanguage(let req):
            return "The language '\(req)' is not supported. Supported languages include Marathi, Hindi, English, Tamil, Telugu, and more."
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

        // MARK: - Global Priority: Dynamic Language Switching via Voice
        if let languageIntent = parseLanguageSwitchIntent(clean: clean) {
            return languageIntent
        }

        // MARK: - Hands-Free & Privacy commands (English, Hindi, Marathi & Multilingual)
        if clean == "pause listening" || clean == "pause voice" || clean == "pause" || clean == "hold on" || clean == "stop listening" ||
           clean == "awaaz roko" || clean == "suno mat" || clean == "ruko" || clean == "shant raho" || clean == "pausa" || clean == "arréter d'écouter" ||
           clean == "ऐकणे थांबवा" || clean == "थांबा" || clean == "आवाज थांबवा" || clean == "aawaz thambva" || clean == "thamba" {
            return .pauseListening
        }
        if clean == "resume listening" || clean == "resume voice" || clean == "resume" || clean == "start listening" || clean == "continue listening" ||
           clean == "suno" || clean == "chalu karo" || clean == "shuru karo" || clean == "reanudar" || clean == "continuer" ||
           clean == "ऐकणे सुरू करा" || clean == "सुरू करा" || clean == "चालू करा" || clean == "suru kara" || clean == "chalu kara" {
            return .resumeListening
        }
        if clean == "toggle hands free" || clean == "enable hands free" || clean == "disable hands free" || clean == "hands free mode" || clean == "hands free" ||
           clean == "bina hath ke" || clean == "manos libres" || clean == "हँड्स फ्री" || clean == "हँड्सफ्री" || clean == "handsfree" {
            return .toggleHandsFree
        }

        // MARK: - Help commands (English, Marathi, Hindi, Spanish, French)
        if clean == "help" || clean == "what can i say" || clean == "commands" || clean == "instructions" || clean == "options" ||
           clean == "madad" || clean == "madad chahiye" || clean == "sahayata" || clean == "ayuda" || clean == "aide" ||
           clean == "मदत" || clean == "साहाय्य" || clean == "मदत करा" || clean == "madat" || clean == "madat kara" {
            return .help
        }
        if clean.hasPrefix("help with ") || clean.hasPrefix("help for ") || clean.hasPrefix("मदत ") {
            let topic = clean
                .replacingOccurrences(of: "help with ", with: "")
                .replacingOccurrences(of: "help for ", with: "")
                .replacingOccurrences(of: "मदत ", with: "")
                .trimmingCharacters(in: .whitespaces)
            return .helpWithTopic(topic)
        }

        // MARK: - OK & Acknowledgements
        if clean == "ok" || clean == "okay" || clean == "theek hai" || clean == "thik hai" || clean == "accha" || clean == "sure" || clean == "alright" ||
           clean == "ठीक आहे" || clean == "हो" || clean == "thik ahe" || clean == "barobar ahe" {
            return .acknowledgeOK
        }

        // MARK: - Continue
        if clean == "continue" || clean == "aage badho" || clean == "agla" || clean == "carry on" || clean == "proceed" ||
           clean == "पुढे चला" || clean == "चालू ठेवा" || clean == "पुढे जा" || clean == "pudhe chala" || clean == "pudhe ja" {
            return .continueAction
        }

        // MARK: - Repeat & Cancel commands
        if clean == "repeat" || clean == "repeat that" || clean == "repeat please" || clean == "phir se bolo" || clean == "dobara bolo" ||
           clean == "say again" || clean == "pardon" || clean == "repetir" || clean == "répéter" ||
           clean == "पुन्हा सांगा" || clean == "परत सांगा" || clean == "पुन्हा बोला" || clean == "punha sanga" || clean == "parat sanga" {
            return .repeatSpoken
        }
        if clean == "cancel" || clean == "abort" || clean == "never mind" || clean == "stop it" || clean == "dismiss" ||
           clean == "radd karo" || clean == "cancel karo" || clean == "cancelar" || clean == "annuler" ||
           clean == "रद्द करा" || clean == "थांबवा" || clean == "radd kara" {
            return .cancel
        }

        // MARK: - Read Learning Progress
        if clean == "read my progress" || clean == "my progress" || clean == "what is my progress" || clean == "check progress" || clean == "progress" || clean == "read progress" ||
           clean == "mera progress" || clean == "pragati batao" || clean == "progreso" ||
           clean == "प्रगती सांगा" || clean == "माझी प्रगती" || clean == "pragati sanga" {
            return .readProgress
        }

        // MARK: - Authentication & Account Navigation
        if clean == "open login" || clean == "go to login" || clean == "login" || clean == "sign in" || clean == "open sign in" || clean == "go to sign in" || clean == "login screen" || clean == "sign in screen" ||
           clean.contains("help me login") || clean.contains("help me log in") || clean.contains("help me sign in") ||
           clean == "iniciar sesión" || clean == "connexion" || clean == "साइन इन" || clean == "साइन इन करा" || clean == "लॉगिन" {
            return .openLogin
        }
        if clean == "open sign up" || clean == "go to sign up" || clean == "sign up" || clean == "register" || clean == "create account" || clean == "new account" || clean == "open registration" || clean == "registration screen" ||
           clean == "khata banao" || clean == "nayi id banao" || clean == "registrarse" || clean == "créer un compte" ||
           clean == "साइन अप" || clean == "साइन अप करा" || clean == "खाते तयार करा" {
            return .openSignUp
        }
        if clean == "open profile" || clean == "my profile" || clean == "user profile" || clean == "edit profile" ||
           clean == "meri profile" || clean == "profile kholo" || clean == "mi perfil" || clean == "mon profil" ||
           clean == "प्रोफाइल" || clean == "माझी प्रोफाइल" || clean == "प्रोफाइल उघडा" {
            return .openUserProfile
        }
        if clean == "sign out" || clean == "log out" || clean == "logout" || clean == "sign off" ||
           clean == "bahar niklo" || clean == "sign out karo" || clean == "log out karo" || clean == "cerrar sesión" || clean == "déconnexion" ||
           clean == "साइन आउट" || clean == "साइन आउट करा" || clean == "बाहेर पडा" {
            return .signOut
        }

        // MARK: - Quiz Option Selection & True/False (Multilingual)
        if let optionIndex = parseQuizOptionIndex(from: clean) {
            return .selectQuizOption(index: optionIndex)
        }
        if clean == "true" || clean == "select true" || clean == "choose true" || clean == "answer true" ||
           clean == "sahi" || clean == "haan" || clean == "sahi hai" || clean == "correct" || clean == "right" || clean == "verdadero" || clean == "vrai" ||
           clean == "बरोबर" || clean == "सत्य" || clean == "योग्य" || clean == "होय" || clean == "खरे" || clean == "barobar" || clean == "satya" {
            return .answerTrue
        }
        if clean == "false" || clean == "select false" || clean == "choose false" || clean == "answer false" ||
           clean == "galat" || clean == "nahi" || clean == "galat hai" || clean == "incorrect" || clean == "wrong" || clean == "falso" || clean == "faux" ||
           clean == "चूक" || clean == "असत्य" || clean == "अयोग्य" || clean == "नाही" || clean == "खोटे" || clean == "chook" || clean == "asatya" {
            return .answerFalse
        }
        if clean.contains("next question") || clean == "skip question" || clean == "proceed question" ||
           clean == "agla prashna" || clean == "agla question" || clean == "siguiente pregunta" ||
           clean == "पुढचा प्रश्न" || clean == "पुढील प्रश्न" || clean == "pudhcha prashna" || clean == "pudhil prashna" {
            return .nextQuestion
        }

        // MARK: - Pronunciation Recording Actions
        if clean == "start recording" || clean == "start record" || clean == "begin recording" || clean == "record" || clean == "start pronunciation practice" ||
           clean == "recording shuru karo" || clean == "abhyas shuru karo" || clean == "grabar" || clean == "enregistrer" ||
           clean == "रेकॉर्डिंग सुरू करा" || clean == "उच्चार सराव सुरू करा" || clean == "recording suru kara" {
            if clean == "start pronunciation practice" || clean == "उच्चार सराव सुरू करा" {
                return .openPronunciation
            }
            return .startRecording
        }
        if clean == "stop recording" || clean == "stop record" || clean == "finish recording" || clean == "done recording" || clean == "stop" ||
           clean == "recording roko" || clean == "parar" || clean == "arrêter" ||
           clean == "रेकॉर्डिंग थांबवा" || clean == "recording thambva" {
            return .stopRecording
        }
        if clean.contains("re-record") || clean.contains("rerecord") || clean.contains("re record") || clean.contains("try again") || clean.contains("record again") ||
           clean == "phir se record karo" || clean == "dobara record karo" ||
           clean == "पुन्हा रेकॉर्ड करा" || clean == "punha record kara" {
            return .reRecord
        }
        if clean.contains("next sentence") || clean == "next practice sentence" || clean == "agla vakya" || clean == "agla sentence" ||
           clean == "पुढचे वाक्य" || clean == "pudhche vakya" {
            return .nextSentence
        }
        if clean.contains("listen to voco") || clean.contains("listen voco") || clean == "listen" || clean == "play pronunciation" ||
           clean == "voco ko suno" || clean == "uchharan suno" || clean == "escuchar" || clean == "écouter" ||
           clean == "व्होको ऐका" || clean == "उच्चार ऐका" || clean == "uchchar aika" {
            return .listenToVoCo
        }

        // MARK: - Stories Navigation & Actions
        if clean == "stories" || clean == "open stories" || clean == "story catalog" || clean == "tell me a story" || clean == "view stories" ||
           clean == "kahani" || clean == "kahani sunao" || clean == "kahania" || clean == "historias" || clean == "contar una historia" || clean == "histoires" ||
           clean == "गोष्टी" || clean == "कथा" || clean == "गोष्ट ऐका" || clean == "गोष्टी उघडा" || clean == "गोष्टी सांगा" || clean == "goshti" {
            return .openStories
        }
        if clean.hasPrefix("read story") || clean.hasPrefix("read this story") || clean.hasPrefix("open story") || clean == "read this story" || clean == "read story" ||
           clean.hasPrefix("kahani padho") || clean.hasPrefix("kahani ") || clean.hasPrefix("गोष्ट वाचा ") || clean.hasPrefix("गोष्ट ") {
            let identifier = parseStoryIdentifier(from: clean)
            return .readStory(identifier: identifier)
        }

        // MARK: - Non-Technical Courses (Precedes technical to avoid substring match)
        if clean.contains("non-technical") || clean.contains("non technical") || clean.contains("nontech") || clean.contains("non tech") ||
           clean.contains("soft skills") || clean.contains("life skills") || clean.contains("non-technical courses dikhao") || clean.contains("non technical courses") ||
           clean.contains("अतांत्रिक") || clean.contains("atantrik") || clean.contains("गैर तकनीकी") {
            return .openNonTechnicalCourses
        }

        // MARK: - Technical Courses & Sessions (Precedes generic courses match)
        if clean.contains("technical courses") || clean.contains("technical course") || clean.contains("tech courses") || clean.contains("open technical courses") || clean.contains("tech course") || clean == "technical" || clean.contains("technical padhao") ||
           clean.contains("तांत्रिक") || clean.contains("तंत्रज्ञान") || clean.contains("tantrik") || clean.contains("तकनीकी") ||
           clean.contains("தொழில்நுட்ப") || clean.contains("సాంకేతిక") {
            return .openTechnicalCourses
        }
        if clean.contains("first episode") || clean.contains("episode 1") || clean.contains("ep 1") || clean.contains("ep1") || clean == "play first episode" || clean == "open the first episode" ||
           clean.contains("पहिले सत्र") || clean.contains("पहिला एपिसोड") || clean.contains("सत्र एक") || clean.contains("धडा पहिला") {
            return .openEpisode(episodeNumber: 1)
        }
        if clean.contains("linked list") || clean.contains("linkedlist") || clean.contains("लिंक्ड लिस्ट") {
            return .openEpisodeByTitle(title: "Linked List")
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
           clean == "uchharan" || clean == "uchharan abhyas" || clean == "bolna seekho" || clean == "pronunciación" || clean == "prononciation" ||
           clean.contains("उच्चार") || clean.contains("उच्चारण") || clean.contains("uchchar") {
            return .openPronunciation
        }
        if clean.contains("talk") || clean.contains("bot") || clean.contains("quadrant 2") || clean.contains("conversation") || clean == "chat" ||
           clean == "baat karo" || clean == "voco se baat" || clean == "hablar con voco" || clean == "parler avec voco" ||
           clean.contains("बोला") || clean.contains("गप्पा मारा") || clean.contains("संभाषण") || clean == "voco shi bola" {
            return .openTalkWithVoCo
        }
        if clean.contains("gyan") || clean.contains("courses") || clean.contains("lessons") || clean.contains("quadrant 3") || clean.contains("tutorials") ||
           clean == "padhai shuru karo" || clean == "courses kholo" || clean.contains("cursos") || clean.contains("cours") ||
           clean.contains("ज्ञान") || clean.contains("अभ्यासक्रम") || clean == "voco gyan" || clean == "gyan" {
            return .openVoCoGyan
        }
        if clean.contains("game") || clean.contains("quadrant 4") || clean.contains("challenges") ||
           clean == "khel" || clean == "juegos" || clean == "jeux" ||
           clean.contains("खेळ") || clean == "khel ughada" {
            return .openGames
        }
        if clean.contains("quiz") || clean.contains("take quiz") || clean.contains("start quiz") || clean.contains("take me to the quiz") || clean.contains("take me to quiz") ||
           clean.contains("interactive quiz") || clean.contains("prashnottari") || clean.contains("cuestionario") ||
           clean.contains("क्विझ") || clean.contains("प्रश्नावली") || clean == "quiz suru kara" || clean == "quiz shuru karo" {
            return .openQuiz
        }

        // MARK: - Global Navigation (English, Hindi, Marathi, Spanish, French)
        if clean == "go home" || clean == "home" || clean == "dashboard" || clean == "main screen" || clean == "go to dashboard" || clean == "take me to dashboard" ||
           clean == "ghar jao" || clean == "home jao" || clean == "dashboard jao" || clean == "inicio" || clean == "accueil" ||
           clean == "मुख्यपृष्ठ" || clean == "मुखपृष्ठ" || clean == "घरी जा" || clean == "मुख्यपृष्ठावर जा" || clean == "होम" || clean == "mukhya prushtha" {
            return .goHome
        }
        if clean == "go back" || clean == "back" || clean == "previous screen" || clean == "previous" || clean == "return" ||
           clean == "piche jao" || clean == "wapas jao" || clean == "pichhe" || clean == "atrás" || clean == "retour" ||
           clean == "मागे जा" || clean == "परत जा" || clean == "मागे" || clean == "मागे फिरा" || clean == "mage ja" || clean == "parat ja" {
            return .goBack
        }

        return .unknown(phrase.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Dynamic Language Switching Parser

    private func parseLanguageSwitchIntent(clean: String) -> VoiceCommandIntent? {
        let prefixes = [
            "change language to ", "switch language to ", "set language to ",
            "change language ", "switch language ",
            "switch to ", "change to ",
            "speak in ", "talk in ",
            "bhasha badlo ", "bhasha badla ",
            "भाषा बदला ", "भाषा बदला", "भाषा "
        ]

        // 1. Direct language identifiers / phrases
        if clean == "marathi" || clean == "मराठी" || clean == "marathi bhasha" || clean == "मराठी भाषा" ||
           clean == "marathi language" || clean == "marathit bola" || clean == "marathi madhe bola" ||
           clean == "मराठीत बोला" || clean == "बोल मराठी" || clean.contains("bhasha marathi") ||
           clean.contains("मराठीमध्ये बदला") || clean.contains("मराठी करा") {
            return .switchLanguage(localeCode: "mr-IN")
        }

        if clean == "hindi" || clean == "हिन्दी" || clean == "हिंदी" || clean == "hindi bhasha" ||
           clean == "हिन्दी भाषा" || clean == "hindi language" || clean == "hindi mein bolo" ||
           clean == "hindi me baat" || clean == "हिन्दी में बात करो" || clean == "shuddh hindi" ||
           clean.contains("bhasha hindi") || clean.contains("हिन्दी में बदलो") || clean.contains("हिंदी करा") {
            return .switchLanguage(localeCode: "hi-IN")
        }

        if clean == "hinglish" || clean.contains("hinglish") || clean.contains("mujhse hinglish mein baat karo") || clean.contains("hinglish mein bolo") || clean == "hinglish language" {
            return .switchLanguage(localeCode: "hi-IN")
        }

        if clean == "english" || clean == "angrezi" || clean == "angreji" || clean == "अंग्रेजी" || clean == "इंग्रजी" || clean == "इंग्लिश" ||
           clean == "english language" || clean == "angrezi bhasha" || clean == "speak english" || clean == "talk in english" || clean == "english please" {
            return .switchLanguage(localeCode: "en-IN")
        }

        if clean == "tamil" || clean == "தமிழ்" || clean == "tamil bhasha" || clean == "tamil language" || clean.contains("tamilil pesu") || clean.contains("தமிழில் பேசு") {
            return .switchLanguage(localeCode: "ta-IN")
        }

        if clean == "telugu" || clean == "తెలుగు" || clean == "telugu bhasha" || clean == "telugu language" || clean.contains("telugulo matladu") {
            return .switchLanguage(localeCode: "te-IN")
        }

        if clean == "bengali" || clean == "bangla" || clean == "বাংলা" || clean == "bangla bhasha" || clean == "bengali language" {
            return .switchLanguage(localeCode: "bn-IN")
        }

        if clean == "gujarati" || clean == "gujrati" || clean == "ગુજરાતી" || clean == "gujarati language" {
            return .switchLanguage(localeCode: "gu-IN")
        }

        if clean == "kannada" || clean == "ಕನ್ನಡ" || clean == "kannada language" {
            return .switchLanguage(localeCode: "kn-IN")
        }

        if clean == "malayalam" || clean == "മലയാളം" || clean == "malayalam language" {
            return .switchLanguage(localeCode: "ml-IN")
        }

        if clean == "punjabi" || clean == "ਪੰਜਾਬੀ" || clean == "punjabi language" {
            return .switchLanguage(localeCode: "pa-IN")
        }

        if clean == "spanish" || clean == "español" || clean == "espanol" || clean == "spanish language" || clean == "cambiar a español" || clean == "idioma español" {
            return .switchLanguage(localeCode: "es-ES")
        }

        if clean == "french" || clean == "français" || clean == "francais" || clean == "french language" || clean == "langue française" || clean == "changer en français" {
            return .switchLanguage(localeCode: "fr-FR")
        }

        if clean == "german" || clean == "deutsch" || clean == "german language" || clean == "deutsche sprache" || clean == "auf deutsch umstellen" {
            return .switchLanguage(localeCode: "de-DE")
        }

        // 2. Prefixed language switching
        for prefix in prefixes {
            if clean.hasPrefix(prefix) {
                let target = clean.replacingOccurrences(of: prefix, with: "").trimmingCharacters(in: .whitespaces)
                guard !target.isEmpty else { continue }

                // Disambiguation: Check known non-language keywords so "switch to quiz" doesn't trigger language switch
                let nonLanguageKeywords = ["technical", "non-technical", "course", "courses", "quiz", "stories", "games", "home", "back", "login", "profile", "pronunciation", "gyan", "first episode"]
                if nonLanguageKeywords.contains(where: { target.contains($0) }) {
                    return nil
                }

                if target.contains("marathi") || target.contains("मराठी") {
                    return .switchLanguage(localeCode: "mr-IN")
                }
                if target.contains("hindi") || target.contains("हिन्दी") || target.contains("हिंदी") {
                    return .switchLanguage(localeCode: "hi-IN")
                }
                if target.contains("hinglish") {
                    return .switchLanguage(localeCode: "hi-IN")
                }
                if target.contains("english") || target.contains("angrezi") || target.contains("अंग्रेजी") || target.contains("इंग्रजी") {
                    return .switchLanguage(localeCode: "en-IN")
                }
                if target.contains("tamil") || target.contains("தமிழ்") {
                    return .switchLanguage(localeCode: "ta-IN")
                }
                if target.contains("telugu") || target.contains("తెలుగు") {
                    return .switchLanguage(localeCode: "te-IN")
                }
                if target.contains("bengali") || target.contains("bangla") || target.contains("বাংলা") {
                    return .switchLanguage(localeCode: "bn-IN")
                }
                if target.contains("gujarati") || target.contains("gujrati") || target.contains("ગુજરાતી") {
                    return .switchLanguage(localeCode: "gu-IN")
                }
                if target.contains("kannada") || target.contains("ಕನ್ನಡ") {
                    return .switchLanguage(localeCode: "kn-IN")
                }
                if target.contains("malayalam") || target.contains("മലയാളം") {
                    return .switchLanguage(localeCode: "ml-IN")
                }
                if target.contains("punjabi") || target.contains("ਪੰਜਾਬੀ") {
                    return .switchLanguage(localeCode: "pa-IN")
                }
                if target.contains("spanish") || target.contains("español") || target.contains("espanol") {
                    return .switchLanguage(localeCode: "es-ES")
                }
                if target.contains("french") || target.contains("français") || target.contains("francais") {
                    return .switchLanguage(localeCode: "fr-FR")
                }
                if target.contains("german") || target.contains("deutsch") {
                    return .switchLanguage(localeCode: "de-DE")
                }
                if target.contains("odia") || target.contains("oriya") {
                    return .switchLanguage(localeCode: "or-IN")
                }
                if target.contains("assamese") || target.contains("asomiya") {
                    return .switchLanguage(localeCode: "as-IN")
                }
                if target.contains("urdu") {
                    return .switchLanguage(localeCode: "ur-IN")
                }
                if target.contains("sanskrit") || target.contains("संस्कृत") {
                    return .switchLanguage(localeCode: "sa-IN")
                }
                if target.contains("nepali") || target.contains("नेपाली") {
                    return .switchLanguage(localeCode: "ne-IN")
                }

                // If explicit language phrasing was used with an unrecognized language, return unsupported
                if prefix.contains("language") || prefix.contains("bhasha") || prefix.contains("speak in") || prefix.contains("talk in") || prefix.contains("भाषा") {
                    return .unsupportedLanguage(requested: target)
                }
            }
        }

        return nil
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
        return cleanedString
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func parseStoryIdentifier(from phrase: String) -> String? {
        if phrase.contains("story 1") || phrase.contains("story one") || phrase.contains("first story") || phrase.contains("peheli kahani") || phrase.contains("number 1") || phrase.contains("पहिली गोष्ट") || phrase.contains("1") {
            return "1"
        }
        if phrase.contains("story 2") || phrase.contains("story two") || phrase.contains("second story") || phrase.contains("dusri kahani") || phrase.contains("number 2") || phrase.contains("दुसरी गोष्ट") || phrase.contains("2") {
            return "2"
        }
        if phrase.contains("story 3") || phrase.contains("third story") || phrase.contains("teesri kahani") || phrase.contains("number 3") || phrase.contains("तिसरी गोष्ट") || phrase.contains("3") {
            return "3"
        }
        if phrase.contains("story 4") || phrase.contains("fourth story") || phrase.contains("chauthi kahani") || phrase.contains("number 4") || phrase.contains("चौथी गोष्ट") || phrase.contains("4") {
            return "4"
        }
        return nil
    }

    private func parseQuizOptionIndex(from phrase: String) -> Int? {
        if phrase == "option 1" || phrase == "option one" || phrase == "choose 1" || phrase == "first option" || phrase == "option a" ||
           phrase == "पर्याय एक" || phrase == "पहिला पर्याय" || phrase == "विकल्प 1" || phrase == "विकल्प एक" {
            return 1
        }
        if phrase == "option 2" || phrase == "option two" || phrase == "choose 2" || phrase == "second option" || phrase == "option b" ||
           phrase == "पर्याय दोन" || phrase == "दुसरा पर्याय" || phrase == "विकल्प 2" || phrase == "विकल्प दो" {
            return 2
        }
        if phrase == "option 3" || phrase == "option three" || phrase == "third option" || phrase == "option c" ||
           phrase == "पर्याय तीन" || phrase == "तीसरा विकल्प" {
            return 3
        }
        if phrase == "option 4" || phrase == "option four" || phrase == "fourth option" || phrase == "option d" ||
           phrase == "पर्याय चार" || phrase == "चौथा विकल्प" {
            return 4
        }
        return nil
    }
}
