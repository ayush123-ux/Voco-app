import Foundation

/// Defines audio recording capabilities for pronunciation practice
public protocol AudioRecordingServiceProtocol: AnyObject, Sendable {
    /// Whether the microphone is actively recording
    var isRecording: Bool { get }

    /// URL of the most recently recorded audio file, if any
    var currentRecordingURL: URL? { get }

    /// Starts recording user audio from the microphone
    func startRecording() async throws -> URL

    /// Stops recording and returns the final file URL
    func stopRecording() async throws -> URL
}
