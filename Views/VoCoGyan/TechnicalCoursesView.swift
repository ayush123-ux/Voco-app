import SwiftUI

/// Courses directory matching ch1.dart (DSA, C++, C, Flutter)
public struct TechnicalCoursesView: View {
    public let category: CourseCategory
    public let onSelectTopic: (CourseTopic) -> Void

    public init(
        category: CourseCategory = .technical,
        onSelectTopic: @escaping (CourseTopic) -> Void
    ) {
        self.category = category
        self.onSelectTopic = onSelectTopic
    }

    private var filteredTopics: [CourseTopic] {
        CourseTopic.standardTopics.filter { $0.category == category }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(filteredTopics) { topic in
                    Button {
                        if topic.isAvailable {
                            onSelectTopic(topic)
                        }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(topic.isAvailable ? Color.blue.opacity(0.12) : Color.gray.opacity(0.1))
                                    .frame(width: 50, height: 50)

                                Image(systemName: topic.isAvailable ? "terminal.fill" : "lock.fill")
                                    .foregroundColor(topic.isAvailable ? .blue : .gray)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(topic.title)
                                        .font(.headline)
                                        .foregroundColor(topic.isAvailable ? .primary : .secondary)

                                    if !topic.isAvailable {
                                        Text("Coming Soon")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.15))
                                            .foregroundColor(.secondary)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(topic.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            if topic.isAvailable {
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(14)
                        .background(Color.gray.opacity(0.06))
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    .disabled(!topic.isAvailable)
                    .accessibilityLabel("\(topic.title). \(topic.description)\(topic.isAvailable ? "" : ", coming soon")")
                }
            }
            .padding()
        }
        .navigationTitle(category.rawValue)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
