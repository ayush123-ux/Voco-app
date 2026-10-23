import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

/// Cloud Firestore service that mirrors Flutter's FirebaseFirestore.instance.collection('sentences') query
public final class FirestoreSentenceService: SentenceServiceProtocol, @unchecked Sendable {
    public init() {}

    public func fetchSentences() async throws -> [PracticeSentence] {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let snapshot = try await db.collection("sentences").getDocuments()
        let sentences: [PracticeSentence] = snapshot.documents.compactMap { doc -> PracticeSentence? in
            let data = doc.data()
            // Flutter code fetched element['sentence'] or element['quote']
            guard let text = (data["quote"] as? String) ?? (data["sentence"] as? String) else {
                return nil
            }
            let category = data["category"] as? String ?? "General"
            let hint = data["hint"] as? String
            let difficulty = data["difficulty"] as? Int ?? 1
            return PracticeSentence(
                id: doc.documentID,
                text: text,
                category: category,
                phoneticHint: hint,
                difficulty: difficulty
            )
        }
        return sentences.isEmpty ? PracticeSentence.sampleSentences : sentences
        #else
        // Fallback to sample sentences when Firestore SDK is not yet linked
        return PracticeSentence.sampleSentences
        #endif
    }
}
