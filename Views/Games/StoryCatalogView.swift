import SwiftUI

/// Story selection catalog matching storytelling.dart
public struct StoryCatalogView: View {
    public let onSelectStory: (Story) -> Void

    public init(onSelectStory: @escaping (Story) -> Void) {
        self.onSelectStory = onSelectStory
    }

    public var body: some View {
        List {
            Section(header: Text("Inspiring Stories for Audio Learning")) {
                ForEach(Story.standardStories) { story in
                    Button {
                        onSelectStory(story)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(story.title)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(story.moral)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(story.title). Moral: \(story.moral)")
                    .accessibilityHint("Double tap to read and listen to this story")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .navigationTitle("Moral Stories")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
