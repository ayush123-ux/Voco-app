import SwiftUI

/// Episode reading and narration screen preserving quizDsa.dart logic,
/// with automatic spoken playback upon opening, hands-free pause/resume/stop, and full accessibility.
public struct EpisodeDetailView: View {
    public let episode: CourseEpisode
    @ObservedObject public var container: ServiceContainer
    public let onTakeQuiz: () -> Void

    @State private var isSpeaking = false
    @State private var hasStartedAutoPlay = false

    public init(
        episode: CourseEpisode,
        container: ServiceContainer,
        onTakeQuiz: @escaping () -> Void
    ) {
        self.episode = episode
        self.container = container
        self.onTakeQuiz = onTakeQuiz
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Badge
                Text("LESSON NARRATIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundColor(.blue)

                Text(episode.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Narrative Content Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(episode.narrativeText)
                        .font(.body)
                        .lineSpacing(7)
                        .foregroundColor(.primary)

                    Divider()

                    Button {
                        toggleNarration()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isSpeaking ? "stop.fill" : "speaker.wave.3.fill")
                            Text(isSpeaking ? "Stop VoCo Narration" : "Listen to VoCo Narration")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.vertical, 6)
                    }
                    .accessibilityLabel(isSpeaking ? "Stop Narration" : "Listen to VoCo read this passage")
                    .accessibilityHint("Toggles text-to-speech reading of this lesson")
                }
                .padding(20)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(18)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Lesson narrative for \(episode.title): \(episode.narrativeText)")

                Spacer(minLength: 20)

                // Quiz Prompt Card matching quizDsa.dart
                VStack(spacing: 16) {
                    Text("Ready to test your comprehension?")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Take a quick true/false quiz based on what you just read and heard.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button {
                            container.speechService.stopSpeaking()
                            isSpeaking = false
                            onTakeQuiz()
                        } label: {
                            Text("YES, TAKE QUIZ")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.green)
                                .cornerRadius(14)
                                .shadow(color: .green.opacity(0.3), radius: 6, y: 3)
                        }
                        .accessibilityLabel("Yes, Take Quiz")
                        .accessibilityHint("Starts a quiz testing your comprehension of this lesson")
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.06))
                .cornerRadius(20)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .navigationTitle(episode.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if !hasStartedAutoPlay {
                hasStartedAutoPlay = true
                startAutoNarration()
            }
        }
        .onDisappear {
            container.speechService.stopSpeaking()
            isSpeaking = false
        }
    }

    private func startAutoNarration() {
        isSpeaking = true
        Task {
            let introText = "Playing lesson: \(episode.title). \(episode.narrativeText)"
            AccessibilityHelper.announce("Lesson started: \(episode.title)")
            await container.speechService.speak(text: introText)
            await MainActor.run {
                self.isSpeaking = false
            }
        }
    }

    private func toggleNarration() {
        if isSpeaking {
            container.speechService.stopSpeaking()
            isSpeaking = false
        } else {
            isSpeaking = true
            Task {
                await container.speechService.speak(text: episode.narrativeText)
                await MainActor.run {
                    self.isSpeaking = false
                }
            }
        }
    }
}
