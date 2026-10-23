import Foundation

/// Practice sentence used in the Pronunciation Guide workflow
public struct PracticeSentence: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let text: String
    public let category: String
    public let phoneticHint: String?
    public let difficulty: Int // 1 (Beginner) to 3 (Advanced)

    public init(
        id: String = UUID().uuidString,
        text: String,
        category: String = "General",
        phoneticHint: String? = nil,
        difficulty: Int = 1
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.phoneticHint = phoneticHint
        self.difficulty = difficulty
    }

    /// Curated seed sentences matching the Flutter app's Firestore collection
    public static let sampleSentences: [PracticeSentence] = [
        PracticeSentence(
            id: "sentence-1",
            text: "Welcome to VoCo pronunciation guide.",
            category: "Introductory",
            phoneticHint: "WEL-kum too VOH-koh pro-NUN-see-AY-shun gyde",
            difficulty: 1
        ),
        PracticeSentence(
            id: "sentence-2",
            text: "Clear communication builds strong human connections.",
            category: "Communication",
            phoneticHint: "kleer kuh-myoo-nih-KAY-shun bildz strong HYOO-mun kuh-NEK-shunz",
            difficulty: 2
        ),
        PracticeSentence(
            id: "sentence-3",
            text: "Practice speaking slowly and articulate every consonant distinctly.",
            category: "Technique",
            phoneticHint: "PRAK-tis SPEE-king SLOH-lee and ar-TIK-yuh-layt EV-ree KON-suh-nunt dih-STINKT-lee",
            difficulty: 2
        ),
        PracticeSentence(
            id: "sentence-4",
            text: "In computer science, a linked list is a linear collection of data elements.",
            category: "Technical",
            phoneticHint: "in kum-PYOO-ter SY-unce, ay LINKT list iz ay LIN-ee-er kuh-LEK-shun uv DAY-tuh EL-uh-ments",
            difficulty: 3
        ),
        PracticeSentence(
            id: "sentence-5",
            text: "The egg became hard, the potato soft, but the coffee transformed the water.",
            category: "Storytelling",
            phoneticHint: "thee EG bih-KAYM hard, thee puh-TAY-toh soft, but thee KAW-fee trans-FORMD thee WAH-ter",
            difficulty: 2
        )
    ]
}
