import Foundation

/// Result of parsing voice email input or spelling commands
public enum VoiceEmailParseResult: Equatable, Sendable {
    /// Email was updated or partially spelled; prompt should be read back for user verification
    case updated(normalizedEmail: String, spokenFeedback: String, isValid: Bool)
    /// Explicit user confirmation received (e.g. "confirm email")
    case confirmed(email: String)
    /// User requested clear or reset
    case cleared(spokenFeedback: String)
    /// Unrecognized command or invalid operation
    case error(message: String)
}

/// Parses free-form spoken email spelling and edit commands
public struct VoiceEmailSpellingParser: Sendable {
    public init() {}

    public func parse(spokenPhrase: String, currentBuffer: String = "") -> VoiceEmailParseResult {
        let trimmed = spokenPhrase.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .error(message: "No speech heard. Please speak or spell your email.")
        }

        // Check for clear / reset commands
        if trimmed == "clear" || trimmed == "clear email" || trimmed == "reset" || trimmed == "start over" {
            return .cleared(spokenFeedback: "Email cleared. Please speak or spell your email address.")
        }

        // Check for confirmation commands
        if trimmed == "confirm" || trimmed == "confirm email" || trimmed == "yes" || trimmed == "yes confirm" || trimmed == "looks good" {
            let normalized = normalizeEmail(currentBuffer)
            if isValidEmail(normalized) {
                return .confirmed(email: normalized)
            } else {
                return .error(message: "Cannot confirm. '\(normalized)' is not a valid email address.")
            }
        }

        // Check for deletion / backspace commands
        if trimmed == "delete last" || trimmed == "delete" || trimmed == "backspace" || trimmed == "remove last" || trimmed == "delete letter" {
            guard !currentBuffer.isEmpty else {
                return .updated(normalizedEmail: "", spokenFeedback: "Email is already empty.", isValid: false)
            }
            var mutable = currentBuffer
            mutable.removeLast()
            let normalized = normalizeEmail(mutable)
            let valid = isValidEmail(normalized)
            let spoken = normalized.isEmpty
                ? "Deleted last character. Email is empty."
                : "Deleted last character. Current email is \(spellOutSpokenEmail(normalized)). Say 'confirm' when finished."
            return .updated(normalizedEmail: normalized, spokenFeedback: spoken, isValid: valid)
        }

        // Extract phrase (stripping preamble like "my email is")
        var workingText = trimmed
        let preambles = ["my email is ", "email is ", "it is ", "i am "]
        for preamble in preambles {
            if workingText.hasPrefix(preamble) {
                workingText = String(workingText.dropFirst(preamble.count))
                break
            }
        }

        // Normalize spoken tokens
        let normalized = normalizeEmail(workingText)
        let valid = isValidEmail(normalized)

        let spokenFeedback: String
        if valid {
            spokenFeedback = "I heard \(normalized). Say 'confirm email' to proceed, or 'clear' to try again."
        } else {
            spokenFeedback = "I heard \(spellOutSpokenEmail(normalized)). This is not yet a complete email. Please continue spelling or say 'clear'."
        }

        return .updated(normalizedEmail: normalized, spokenFeedback: spokenFeedback, isValid: valid)
    }

    /// Normalizes spoken variations ("at", "dot", dashes) into standard email characters
    public func normalizeEmail(_ input: String) -> String {
        var text = input.lowercased()

        // Replace hyphenated spoken words like "c-a-r-l-o-s-at-gmail-dot-com"
        text = text.replacingOccurrences(of: "-", with: " ")

        // Replace common punctuation spoken as words
        text = text.replacingOccurrences(of: " at ", with: "@")
        text = text.replacingOccurrences(of: "@ ", with: "@")
        text = text.replacingOccurrences(of: " @", with: "@")

        text = text.replacingOccurrences(of: " dot ", with: ".")
        text = text.replacingOccurrences(of: " period ", with: ".")
        text = text.replacingOccurrences(of: " point ", with: ".")
        text = text.replacingOccurrences(of: " full stop ", with: ".")

        text = text.replacingOccurrences(of: " underscore ", with: "_")
        text = text.replacingOccurrences(of: " dash ", with: "-")
        text = text.replacingOccurrences(of: " hyphen ", with: "-")

        // Split into parts around '@' if present
        if text.contains("@") {
            let parts = text.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
            let userPart = parts[0].replacingOccurrences(of: " ", with: "")
            let domainPart = parts.count > 1 ? parts[1].replacingOccurrences(of: " ", with: "") : ""
            return "\(userPart)@\(domainPart)"
        } else {
            // No @ yet, just strip internal spaces from spelled letters
            return text.replacingOccurrences(of: " ", with: "")
        }
    }

    /// Spells out symbols naturally for speech synthesis / VoiceOver
    public func spellOutSpokenEmail(_ email: String) -> String {
        return email
            .replacingOccurrences(of: "@", with: " at ")
            .replacingOccurrences(of: ".", with: " dot ")
    }

    /// Validates email format according to standard RFC structure
    public func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
