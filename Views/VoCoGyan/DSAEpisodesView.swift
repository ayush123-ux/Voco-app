import SwiftUI

/// Episodes list matching DSA.dart (Ep 1 to 10)
public struct DSAEpisodesView: View {
    public let topic: CourseTopic
    @ObservedObject public var container: ServiceContainer
    public let onSelectEpisode: (CourseEpisode) -> Void

    public init(
        topic: CourseTopic,
        container: ServiceContainer,
        onSelectEpisode: @escaping (CourseEpisode) -> Void
    ) {
        self.topic = topic
        self.container = container
        self.onSelectEpisode = onSelectEpisode
    }

    public var body: some View {
        List {
            Section(header: Text("Curriculum Episodes")) {
                ForEach(topic.episodes) { episode in
                    Button {
                        if episode.isAvailable {
                            onSelectEpisode(episode)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Text("\(episode.episodeNumber)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(episode.isAvailable ? .white : .secondary)
                                .frame(width: 32, height: 32)
                                .background(episode.isAvailable ? Color.blue : Color.gray.opacity(0.3))
                                .clipShape(Circle())
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(episode.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(episode.isAvailable ? .primary : .secondary)

                                if !episode.isAvailable {
                                    Text("Coming Soon")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if episode.isAvailable {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.blue)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(!episode.isAvailable)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Episode \(episode.episodeNumber): \(episode.title)\(episode.isAvailable ? "" : ", coming soon, locked")")
                    .accessibilityHint(episode.isAvailable ? "Double tap to listen to this lesson" : "Lesson is currently in development")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .navigationTitle(topic.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            let availableCount = topic.episodes.filter { $0.isAvailable }.count
            let msg = "\(topic.title). \(availableCount) episode\(availableCount == 1 ? "" : "s") available. Episode 1: \(topic.episodes.first?.title ?? ""). Say open episode 1 to begin."
            AccessibilityHelper.announce(msg)
        }
    }
}
