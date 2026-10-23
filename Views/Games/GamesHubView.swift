import SwiftUI

/// Games and interactive quizzes hub preserving game.dart
public struct GamesHubView: View {
    public let onSelectStories: () -> Void
    public let onSelectQuiz: () -> Void

    public init(
        onSelectStories: @escaping () -> Void,
        onSelectQuiz: @escaping () -> Void
    ) {
        self.onSelectStories = onSelectStories
        self.onSelectQuiz = onSelectQuiz
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Intro header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Games & Challenges")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Interactive audio drills, moral stories, and comprehension tests.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 12)

                // Option 1: Moral Stories
                Button(action: onSelectStories) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 58, height: 58)

                            Image(systemName: "book.pages.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Storytelling & Lessons")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Listen to classic moral fables and answer comprehension checks.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Storytelling and Lessons")

                // Option 2: Knowledge Check Quiz
                Button(action: onSelectQuiz) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 58, height: 58)

                            Image(systemName: "checkmark.seal.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("VoCo Knowledge Quiz")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Test your technical and speech knowledge with rapid True/False questions.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("VoCo Knowledge Quiz")
            }
            .padding(.horizontal)
        }
        .navigationTitle("Games & Challenges")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
