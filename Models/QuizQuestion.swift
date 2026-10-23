import Foundation

/// Represents a True/False quiz question conforming to the original Flutter quiz schema
public struct QuizQuestion: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let prompt: String
    public let correctAnswer: Bool
    public let explanation: String?

    public init(
        id: String = UUID().uuidString,
        prompt: String,
        correctAnswer: Bool,
        explanation: String? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }

    /// Curated questions preserved directly from the Flutter StartQuiz.dart source
    public static let standardQuestions: [QuizQuestion] = [
        QuizQuestion(
            id: "q1",
            prompt: "Linked List is similar to an array in memory placement.",
            correctAnswer: false,
            explanation: "In a linked list, elements are not stored in contiguous physical memory locations. Instead, each node contains a pointer to the next node."
        ),
        QuizQuestion(
            id: "q2",
            prompt: "VoCo is designed exclusively for people who are deaf.",
            correctAnswer: false,
            explanation: "VoCo is designed for language learners, speech practice, and assistive communication for anyone working on pronunciation."
        ),
        QuizQuestion(
            id: "q3",
            prompt: "The original prototype of VoCo was built using Flutter.",
            correctAnswer: true,
            explanation: "The original cross-platform codebase was created in Flutter with Dart."
        ),
        QuizQuestion(
            id: "q4",
            prompt: "VoCo helps people learn new languages and technical terminology through voice.",
            correctAnswer: true,
            explanation: "VoCo pairs audio narratives and technical courses with active pronunciation drills."
        ),
        QuizQuestion(
            id: "q5",
            prompt: "In the coffee beans moral story, the coffee beans changed the boiling water entirely.",
            correctAnswer: true,
            explanation: "The coffee beans released aroma and flavor, illustrating positive adaptation under pressure."
        )
    ]
}
