import Foundation

/// Real implementation of AIServiceProtocol connecting securely to the VoCo Gemini backend proxy.
/// Architecture:
/// - iOS app NEVER holds or compiles the GEMINI_API_KEY.
/// - All AI requests are dispatched to the VoCo backend which holds the key securely in an environment variable.
/// - If the backend is unreachable or offline, GeminiAIService gracefully provides local speech-friendly answers.
public final class GeminiAIService: AIServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let lock = NSLock()
    private var _backendURL: URL
    private var _isBackendReachable: Bool = false

    public var backendURL: URL {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _backendURL
        }
        set {
            lock.lock()
            _backendURL = newValue
            lock.unlock()
            UserDefaults.standard.set(newValue.absoluteString, forKey: "voco_ai_backend_url")
        }
    }

    public var isBackendReachable: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isBackendReachable
    }

    public init(session: URLSession = .shared) {
        self.session = session
        let saved = UserDefaults.standard.string(forKey: "voco_ai_backend_url")
        if let savedStr = saved, let url = URL(string: savedStr) {
            self._backendURL = url
        } else {
            // Default to local Mac development IP or localhost
            self._backendURL = URL(string: "http://10.21.70.127:8080")!
        }
    }

    public func checkHealth() async -> Bool {
        let healthURL = backendURL.appendingPathComponent("health")
        var request = URLRequest(url: healthURL)
        request.timeoutInterval = 3.0
        request.httpMethod = "GET"

        do {
            let (data, response) = try await session.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String, status == "healthy" {
                    lock.lock()
                    _isBackendReachable = true
                    lock.unlock()
                    return true
                }
            }
        } catch {
            // Backend offline or unreachable
        }

        lock.lock()
        _isBackendReachable = false
        lock.unlock()
        return false
    }

    public func sendMessage(_ text: String, history: [AIChatMessage], language: String) async -> AIChatResponse {
        let sanitized = sanitize(text)
        guard !sanitized.isEmpty else {
            return AIChatResponse(
                reply: "I could not hear any text. Please try asking again.",
                language: language,
                status: "empty_input",
                source: "local"
            )
        }

        let chatURL = backendURL.appendingPathComponent("api/chat")
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "message": sanitized,
            "language": language,
            "history": history.map { ["role": $0.role, "text": sanitize($0.text)] }
        ]

        if let bodyData = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = bodyData
            do {
                let (data, response) = try await session.data(for: request)
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                    if let res = try? JSONDecoder().decode(AIChatResponse.self, from: data) {
                        lock.lock()
                        _isBackendReachable = true
                        lock.unlock()
                        return res
                    }
                }
            } catch {
                // Network error or timeout: fall back gracefully
            }
        }

        lock.lock()
        _isBackendReachable = false
        lock.unlock()

        // Local intelligence fallback
        let fallback = localFallbackAnswer(for: sanitized, language: language)
        return AIChatResponse(
            reply: fallback,
            language: language,
            status: "offline_fallback",
            source: "local_device",
            warning: "Gemini backend unreachable. Responded with local tutor knowledge."
        )
    }

    public func interpretCommand(phrase: String, currentScreen: String, language: String) async -> AICommandInterpretation? {
        let sanitized = sanitize(phrase)
        guard !sanitized.isEmpty else { return nil }

        let endpoint = backendURL.appendingPathComponent("api/interpret_command")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 4.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "phrase": sanitized,
            "currentScreen": currentScreen,
            "language": language
        ]

        if let bodyData = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = bodyData
            do {
                let (data, response) = try await session.data(for: request)
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                    if let decoded = try? JSONDecoder().decode(AICommandInterpretation.self, from: data) {
                        return decoded
                    }
                }
            } catch {
                return nil
            }
        }
        return nil
    }

    private func sanitize(_ str: String) -> String {
        // Redact any occurrences of passwords, credentials, tokens
        var s = str
        let patterns = [
            "(?i)password[:=]\\s*\\S+",
            "(?i)token[:=]\\s*\\S+",
            "(?i)pin[:=]\\s*\\S+"
        ]
        for p in patterns {
            if let regex = try? NSRegularExpression(pattern: p) {
                s = regex.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "[REDACTED]")
            }
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func localFallbackAnswer(for query: String, language: String) -> String {
        let q = query.lowercased()
        let isHindi = language.lowercased().contains("hindi") || language.lowercased().contains("hinglish")

        if q.contains("binary search") {
            return isHindi
                ? "बाइनरी सर्च सॉर्टेड लिस्ट में आधे हिस्से को छांटकर किसी भी एलिमेंट को बहुत तेजी से खोज लेता है।"
                : "Binary search is an efficient search algorithm that finds an item in a sorted list by repeatedly dividing the search interval in half."
        } else if q.contains("linked list") {
            return isHindi
                ? "लिंक्ड लिस्ट एक लीनियर डेटा स्ट्रक्चर है जिसमें हर नोड अगले नोड का पॉइंटर स्टोर करता है।"
                : "A linked list is a linear data structure where elements are connected by pointers rather than stored contiguously in memory."
        } else if q.contains("vowel") {
            return isHindi
                ? "अंग्रेजी में पांच स्वर ए, ई, आई, ओ, यू होते हैं। उच्चारण में अपनी आवाज़ को खुले मुंह से स्पष्ट निकालें।"
                : "The five pure vowels are A, E, I, O, and U. Practice shaping your mouth openly to articulate each sound."
        } else if q.contains("tongue twister") {
            return isHindi
                ? "एक मजेदार अभ्यास: 'समझ समझ के समझ को समझो'। इसे स्पष्टता से बोलने का प्रयास करें।"
                : "Here is a classic speech exercise: 'She sells seashells by the seashore.' Focus on contrasting the sharp S and soft SH sounds."
        } else if isHindi {
            return "नमस्ते! मैं वोको हूँ। आप मुझसे उच्चारण, डेटा स्ट्रक्चर्स, या क्विज़ के बारे में बात कर सकते हैं।"
        } else {
            return "Hello! I am VoCo, your voice companion. You can ask me to explain concepts, practice pronunciation, or navigate courses."
        }
    }
}
