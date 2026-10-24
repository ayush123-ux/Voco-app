import Foundation
import Speech
import AVFoundation

/// Geographical / Cultural region for languages
public enum LanguageRegion: String, CaseIterable, Identifiable, Hashable, Sendable {
    case indian = "Indian Languages"
    case international = "International Languages"

    public var id: String { rawValue }
}

/// Represents a supported spoken language with locale information and device compatibility
public struct AppLanguage: Identifiable, Hashable, Sendable {
    public let id: String                 // BCP-47 identifier e.g. "hi-IN", "en-IN"
    public let name: String               // English name e.g. "Hindi", "Indian English"
    public let nativeName: String         // Native script e.g. "हिन्दी", "தமிழ்"
    public let region: LanguageRegion
    public let flagEmoji: String

    public init(id: String, name: String, nativeName: String, region: LanguageRegion, flagEmoji: String) {
        self.id = id
        self.name = name
        self.nativeName = nativeName
        self.region = region
        self.flagEmoji = flagEmoji
    }

    /// Complete catalogue of verified Indian and International languages
    public static let standardLanguages: [AppLanguage] = [
        // MARK: - Indian Languages
        AppLanguage(id: "en-IN", name: "Indian English", nativeName: "English (India)", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "hi-IN", name: "Hindi", nativeName: "हिन्दी", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "ta-IN", name: "Tamil", nativeName: "தமிழ்", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "te-IN", name: "Telugu", nativeName: "తెలుగు", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "bn-IN", name: "Bengali", nativeName: "বাংলা", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "mr-IN", name: "Marathi", nativeName: "मराठी", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "gu-IN", name: "Gujarati", nativeName: "ગુજરાતી", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "kn-IN", name: "Kannada", nativeName: "ಕನ್ನಡ", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "ml-IN", name: "Malayalam", nativeName: "മലയാളം", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "pa-IN", name: "Punjabi", nativeName: "ਪੰਜਾਬੀ", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "or-IN", name: "Odia", nativeName: "ଓଡ଼ିଆ", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "as-IN", name: "Assamese", nativeName: "অসমীয়া", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "ur-IN", name: "Urdu", nativeName: "اردو", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "sa-IN", name: "Sanskrit", nativeName: "संस्कृतम्", region: .indian, flagEmoji: "🇮🇳"),
        AppLanguage(id: "ne-IN", name: "Nepali", nativeName: "नेपाली", region: .indian, flagEmoji: "🇳🇵"),

        // MARK: - International Languages
        AppLanguage(id: "en-US", name: "US English", nativeName: "English (US)", region: .international, flagEmoji: "🇺🇸"),
        AppLanguage(id: "es-ES", name: "Spanish", nativeName: "Español", region: .international, flagEmoji: "🇪🇸"),
        AppLanguage(id: "fr-FR", name: "French", nativeName: "Français", region: .international, flagEmoji: "🇫🇷"),
        AppLanguage(id: "de-DE", name: "German", nativeName: "Deutsch", region: .international, flagEmoji: "🇩🇪"),
        AppLanguage(id: "pt-BR", name: "Portuguese", nativeName: "Português (Brasil)", region: .international, flagEmoji: "🇧🇷"),
        AppLanguage(id: "ar-SA", name: "Arabic", nativeName: "العربية", region: .international, flagEmoji: "🇸🇦"),
        AppLanguage(id: "zh-CN", name: "Mandarin Chinese", nativeName: "中文 (简体)", region: .international, flagEmoji: "🇨🇳"),
        AppLanguage(id: "ja-JP", name: "Japanese", nativeName: "日本語", region: .international, flagEmoji: "🇯🇵"),
        AppLanguage(id: "ko-KR", name: "Korean", nativeName: "한국어", region: .international, flagEmoji: "🇰🇷"),
        AppLanguage(id: "ru-RU", name: "Russian", nativeName: "Русский", region: .international, flagEmoji: "🇷🇺")
    ]

    /// Default language for VoCo
    public static let defaultLanguage: AppLanguage = standardLanguages[0] // en-IN

    /// Returns the verified matching locale identifier supported on this device
    public var verifiedSpeechLocaleIdentifier: String {
        #if os(iOS)
        let target = Locale(identifier: id)
        let supported = SFSpeechRecognizer.supportedLocales()
        if supported.contains(target) {
            return id
        }
        // Try matching by 2-character language prefix
        let prefix = String(id.prefix(2))
        if let match = supported.first(where: { $0.identifier.hasPrefix(prefix) }) {
            return match.identifier
        }
        // Fallback: Indian English for Indian languages, US English for international
        return region == .indian ? "en-IN" : "en-US"
        #else
        return id
        #endif
    }

    /// Whether this locale is supported by SFSpeechRecognizer on this device
    public var isSpeechRecognitionAvailable: Bool {
        #if os(iOS)
        let target = Locale(identifier: id)
        let supported = SFSpeechRecognizer.supportedLocales()
        if supported.contains(target) { return true }
        let prefix = String(id.prefix(2))
        return supported.contains { $0.identifier.hasPrefix(prefix) }
        #else
        return true
        #endif
    }
}
