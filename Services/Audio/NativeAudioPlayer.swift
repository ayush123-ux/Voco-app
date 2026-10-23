import Foundation
import AVFoundation

/// Native audio player using AVAudioPlayer.
/// Replaces Flutter's audioplayers plugin.
public final class NativeAudioPlayer: NSObject, AudioPlaybackServiceProtocol, AVAudioPlayerDelegate, @unchecked Sendable {
    private var player: AVAudioPlayer?
    public private(set) var isPlaying: Bool = false

    private var playbackCompletionHandler: (() -> Void)?

    public override init() {
        super.init()
    }

    public func playAudio(from url: URL) async throws {
        stopPlayback()

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try session.setActive(true)
        #endif

        let audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()

        guard audioPlayer.play() else {
            throw NSError(domain: "VoCoAudio", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to play audio file."])
        }

        self.player = audioPlayer
        self.isPlaying = true
    }

    public func stopPlayback() {
        if let player = player, player.isPlaying {
            player.stop()
        }
        self.player = nil
        self.isPlaying = false
    }

    // MARK: - AVAudioPlayerDelegate

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.isPlaying = false
        self.player = nil
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.isPlaying = false
        self.player = nil
    }
}
