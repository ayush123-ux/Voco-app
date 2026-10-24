import Foundation

/// Fast deterministic mock for AIServiceProtocol to enable comprehensive unit testing
public final class MockAIService: AIServiceProtocol, @unchecked Sendable {
    public var isBackendReachable: Bool = true
    public var backendURL: URL = URL(string: "http://localhost:8080")!

    public var lastSentMessage: String?
    public var lastSentLanguage: String?
    public var simulatedReply: String?
    public var simulatedInterpretation: AICommandInterpretation?

    public init(simulatedReply: String? = nil) {
        self.simulatedReply = simulatedReply
    }

    public func checkHealth() async -> Bool {
        return isBackendReachable
    }

    public func sendMessage(_ text: String, history: [AIChatMessage], language: String) async -> AIChatResponse {
        lastSentMessage = text
        lastSentLanguage = language

        if let reply = simulatedReply {
            return AIChatResponse(reply: reply, language: language, status: "mock_success", source: "mock")
        }

        let isHindi = language.lowercased().contains("hindi")
        let lower = text.lowercased()

        if lower.contains("binary search") {
            let r = isHindi ? "बाइनरी सर्च एक कुशल खोज एल्गोरिथ्म है।" : "Binary search divides the sorted array in half."
            return AIChatResponse(reply: r, language: language, status: "mock_success", source: "mock")
        } else if lower.contains("linked list") {
            let r = isHindi ? "लिंक्ड लिस्ट में नोड्स पॉइंटर से जुड़े होते हैं।" : "A linked list connects nodes via references."
            return AIChatResponse(reply: r, language: language, status: "mock_success", source: "mock")
        } else {
            let r = isHindi ? "नमस्ते, मैं वोको हूँ।" : "Hello from VoCo mock AI."
            return AIChatResponse(reply: r, language: language, status: "mock_success", source: "mock")
        }
    }

    public func interpretCommand(phrase: String, currentScreen: String, language: String) async -> AICommandInterpretation? {
        if let sim = simulatedInterpretation {
            return sim
        }

        let p = phrase.lowercased()
        if p.contains("technical courses") || p.contains("tech course") {
            return AICommandInterpretation(action: "openTechnicalCourses", parameters: nil, confidence: 0.98)
        } else if p.contains("quiz") {
            return AICommandInterpretation(action: "openQuiz", parameters: nil, confidence: 0.95)
        } else if p.contains("first episode") || p.contains("episode 1") {
            return AICommandInterpretation(action: "openEpisodeNumber", parameters: ["number": "1"], confidence: 0.95)
        } else if p.contains("linked list") {
            return AICommandInterpretation(action: "openCourseTopic", parameters: ["topicId": "topic-dsa"], confidence: 0.95)
        }
        return nil
    }
}
