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
        case "hi-IN":
            return "भाषा अब हिन्दी में सेट कर दी गई है।"
        case "ta-IN":
            return "மொழி இப்போது தமிழில் மாற்றப்பட்டுள்ளது."
        case "te-IN":
            return "భాష ఇప్పుడు తెలుగులోకి మార్చబడింది."
        case "bn-IN":
            return "ভাষা এখন বাংলায় সেট করা হয়েছে।"
        case "mr-IN":
            return "भाषा आता मराठी मध्ये सेट केली आहे."
        case "es-ES":
            return "Idioma cambiado a español."
        case "fr-FR":
            return "Langue changée en français."
        case "de-DE":
            return "Sprache auf Deutsch umgestellt."
        default:
            return "Language switched to \(language.name)."
        }
    }

    /// Localized welcome / help prompt
    public func localizedHelpPrompt() -> String {
        switch currentLanguage.id {
        case "hi-IN":
            return "VoCo आवाज़ सहायता: आप कह सकते हैं 'courses kholo', 'uchharan abhyas', 'stories sunao', 'quiz shuru karo', ya 'piche jao'."
        case "es-ES":
            return "Ayuda de voz VoCo: Puede decir 'abrir cursos', 'pronunciación', 'historias', 'iniciar cuestionario', o 'ir atrás'."
        case "fr-FR":
            return "Aide vocale VoCo: Vous pouvez dire 'ouvrir les cours', 'prononciation', 'histoires', 'commencer le quiz', ou 'retour'."
        default:
            return "VoCo Voice Help: You can say 'open courses', 'pronunciation', 'stories', 'start quiz', or 'go back'."
        }
    }

    /// Localized clarification prompt when intent is ambiguous
    public func localizedClarificationPrompt(for topic: String) -> String {
        switch currentLanguage.id {
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
        case "hi-IN":
            return "माफ़ कीजिए, '\(phrase)' समझ नहीं आया। आप 'courses kholo', 'uchharan', ya 'madad' कह सकते हैं।"
        case "es-ES":
            return "No entendí '\(phrase)'. Puede decir 'abrir cursos', 'pronunciación', o 'ayuda'."
        default:
            return "Command not recognized: '\(phrase)'. Say 'open courses', 'pronunciation', or 'help' for options."
        }
    }
}
