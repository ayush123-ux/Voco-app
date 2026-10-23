import Foundation
import SwiftUI
import Combine

/// Manages interactive True/False quiz execution preserving StartQuiz.dart behavior
@MainActor
public final class QuizViewModel: ObservableObject {
    @Published public private(set) var questions: [QuizQuestion] = []
    @Published public private(set) var currentIndex: Int = 0
    @Published public private(set) var score: Int = 0
    @Published public private(set) var selectedAnswer: Bool?
    @Published public private(set) var isAnswerSubmitted: Bool = false
    @Published public private(set) var isQuizCompleted: Bool = false

    public init(questions: [QuizQuestion] = QuizQuestion.standardQuestions) {
        self.questions = questions.isEmpty ? QuizQuestion.standardQuestions : questions
    }

    public var currentQuestion: QuizQuestion? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    public var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(questions.count)
    }

    public var percentageScore: Int {
        guard !questions.isEmpty else { return 0 }
        return Int((Double(score) / Double(questions.count)) * 100)
    }

    public func answerCurrentQuestion(with answer: Bool) {
        guard !isAnswerSubmitted, let question = currentQuestion else { return }

        selectedAnswer = answer
        isAnswerSubmitted = true

        if answer == question.correctAnswer {
            score += 1
        }
    }

    public func nextQuestion() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            selectedAnswer = nil
            isAnswerSubmitted = false
        } else {
            isQuizCompleted = true
        }
    }

    public func resetQuiz() {
        currentIndex = 0
        score = 0
        selectedAnswer = nil
        isAnswerSubmitted = false
        isQuizCompleted = false
    }
}
