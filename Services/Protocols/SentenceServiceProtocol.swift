import Foundation

/// Defines practice sentence fetching capabilities
public protocol SentenceServiceProtocol: AnyObject, Sendable {
    /// Fetches practice sentences for the pronunciation guide
    func fetchSentences() async throws -> [PracticeSentence]
}
