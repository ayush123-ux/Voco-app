import Foundation

/// Defines audio playback capabilities replacing audioplayers
public protocol AudioPlaybackServiceProtocol: AnyObject, Sendable {
    /// Whether audio is actively playing
    var isPlaying: Bool { get }

    /// Plays audio from a given file URL
    func playAudio(from url: URL) async throws

    /// Stops audio playback immediately
    func stopPlayback()
}
