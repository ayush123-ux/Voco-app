import Foundation

/// Learning category for VoCo Gyan matching story1.dart
public enum CourseCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case technical = "Technical Courses"
    case nonTechnical = "Non-Technical Courses"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .technical:
            return "laptopcomputer"
        case .nonTechnical:
            return "person.3.fill"
        }
    }

    public var subtitle: String {
        switch self {
        case .technical:
            return "Data structures, programming, and software engineering"
        case .nonTechnical:
            return "Life skills, communication, and moral stories"
        }
    }
}

/// Episode / Lesson within a course topic matching DSA.dart
public struct CourseEpisode: Identifiable, Hashable, Sendable {
    public let id: String
    public let episodeNumber: Int
    public let title: String
    public let narrativeText: String
    public let isAvailable: Bool

    public init(
        id: String,
        episodeNumber: Int,
        title: String,
        narrativeText: String,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.episodeNumber = episodeNumber
        self.title = title
        self.narrativeText = narrativeText
        self.isAvailable = isAvailable
    }
}

/// Topic matching ch1.dart (DSA, C++, C, Flutter)
public struct CourseTopic: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let category: CourseCategory
    public let episodes: [CourseEpisode]
    public let isAvailable: Bool

    public init(
        id: String,
        title: String,
        description: String,
        category: CourseCategory,
        episodes: [CourseEpisode],
        isAvailable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.episodes = episodes
        self.isAvailable = isAvailable
    }
}

extension CourseTopic {
    public static let standardTopics: [CourseTopic] = [
        CourseTopic(
            id: "topic-dsa",
            title: "Data Structures & Algorithms",
            description: "Master foundational computer science structures from Linked Lists to Trees.",
            category: .technical,
            episodes: [
                CourseEpisode(
                    id: "dsa-ep-1",
                    episodeNumber: 1,
                    title: "Ep. 1 - Linked List",
                    narrativeText: """
                    In computer science, a linked list is a linear collection of data elements whose order is not given by their physical placement in memory. Instead, each element points to the next.

                    It is a data structure consisting of a collection of nodes which together represent a sequence. In its most basic form, each node contains data and a reference to the next node in the sequence.

                    This structure allows for efficient insertion or removal of elements from any position in the sequence during iteration. More complex variants add additional links, allowing more efficient insertion or removal of nodes at arbitrary positions.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(id: "dsa-ep-2", episodeNumber: 2, title: "Ep. 2 - C Programming Basics", narrativeText: "Introduction to low-level memory concepts in C.", isAvailable: false),
                CourseEpisode(id: "dsa-ep-3", episodeNumber: 3, title: "Ep. 3 - Stacks and Queues", narrativeText: "LIFO and FIFO operations explained.", isAvailable: false),
                CourseEpisode(id: "dsa-ep-4", episodeNumber: 4, title: "Ep. 4 - Binary Trees", narrativeText: "Hierarchical data representation.", isAvailable: false),
                CourseEpisode(id: "dsa-ep-5", episodeNumber: 5, title: "Ep. 5 - Graph Traversal", narrativeText: "Breadth-first and depth-first search algorithms.", isAvailable: false),
                CourseEpisode(id: "dsa-ep-6", episodeNumber: 6, title: "Ep. 6 - Sorting Algorithms", narrativeText: "Quicksort, mergesort, and asymptotic complexity.", isAvailable: false),
                CourseEpisode(id: "dsa-ep-7", episodeNumber: 7, title: "Ep. 7 - Hash Tables", narrativeText: "Constant-time lookups and collision handling.", isAvailable: false),
                CourseEpisode(id: "dsa-ep-8", episodeNumber: 8, title: "Ep. 8 - Dynamic Programming", narrativeText: "Memoization and optimal substructure.", isAvailable: false),
                CourseEpisode(id: "dsa-ep-9", episodeNumber: 9, title: "Ep. 9 - Greedy Algorithms", narrativeText: "Locally optimal choices for global solutions.", isAvailable: false),
                CourseEpisode(id: "dsa-ep-10", episodeNumber: 10, title: "Ep. 10 - Dart & Modern Swift", narrativeText: "Object-oriented language constructs and concurrency.", isAvailable: false)
            ],
            isAvailable: true
        ),
        CourseTopic(
            id: "topic-cpp",
            title: "C++ Programming",
            description: "Object-oriented programming, templates, and systems memory management.",
            category: .technical,
            episodes: [],
            isAvailable: false
        ),
        CourseTopic(
            id: "topic-c",
            title: "C Language Fundamentals",
            description: "Pointers, arrays, manual memory allocation, and operating systems fundamentals.",
            category: .technical,
            episodes: [],
            isAvailable: false
        ),
        CourseTopic(
            id: "topic-flutter",
            title: "Flutter & Mobile Frameworks",
            description: "Cross-platform mobile engineering with reactive widget trees.",
            category: .technical,
            episodes: [],
            isAvailable: false
        )
    ]
}
