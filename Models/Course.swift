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
            return "Life skills, communication, leadership, and interview prep"
        }
    }
}

/// Course difficulty level
public enum CourseDifficulty: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all = "All"
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    public var id: String { rawValue }
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

/// Topic matching ch1.dart (DSA, C++, C, Flutter) and non-technical life skills
public struct CourseTopic: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let category: CourseCategory
    public let difficulty: CourseDifficulty
    public let estimatedDuration: String
    public let episodes: [CourseEpisode]
    public let isAvailable: Bool

    public init(
        id: String,
        title: String,
        description: String,
        category: CourseCategory,
        difficulty: CourseDifficulty = .beginner,
        estimatedDuration: String = "15 mins",
        episodes: [CourseEpisode],
        isAvailable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.episodes = episodes
        self.isAvailable = isAvailable
    }
}

extension CourseTopic {
    public static let standardTopics: [CourseTopic] = [
        // MARK: - Technical Courses
        CourseTopic(
            id: "topic-dsa",
            title: "Data Structures & Algorithms",
            description: "Master foundational computer science structures from Linked Lists to Trees.",
            category: .technical,
            difficulty: .intermediate,
            estimatedDuration: "45 mins",
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
            difficulty: .intermediate,
            estimatedDuration: "30 mins",
            episodes: [],
            isAvailable: false
        ),
        CourseTopic(
            id: "topic-c",
            title: "C Language Fundamentals",
            description: "Pointers, arrays, manual memory allocation, and operating systems fundamentals.",
            category: .technical,
            difficulty: .beginner,
            estimatedDuration: "25 mins",
            episodes: [],
            isAvailable: false
        ),
        CourseTopic(
            id: "topic-flutter",
            title: "Flutter & Mobile Frameworks",
            description: "Cross-platform mobile engineering with reactive widget trees.",
            category: .technical,
            difficulty: .intermediate,
            estimatedDuration: "35 mins",
            episodes: [],
            isAvailable: false
        ),

        // MARK: - Non-Technical Courses
        CourseTopic(
            id: "topic-communication",
            title: "Communication & Spoken English",
            description: "Master conversational clarity, active listening, and overcome hesitation in spoken conversations.",
            category: .nonTechnical,
            difficulty: .beginner,
            estimatedDuration: "20 mins",
            episodes: [
                CourseEpisode(
                    id: "comm-ep-1",
                    episodeNumber: 1,
                    title: "Ep. 1 - Active Listening & Conversational Turn-Taking",
                    narrativeText: """
                    Effective communication begins with active listening. Rather than planning your response while the other person is speaking, focus your full attention on their words, cadence, and underlying intent.

                    Notice natural conversational pauses before responding. Summarizing key points with phrases like 'What I hear you saying is...' validates the speaker and clarifies alignment.

                    Eliminate unnecessary filler words by allowing brief silences. A deliberate pause conveys confidence, whereas rushed speech often signals anxiety.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(
                    id: "comm-ep-2",
                    episodeNumber: 2,
                    title: "Ep. 2 - The PREP Method for Clear Explanations",
                    narrativeText: """
                    When asked for your opinion in professional or everyday settings, use the PREP structure: Point, Reason, Example, Point.

                    First, state your main Point clearly in one sentence. Second, provide the Reason or rationale behind your perspective. Third, share a concrete Example or story that demonstrates your idea. Finally, restate your Point to create a memorable conclusion.

                    This method prevents rambling and ensures your listener grasps your core message immediately.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(
                    id: "comm-ep-3",
                    episodeNumber: 3,
                    title: "Ep. 3 - Overcoming Fear and Speech Hesitation",
                    narrativeText: """
                    Language anxiety often stems from the fear of making grammatical errors. Remember that the primary goal of spoken communication is comprehension, not perfection.

                    Practice daily tongue twisters and vocal warm-ups to relax facial muscles. When you stumble upon a word, breathe gently, rephrase simply, and keep going without self-judgment.
                    """,
                    isAvailable: true
                )
            ],
            isAvailable: true
        ),
        CourseTopic(
            id: "topic-interview",
            title: "Interview Preparation & Practice",
            description: "Ace behavioral and technical job interviews using structured frameworks and confident storytelling.",
            category: .nonTechnical,
            difficulty: .intermediate,
            estimatedDuration: "25 mins",
            episodes: [
                CourseEpisode(
                    id: "interview-ep-1",
                    episodeNumber: 1,
                    title: "Ep. 1 - The STAR Method for Behavioral Interviews",
                    narrativeText: """
                    The STAR framework is the industry gold standard for answering behavioral questions like 'Tell me about a time you faced a challenge'.

                    S stands for Situation: Set the context briefly in 2 to 3 sentences. T is Task: Clarify your specific responsibility. A represents Action: Explain the step-by-step decisions and actions you personally took. R is Result: Share the quantifiable outcome and lessons learned.

                    Focus 70% of your time on Action and Result to highlight your proactive problem-solving abilities.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(
                    id: "interview-ep-2",
                    episodeNumber: 2,
                    title: "Ep. 2 - The 60-Second Elevator Pitch",
                    narrativeText: """
                    When an interviewer says 'Tell me about yourself', they are looking for a cohesive narrative connecting your past experiences, current passion, and why you are excited about this role.

                    Divide your pitch into three 20-second segments: Where you started, what significant value you built recently, and what you are eager to conquer next at their company.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(
                    id: "interview-ep-3",
                    episodeNumber: 3,
                    title: "Ep. 3 - Asking Strategic Questions to Interviewers",
                    narrativeText: """
                    The questions you ask at the conclusion of an interview reveal your depth of thinking.

                    Inquire about team dynamics: 'What separates a good performer from an exceptional performer on this team?' or 'What is the biggest operational challenge the team solved in the last quarter?' This demonstrates strategic vision and genuine engagement.
                    """,
                    isAvailable: true
                )
            ],
            isAvailable: true
        ),
        CourseTopic(
            id: "topic-personality",
            title: "Personality Development & Presence",
            description: "Develop executive presence, confident non-verbal posture, and a resilient growth mindset.",
            category: .nonTechnical,
            difficulty: .beginner,
            estimatedDuration: "20 mins",
            episodes: [
                CourseEpisode(
                    id: "personality-ep-1",
                    episodeNumber: 1,
                    title: "Ep. 1 - Cultivating a Growth Mindset",
                    narrativeText: """
                    A fixed mindset views talent and intelligence as static traits, leading individuals to avoid challenges to avoid failure. A growth mindset views abilities as muscle developed through deliberate practice.

                    Embrace the power of 'yet': instead of saying 'I cannot do this', affirm 'I cannot do this yet'. Every setback is data guiding your next iteration.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(
                    id: "personality-ep-2",
                    episodeNumber: 2,
                    title: "Ep. 2 - Non-Verbal Presence & Body Language",
                    narrativeText: """
                    Over half of interpersonal perception is derived from non-verbal cues. Maintain open body language: keep shoulders relaxed, avoid crossing arms defensively, and hold gentle eye contact.

                    Your posture physically influences your vocal resonance. Sitting tall expands your diaphragm, giving your voice natural authority and clarity.
                    """,
                    isAvailable: true
                )
            ],
            isAvailable: true
        ),
        CourseTopic(
            id: "topic-leadership",
            title: "Leadership & Collaborative Teamwork",
            description: "Inspire trust, resolve interpersonal conflict, and give constructive feedback with empathy.",
            category: .nonTechnical,
            difficulty: .advanced,
            estimatedDuration: "30 mins",
            episodes: [
                CourseEpisode(
                    id: "leadership-ep-1",
                    episodeNumber: 1,
                    title: "Ep. 1 - Empathy-Driven Collaboration",
                    narrativeText: """
                    Leadership is not about commanding authority; it is about creating psychological safety where every team member feels comfortable sharing unconventional ideas and admitting mistakes.

                    Acknowledge others' contributions publicly and address disagreements privately with curiosity instead of accusation.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(
                    id: "leadership-ep-2",
                    episodeNumber: 2,
                    title: "Ep. 2 - The SBI Model for Constructive Feedback",
                    narrativeText: """
                    Giving actionable feedback without causing defensiveness requires precision. Use the Situation-Behavior-Impact (SBI) model.

                    Anchor the feedback in the specific Situation (when and where), describe the observable Behavior without subjective labels, and explain the measurable Impact on the team or project.
                    """,
                    isAvailable: true
                )
            ],
            isAvailable: true
        ),
        CourseTopic(
            id: "topic-productivity",
            title: "Time Management & Productivity",
            description: "Protect your focus, eliminate burnout, and prioritize using proven cognitive frameworks.",
            category: .nonTechnical,
            difficulty: .beginner,
            estimatedDuration: "15 mins",
            episodes: [
                CourseEpisode(
                    id: "productivity-ep-1",
                    episodeNumber: 1,
                    title: "Ep. 1 - The Eisenhower Matrix & Prioritization",
                    narrativeText: """
                    Organize your daily responsibilities into four distinct quadrants based on Urgency and Importance.

                    Quadrant 1 contains Urgent & Important tasks (crises). Quadrant 2 contains Not Urgent but Important tasks (learning, exercise, relationship building). True long-term success comes from maximizing time spent in Quadrant 2 before tasks become emergencies.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(
                    id: "productivity-ep-2",
                    episodeNumber: 2,
                    title: "Ep. 2 - Deep Work & Attention Management",
                    narrativeText: """
                    Constant notifications fragment cognitive attention and deplete willpower. Create dedicated 90-minute blocks of uninterrupted deep work.

                    Silence notifications, batch emails into fixed times of the day, and protect your most creative morning hours for high-cognition problem-solving.
                    """,
                    isAvailable: true
                )
            ],
            isAvailable: true
        ),
        CourseTopic(
            id: "topic-criticalthinking",
            title: "Critical Thinking & Problem-Solving",
            description: "Break complex real-world dilemmas into fundamental truths and reasoned solutions.",
            category: .nonTechnical,
            difficulty: .intermediate,
            estimatedDuration: "20 mins",
            episodes: [
                CourseEpisode(
                    id: "critical-ep-1",
                    episodeNumber: 1,
                    title: "Ep. 1 - First Principles Reasoning",
                    narrativeText: """
                    First principles thinking means boiling a problem down to its most fundamental truths that cannot be deduced any further, and reasoning up from there.

                    Instead of reasoning by analogy—doing what everyone else is doing with minor tweaks—question assumptions: 'What do we know is true? What are the basic components?' This unlocks breakthrough innovation.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(
                    id: "critical-ep-2",
                    episodeNumber: 2,
                    title: "Ep. 2 - Root Cause Analysis: The 5 Whys",
                    narrativeText: """
                    When a problem occurs, human instinct is often to patch the immediate symptom. The 5 Whys technique involves repeatedly asking 'Why did this happen?' five consecutive times.

                    Drilling through each layer reveals systemic process breakdowns rather than superficial human error, allowing you to implement permanent solutions.
                    """,
                    isAvailable: true
                )
            ],
            isAvailable: true
        ),
        CourseTopic(
            id: "topic-career",
            title: "Career Readiness & Professional Networking",
            description: "Build authentic professional relationships, showcase projects, and navigate promotions.",
            category: .nonTechnical,
            difficulty: .intermediate,
            estimatedDuration: "20 mins",
            episodes: [
                CourseEpisode(
                    id: "career-ep-1",
                    episodeNumber: 1,
                    title: "Ep. 1 - Authentic Networking & Adding Value",
                    narrativeText: """
                    Networking is not transactional business-card collecting; it is cultivating genuine relationships built on mutual value.

                    Reach out to professionals whose work inspires you with specific appreciation for a project they built. Offer insights or volunteer assistance before ever asking for a favor or referral.
                    """,
                    isAvailable: true
                )
            ],
            isAvailable: true
        ),
        CourseTopic(
            id: "topic-financial",
            title: "Practical Financial Literacy",
            description: "Understand budgeting, compounding interest, emergency funds, and long-term financial security.",
            category: .nonTechnical,
            difficulty: .beginner,
            estimatedDuration: "20 mins",
            episodes: [
                CourseEpisode(
                    id: "finance-ep-1",
                    episodeNumber: 1,
                    title: "Ep. 1 - The 50/30/20 Budgeting Rule",
                    narrativeText: """
                    Financial freedom begins with an intentional spending framework. The 50/30/20 rule divides your after-tax income into three buckets:

                    50% for Needs (rent, groceries, utilities, minimum debt payments), 30% for Wants (dining out, entertainment, hobbies), and 20% for Savings and debt acceleration. Building a 3-to-6 month emergency fund protects you from unforeseen shocks.
                    """,
                    isAvailable: true
                ),
                CourseEpisode(
                    id: "finance-ep-2",
                    episodeNumber: 2,
                    title: "Ep. 2 - The Power of Compound Growth",
                    narrativeText: """
                    Compound interest is earning interest on top of past interest. Over decades, this exponential curve turns consistent modest contributions into substantial wealth.

                    Starting early matters far more than starting with large sums because time is the greatest multiplier of compound interest.
                    """,
                    isAvailable: true
                )
            ],
            isAvailable: true
        )
    ]
}
