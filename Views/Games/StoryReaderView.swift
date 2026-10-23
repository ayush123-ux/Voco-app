import SwiftUI

/// Story viewer and audio playback screen matching storytelling2.dart
public struct StoryReaderView: View {
    public let story: Story
    @ObservedObject public var container: ServiceContainer
    public let onTakeQuiz: () -> Void

    @State private var isSpeaking = false

    public init(
        story: Story,
        container: ServiceContainer,
        onTakeQuiz: @escaping () -> Void
    ) {
        self.story = story
        self.container = container
        self.onTakeQuiz = onTakeQuiz
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(story.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Story Narrative Card
                VStack(alignment: .leading, spacing: 14) {
                    Text(story.narrativeText)
                        .font(.body)
                        .lineSpacing(7)
                        .foregroundColor(.primary)

                    Divider()

                    Button {
                        toggleNarration()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isSpeaking ? "stop.fill" : "speaker.wave.3.fill")
                            Text(isSpeaking ? "Stop Story Audio" : "Listen to Story (VoCo Voice)")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                    }
                }
                .padding(20)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(18)

                // Moral Callout
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                        Text("MORAL OF THE STORY")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }

                    Text(story.moral)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(14)

                Spacer(minLength: 16)

                // Quiz Launch Button
                Button {
                    container.speechService.stopSpeaking()
                    isSpeaking = false
                    onTakeQuiz()
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                        Text("Test Your Comprehension")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .navigationTitle("Moral Story")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onDisappear {
            container.speechService.stopSpeaking()
        }
    }

    private func toggleNarration() {
        if isSpeaking {
            container.speechService.stopSpeaking()
            isSpeaking = false
        } else {
            isSpeaking = true
            Task {
                await container.speechService.speak(text: story.narrativeText)
                await MainActor.run {
                    self.isSpeaking = false
                }
            }
        }
    }
}
