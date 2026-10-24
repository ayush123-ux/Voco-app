import Foundation
import SwiftUI
import Combine

/// Centralized manager for dynamic runtime language switching and multilingual TTS/STT synchronization
@MainActor
public final class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()

    private let userDefaultsKey = "voco_selected_language_code"

    @Published public private(set) var currentLanguage: AppLanguage

    public var onLanguageChanged: ((AppLanguage) -> Void)?

    public init(defaultLanguage: AppLanguage = AppLanguage.defaultLanguage) {
        if let savedCode = UserDefaults.standard.string(forKey: userDefaultsKey),
           let match = AppLanguage.standardLanguages.first(where: { $0.id == savedCode }) {
            self.currentLanguage = match
        } else {
            self.currentLanguage = defaultLanguage
        }
    }

    /// Dynamically switches the active language across all voice services
    public func setLanguage(_ language: AppLanguage, container: ServiceContainer? = nil) {
        self.currentLanguage = language
        UserDefaults.standard.set(language.id, forKey: userDefaultsKey)

        if let container = container {
            applyLanguage(to: container)
        }

        onLanguageChanged?(language)

        // Announce language switch to Apple VoiceOver
        AccessibilityHelper.announce(localizedAnnouncementForSwitch(to: language))
    }

    /// Synchronizes language settings with the current ServiceContainer
    public func applyLanguage(to container: ServiceContainer) {
        let verifiedSTTLocale = currentLanguage.verifiedSpeechLocaleIdentifier
        container.speechRecognizer.setLocale(verifiedSTTLocale)
        container.speechService.defaultLanguage = currentLanguage.id
    }

    /// Localized speech confirmation when switching languages
    public func localizedAnnouncementForSwitch(to language: AppLanguage) -> String {
        switch language.id {
        case "mr-IN":
            return "भाषा मराठीमध्ये बदलली आहे. आता तुम्ही मराठीत बोलू शकता."
        case "hi-IN":
            return "भाषा अब हिन्दी में सेट कर दी गई है। अब आप हिन्दी में बोल सकते हैं।"
        case "en-IN", "en-US":
            return "Language changed to English. You can speak in English now."
        case "ta-IN":
            return "மொழி இப்போது தமிழில் மாற்றப்பட்டுள்ளது. நீங்கள் இப்போது தமிழில் பேசலாம்."
        case "te-IN":
            return "భాష తెలుగులోకి మార్చబడింది. మీరు ఇప్పుడు తెలుగులో మాట్లాడవచ్చు."
        case "bn-IN":
            return "भाषा বাংলায় পরিবর্তিত হয়েছে। আপনি এখন বাংলায় কথা বলতে পারেন।"
        case "gu-IN":
            return "ભાષા ગુજરાતીમાં બદલાઈ ગઈ છે. હવે તમે ગુજરાતીમાં બોલી શકો છો."
        case "kn-IN":
            return "ಭಾಷೆಯನ್ನು ಕನ್ನಡಕ್ಕೆ ಬದಲಾಯಿಸಲಾಗಿದೆ. ನೀವು ಈಗ ಕನ್ನಡದಲ್ಲಿ ಮಾತನಾಡಬಹುದು."
        case "ml-IN":
            return "ഭാഷ മലയാളത്തിലേക്ക് മാറ്റി. നിങ്ങൾക്ക് ഇപ്പോൾ മലയാളത്തിൽ സംസാരിക്കാം."
        case "pa-IN":
            return "ਭਾਸ਼ਾ ਪੰਜਾਬੀ ਵਿੱਚ ਬਦਲ ਦਿੱਤੀ ਗਈ ਹੈ। ਹੁਣ ਤੁਸੀਂ ਪੰਜਾਬੀ ਵਿੱਚ ਬੋਲ ਸਕਦੇ ਹੋ।"
        case "es-ES":
            return "El idioma ha cambiado a español. Ahora puedes hablar en español."
        case "fr-FR":
            return "La langue a été changée en français. Vous pouvez maintenant parler en français."
        case "de-DE":
            return "Die Sprache wurde auf Deutsch umgestellt. Sie können jetzt auf Deutsch sprechen."
        default:
            return "Language switched to \(language.name)."
        }
    }

    /// Localized explanation when an unsupported language is requested
    public func localizedUnsupportedFeedback(for requested: String) -> String {
        switch currentLanguage.id {
        case "mr-IN":
            return "ही भाषा '\(requested)' उपलब्ध नाही. तुम्ही मराठी, हिन्दी, किंवा इंग्रजी निवडू शकता."
        case "hi-IN":
            return "यह भाषा '\(requested)' समर्थित नहीं है। आप हिन्दी, मराठी या अंग्रेज़ी चुन सकते हैं।"
        default:
            return "The language '\(requested)' is not supported. Supported languages include Marathi, Hindi, English, Tamil, Telugu, and more."
        }
    }

    /// Localized welcome / help prompt
    public func localizedHelpPrompt() -> String {
        switch currentLanguage.id {
        case "mr-IN":
            return "व्होको मदत: तुम्ही 'तांत्रिक कोर्सेस उघडा', 'क्विझ सुरू करा', 'उच्चार सराव', 'गोष्टी', किंवा 'मागे जा' असे बोलू शकता."
        case "hi-IN":
            return "वोको सहायता: आप कह सकते हैं 'तकनीकी कोर्सेस खोलो', 'उच्चारण अभ्यास', 'कहानियाँ सुनाओ', 'क्विज़ शुरू करो', या 'पीछे जाओ'।"
        case "es-ES":
            return "Ayuda de voz VoCo: Puede decir 'abrir cursos', 'pronunciación', 'historias', 'iniciar cuestionario', o 'ir atrás'."
        case "fr-FR":
            return "Aide vocale VoCo: Vous pouvez dire 'ouvrir les cours', 'prononciation', 'histoires', 'commencer le quiz', ou 'retour'."
        default:
            return "VoCo Voice Help: You can say 'open technical courses', 'start quiz', 'pronunciation', 'stories', or 'go back'."
        }
    }

    /// Localized clarification prompt when intent is ambiguous
    public func localizedClarificationPrompt(for topic: String) -> String {
        switch currentLanguage.id {
        case "mr-IN":
            return "तुम्हाला \(topic) उघडायचे आहे का? कृपया खात्री करण्यासाठी 'हो' म्हणा."
        case "hi-IN":
            return "क्या आपका मतलब \(topic) से था? कृपया स्पष्ट करें।"
        case "es-ES":
            return "¿Se refiere a \(topic)? Por favor confirme."
        default:
            return "Did you mean \(topic)? Please say yes to confirm or specify your choice."
        }
    }

    /// Localized unknown command feedback
    public func localizedUnknownFeedback(for phrase: String) -> String {
        switch currentLanguage.id {
        case "mr-IN":
            if phrase.isEmpty {
                return "आवाज ऐकू आला नाही. कृपया पुन्हा बोला."
            }
            return "आज्ञा समजली नाही: '\(phrase)'. उपलब्ध पर्यायांसाठी 'मदत' म्हणा."
        case "hi-IN":
            if phrase.isEmpty {
                return "कोई आवाज़ नहीं मिली। कृपया दोबारा बोलें।"
            }
            return "माफ़ कीजिए, '\(phrase)' समझ नहीं आया। उपलब्ध विकल्पों के लिए 'मदद' कहें।"
        case "es-ES":
            return "No entendí '\(phrase)'. Diga 'ayuda' para ver las opciones."
        default:
            if phrase.isEmpty {
                return "No speech detected. Please try speaking again."
            }
            return "Command not recognized: \(phrase). Say 'help' for available commands."
        }
    }
}
