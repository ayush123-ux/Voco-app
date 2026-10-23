import SwiftUI

/// Review and comparison screen preserving the exact 4-quadrant functionality of guidep2.dart
public struct PronunciationReviewView: View {
    @ObservedObject public var viewModel: PronunciationViewModel
    public let onReRecord: () -> Void
    public let onCompletedAllSentences: () -> Void

    public init(
        viewModel: PronunciationViewModel,
        onReRecord: @escaping () -> Void,
        onCompletedAllSentences: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onReRecord = onReRecord
        self.onCompletedAllSentences = onCompletedAllSentences
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Sentence Context Bar
            if let sentence = viewModel.currentSentence {
                VStack(spacing: 6) {
                    Text("PRACTICE SENTENCE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text(sentence.text)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.06))
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.top, 10)
            }

            Spacer()

            // 4-Quadrant Actions matching guidep2.dart
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                // Quadrant 1: Re-Record (Top Left)
                QuadrantCardView(
                    title: "Re-Record",
                    subtitle: "Try speaking this sentence again",
                    systemImage: "arrow.counterclockwise.circle.fill",
                    gradientColors: [.orange, .red],
                    accessibilityHint: "Clears your recording and returns to microphone screen",
                    action: {
                        viewModel.resetForCurrentSentence()
                        onReRecord()
                    }
                )

                // Quadrant 2: Next Sentence (Top Right)
                QuadrantCardView(
                    title: viewModel.hasNextSentence ? "Next Sentence" : "Finish Practice",
                    subtitle: viewModel.hasNextSentence ? "Advance to sentence \(viewModel.currentIndex + 2)" : "Complete session and return home",
                    systemImage: viewModel.hasNextSentence ? "arrow.right.circle.fill" : "checkmark.seal.fill",
                    gradientColors: [.green, .teal],
                    accessibilityHint: "Advances to the next pronunciation sentence",
                    action: {
                        if viewModel.moveToNextSentence() {
                            onReRecord()
                        } else {
                            onCompletedAllSentences()
                        }
                    }
                )

                // Quadrant 3: Listen to VoCo (Bottom Left)
                QuadrantCardView(
                    title: viewModel.isSpeakingVoCo ? "VoCo Speaking..." : "Listen to VoCo",
                    subtitle: "Hear clear native pronunciation",
                    systemImage: viewModel.isSpeakingVoCo ? "speaker.wave.3.fill" : "speaker.wave.2.circle.fill",
                    gradientColors: [.indigo, .blue],
                    accessibilityHint: "Plays text-to-speech pronunciation benchmark",
                    action: {
                        Task {
                            await viewModel.listenToVoCo()
                        }
                    }
                )

                // Quadrant 4: Listen to Your Audio (Bottom Right)
                QuadrantCardView(
                    title: viewModel.isPlayingRecordedAudio ? "Playing Voice..." : "Your Recording",
                    subtitle: "Listen to your recorded playback",
                    systemImage: viewModel.isPlayingRecordedAudio ? "play.circle.fill" : "person.wave.2.fill",
                    gradientColors: [.purple, .indigo],
                    accessibilityHint: "Plays back your microphone recording",
                    action: {
                        Task {
                            await viewModel.listenToOwnAudio()
                        }
                    }
                )
            }
            .padding(.horizontal)

            Spacer()

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Pronunciation Review")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
