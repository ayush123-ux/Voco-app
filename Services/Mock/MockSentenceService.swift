import Foundation

/// Offline sentence service providing instant access to pronunciation sentences
public final class MockSentenceService: SentenceServiceProtocol, @unchecked Sendable {
    private var sentences: [PracticeSentence]

    public init(initialSentences: [PracticeSentence] = PracticeSentence.sampleSentences) {
        self.sentences = initialSentences
    }

    public func fetchSentences() async throws -> [PracticeSentence] {
        // Simulated lightweight latency
        try? await Task.sleep(nanoseconds: 100_000_000)
        return sentences
    }

    public func appendSentence(_ sentence: PracticeSentence) {
        sentences.append(sentence)
    }
}
