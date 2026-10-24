import SwiftUI

/// True/False Interactive Quiz screen preserving StartQuiz.dart logic and score alerts,
/// with full voice-first automated question narration, option reading, and validation feedback.
public struct InteractiveQuizView: View {
    @ObservedObject public var viewModel: QuizViewModel
    @ObservedObject public var container: ServiceContainer
    public let onExitToHome: () -> Void

    @State private var hasAnnouncedInitialQuestion = false
    @State private var isNarrating = false

    public init(
        viewModel: QuizViewModel,
        container: ServiceContainer,
        onExitToHome: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.container = container
        self.onExitToHome = onExitToHome
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Progress Bar & Question Counter
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Score: \(viewModel.score)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                ProgressView(value: viewModel.progress)
                    .tint(.blue)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Spacer()

            // Question Card
            if let question = viewModel.currentQuestion {
                VStack(spacing: 16) {
                    Text("QUESTION")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1.5)
                        .foregroundColor(.blue)

                    Text(question.prompt)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 8)

                    // Repeat audio button for voice accessibility
                    Button {
                        readCurrentQuestionWithOptions()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Repeat Question")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Repeat question and answer options")
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Question \(viewModel.currentIndex + 1): \(question.prompt)")
            }

            // Explanation / Feedback Box after answer submission
            if viewModel.isAnswerSubmitted, let question = viewModel.currentQuestion {
                let isCorrect = viewModel.selectedAnswer == question.correctAnswer
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(isCorrect ? .green : .red)
                            .accessibilityHidden(true)
                        Text(isCorrect ? "Correct!" : "Incorrect")
                            .font(.headline)
                            .foregroundColor(isCorrect ? .green : .red)
                    }

                    if let explanation = question.explanation {
                        Text(explanation)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(14)
                .padding(.horizontal, 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(isCorrect ? "Correct!" : "Incorrect.") \(question.explanation ?? "")")
            }

            Spacer()

            // Action Buttons: TRUE & FALSE or Next Question
            if !viewModel.isAnswerSubmitted {
                HStack(spacing: 16) {
                    // True Button
                    Button {
                        submitAnswer(true)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("TRUE")
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.green)
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 6, y: 3)
                    }
                    .accessibilityLabel("Select True")
                    .accessibilityHint("Submits True as your answer")
                    .accessibilityAddTraits(.isButton)

                    // False Button
                    Button {
                        submitAnswer(false)
                    } label: {
                        HStack {
                            Image(systemName: "xmark")
                            Text("FALSE")
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red)
                        .cornerRadius(16)
                        .shadow(color: .red.opacity(0.3), radius: 6, y: 3)
                    }
                    .accessibilityLabel("Select False")
                    .accessibilityHint("Submits False as your answer")
                    .accessibilityAddTraits(.isButton)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            } else {
                Button {
                    advanceQuestion()
                } label: {
                    HStack {
                        Text(viewModel.currentIndex + 1 < viewModel.questions.count ? "Next Question" : "See Final Results")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .accessibilityLabel(viewModel.currentIndex + 1 < viewModel.questions.count ? "Next Question" : "See Final Results")
                .accessibilityHint("Proceeds to the next item")
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("VoCo Quiz")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if !hasAnnouncedInitialQuestion {
                hasAnnouncedInitialQuestion = true
                announceQuizStartAndFirstQuestion()
            }
        }
        .onDisappear {
            container.speechService.stopSpeaking()
        }
        .alert("Quiz Completed!", isPresented: Binding(
            get: { viewModel.isQuizCompleted },
            set: { _ in }
        )) {
            Button("Play Again") {
                viewModel.resetQuiz()
                hasAnnouncedInitialQuestion = true
                announceQuizStartAndFirstQuestion()
            }
            Button("Return to Home", role: .cancel) {
                onExitToHome()
            }
        } message: {
            Text("You answered \(viewModel.score) out of \(viewModel.questions.count) correctly (\(viewModel.percentageScore)%).")
        }
    }

    private func announceQuizStartAndFirstQuestion() {
        Task {
            guard let q = viewModel.currentQuestion else { return }
            let langId = LanguageManager.shared.currentLanguage.id
            let text: String
            if langId.contains("mr") {
                text = "व्होको क्विझ सुरू होत आहे. प्रश्न 1 / \(viewModel.questions.count): \(q.prompt). पर्याय 1: बरोबर. पर्याय 2: चूक. मी ऐकत आहे. तुम्ही आता बरोबर किंवा चूक म्हणू शकता."
            } else if langId.contains("hi") {
                text = "वोको क्विज़ शुरू हो रहा है। प्रश्न 1 / \(viewModel.questions.count): \(q.prompt)। विकल्प 1: सही। विकल्प 2: गलत। मैं सुन रहा हूँ। आप सही या गलत बोल सकते हैं।"
            } else {
                text = "Starting VoCo Quiz. Question 1 of \(viewModel.questions.count): \(q.prompt). Option 1: True. Option 2: False. I'm listening. You can say True or False now."
            }
            await container.speechService.speak(text: text)
            AccessibilityHelper.announce(text)
        }
    }

    private func readCurrentQuestionWithOptions() {
        guard let q = viewModel.currentQuestion else { return }
        Task {
            let langId = LanguageManager.shared.currentLanguage.id
            let text: String
            if langId.contains("mr") {
                text = "प्रश्न \(viewModel.currentIndex + 1) / \(viewModel.questions.count): \(q.prompt). पर्याय 1: बरोबर. पर्याय 2: चूक. बरोबर किंवा चूक म्हणा."
            } else if langId.contains("hi") {
                text = "प्रश्न \(viewModel.currentIndex + 1) / \(viewModel.questions.count): \(q.prompt)। विकल्प 1: सही। विकल्प 2: गलत। सही या गलत बोलें।"
            } else {
                text = "Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count): \(q.prompt). Option 1: True. Option 2: False. Say True or False."
            }
            await container.speechService.speak(text: text)
        }
    }

    private func submitAnswer(_ answer: Bool) {
        guard let question = viewModel.currentQuestion else { return }
        viewModel.answerCurrentQuestion(with: answer)
        let isCorrect = answer == question.correctAnswer
        let langId = LanguageManager.shared.currentLanguage.id
        let prefix: String
        if langId.contains("mr") {
            prefix = isCorrect ? "बरोबर!" : "चूक."
        } else if langId.contains("hi") {
            prefix = isCorrect ? "सही!" : "गलत।"
        } else {
            prefix = isCorrect ? "Correct!" : "Incorrect."
        }
        let feedback = "\(prefix) \(question.explanation ?? "")"

        Task {
            await container.speechService.speak(text: feedback)
            AccessibilityHelper.announce(feedback)

            // Auto-advance after feedback is spoken if quiz is not completed
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run {
                if !viewModel.isQuizCompleted && viewModel.isAnswerSubmitted {
                    advanceQuestion()
                }
            }
        }
    }

    private func advanceQuestion() {
        viewModel.nextQuestion()
        if let nextQ = viewModel.currentQuestion {
            Task {
                let text = "Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count): \(nextQ.prompt). Option 1: True. Option 2: False. Say True or False."
                await container.speechService.speak(text: text)
                AccessibilityHelper.announce(text)
            }
        } else if viewModel.isQuizCompleted {
            Task {
                let finishMsg = "Quiz completed! You scored \(viewModel.score) out of \(viewModel.questions.count), which is \(viewModel.percentageScore) percent. Say play again, or return to home."
                await container.speechService.speak(text: finishMsg)
                AccessibilityHelper.announce(finishMsg)
            }
        }
    }
}
