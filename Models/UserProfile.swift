import Foundation

/// Gender option matching the Flutter Form radio/dropdown index
public enum Gender: Int, CaseIterable, Codable, Sendable, Identifiable {
    case male = 0
    case female = 1
    case other = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Others"
        }
    }
}

/// Marital status matching the Flutter Form radio group values
public enum MaritalStatus: String, CaseIterable, Codable, Sendable, Identifiable {
    case single = "single"
    case married = "married"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .single: return "Single"
        case .married: return "Married"
        }
    }
}

/// Education level matching the Flutter Form dropdown index
public enum EducationLevel: Int, CaseIterable, Codable, Sendable, Identifiable {
    case uneducated = 0
    case schoolEducation = 1
    case higherEducation = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .uneducated: return "Basic / None"
        case .schoolEducation: return "School Education"
        case .higherEducation: return "Higher Education"
        }
    }
}

/// User intake profile matching form.dart
public struct UserProfile: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var email: String
    public var age: Int
    public var gender: Gender
    public var maritalStatus: MaritalStatus
    public var educationLevel: EducationLevel
    public var termsAccepted: Bool
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String = "",
        email: String = "",
        age: Int = 18,
        gender: Gender = .male,
        maritalStatus: MaritalStatus = .single,
        educationLevel: EducationLevel = .higherEducation,
        termsAccepted: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender
        self.maritalStatus = maritalStatus
        self.educationLevel = educationLevel
        self.termsAccepted = termsAccepted
        self.updatedAt = updatedAt
    }
}
