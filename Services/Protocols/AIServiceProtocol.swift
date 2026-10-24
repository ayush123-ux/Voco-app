import Foundation

/// Chat turn payload for conversational AI interactions
public struct AIChatMessage: Codable, Equatable, Sendable {
    public let role: String // "user" or "model"
    public let text: String

    public init(role: String, text: String) {
        self.role = role
        self.text = text
    }
}

/// Structured response returned by VoCo AI intelligence service
public struct AIChatResponse: Codable, Equatable, Sendable {
    public let reply: String
    public let language: String
    public let status: String
    public let source: String
    public let warning: String?

    public init(
        reply: String,
        language: String = "English",
        status: String = "success",
        source: String = "gemini",
        warning: String? = nil
    ) {
        self.reply = reply
        self.language = language
        self.status = status
        self.source = source
        self.warning = warning
    }
}

/// Structured command interpretation returned by Gemini intent classifier
public struct AICommandInterpretation: Codable, Equatable, Sendable {
    public let action: String
    public let parameters: [String: String]?
    public let confidence: Double

    public init(action: String, parameters: [String: String]? = nil, confidence: Double = 1.0) {
        self.action = action
        self.parameters = parameters
        self.confidence = confidence
    }
}

/// Contract for VoCo Conversational AI & Gemini integration
public protocol AIServiceProtocol: AnyObject, Sendable {
    var isBackendReachable: Bool { get }
    var backendURL: URL { get set }
    func sendMessage(_ text: String, history: [AIChatMessage], language: String) async -> AIChatResponse
    func interpretCommand(phrase: String, currentScreen: String, language: String) async -> AICommandInterpretation?
    func checkHealth() async -> Bool
}
