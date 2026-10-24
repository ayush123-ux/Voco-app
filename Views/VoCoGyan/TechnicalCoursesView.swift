import SwiftUI

/// Courses directory supporting both Technical and Non-Technical categories with full states and accessibility
public struct TechnicalCoursesView: View {
    public let category: CourseCategory
    public let onSelectTopic: (CourseTopic) -> Void

    @State private var selectedDifficulty: CourseDifficulty = .all
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        category: CourseCategory = .technical,
        onSelectTopic: @escaping (CourseTopic) -> Void
    ) {
        self.category = category
        self.onSelectTopic = onSelectTopic
    }

    private var allCategoryTopics: [CourseTopic] {
        CourseTopic.standardTopics.filter { $0.category == category }
    }

    private var filteredTopics: [CourseTopic] {
        allCategoryTopics.filter { topic in
            let matchesDifficulty = (selectedDifficulty == .all || topic.difficulty == selectedDifficulty)
            let matchesQuery = searchQuery.isEmpty ||
                topic.title.localizedCaseInsensitiveContains(searchQuery) ||
                topic.description.localizedCaseInsensitiveContains(searchQuery)
            return matchesDifficulty && matchesQuery
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Filter and Search Header
            VStack(spacing: 10) {
                // Difficulty Segmented Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CourseDifficulty.allCases) { diff in
                            Button {
                                selectedDifficulty = diff
                                announceFilterChange()
                            } label: {
                                Text(diff.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(selectedDifficulty == diff ? .semibold : .regular)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedDifficulty == diff ? Color.blue : Color.gray.opacity(0.12))
                                    .foregroundColor(selectedDifficulty == diff ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Filter by \(diff.rawValue) difficulty")
                            .accessibilityAddTraits(selectedDifficulty == diff ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search \(category.rawValue)...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()

                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(colorSchemeAdaptiveBackground)

            Divider()

            // Main Content Area with States
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                    Text("Loading courses...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Loading courses")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)
                    Text("Unable to Load Courses")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button("Try Again") {
                        errorMessage = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredTopics.isEmpty {
                // Accessible Empty State
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.6))

                    Text("No Courses Found")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(searchQuery.isEmpty
                         ? "No \(selectedDifficulty.rawValue.lowercased()) courses available in this category."
                         : "No courses matching '\(searchQuery)'."
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                    if selectedDifficulty != .all || !searchQuery.isEmpty {
                        Button("Reset Filters") {
                            selectedDifficulty = .all
                            searchQuery = ""
                            AccessibilityHelper.announce("Filters reset. Showing all courses.")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .accessibilityHint("Shows all available courses")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTopics) { topic in
                            CourseTopicCard(topic: topic) {
                                if topic.isAvailable {
                                    onSelectTopic(topic)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(category.rawValue)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            announceCategoryArrival()
        }
    }

    private var colorSchemeAdaptiveBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #else
        return Color.white
        #endif
    }

    private func announceCategoryArrival() {
        let count = filteredTopics.count
        AccessibilityHelper.announce("\(category.rawValue). Showing \(count) available topics. Use the microphone or swipe to navigate.")
    }

    private func announceFilterChange() {
        let count = filteredTopics.count
        AccessibilityHelper.announce("Filter set to \(selectedDifficulty.rawValue). \(count) courses found.")
    }
}

/// Detailed Course Topic Card with badges and VoiceOver compliance
private struct CourseTopicCard: View {
    let topic: CourseTopic
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 14) {
                    // Category icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(topic.isAvailable ? Color.blue.opacity(0.12) : Color.gray.opacity(0.12))
                            .frame(width: 48, height: 48)

                        Image(systemName: iconForTopic(topic))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(topic.isAvailable ? .blue : .gray)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(topic.title)
                                .font(.headline)
                                .foregroundColor(topic.isAvailable ? .primary : .secondary)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            if !topic.isAvailable {
                                Text("Coming Soon")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.gray.opacity(0.15))
                                    .foregroundColor(.secondary)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(topic.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }

                // Metadata Badges (Difficulty, Duration, Lessons count)
                HStack(spacing: 8) {
                    // Difficulty badge
                    Label(topic.difficulty.rawValue, systemImage: "chart.bar.fill")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor(topic.difficulty).opacity(0.15))
                        .foregroundColor(difficultyColor(topic.difficulty))
                        .clipShape(Capsule())

                    // Duration badge
                    Label(topic.estimatedDuration, systemImage: "clock.fill")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.12))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())

                    // Lessons count badge
                    if !topic.episodes.isEmpty {
                        Label("\(topic.episodes.count) lessons", systemImage: "play.circle.fill")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if topic.isAvailable {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.06))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!topic.isAvailable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.title). \(topic.difficulty.rawValue) difficulty. Duration \(topic.estimatedDuration). \(topic.episodes.count) lessons. \(topic.description)\(topic.isAvailable ? "" : ". Coming soon")")
        .accessibilityHint(topic.isAvailable ? "Double tap to open course curriculum" : "This course is not yet released")
        .accessibilityAddTraits(.isButton)
    }

    private func iconForTopic(_ topic: CourseTopic) -> String {
        switch topic.id {
        case "topic-communication": return "bubble.left.and.bubble.right.fill"
        case "topic-interview": return "person.crop.rectangle.badge.plus"
        case "topic-personality": return "sparkles"
        case "topic-leadership": return "person.3.sequence.fill"
        case "topic-productivity": return "timer"
        case "topic-criticalthinking": return "brain.head.profile"
        case "topic-career": return "briefcase.fill"
        case "topic-financial": return "indianrupeesign.circle.fill"
        case "topic-dsa": return "chevron.left.forwardslash.chevron.right"
        default: return "laptopcomputer"
        }
    }

    private func difficultyColor(_ diff: CourseDifficulty) -> Color {
        switch diff {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .purple
        case .all: return .blue
        }
    }
}
