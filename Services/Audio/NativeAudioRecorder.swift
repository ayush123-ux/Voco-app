import Foundation
import AVFoundation

/// Native audio recording service using AVAudioRecorder.
/// Replaces Flutter's flutter_sound_record / RecordMp3 plugins.
public final class NativeAudioRecorder: NSObject, AudioRecordingServiceProtocol, AVAudioRecorderDelegate, @unchecked Sendable {
    private var recorder: AVAudioRecorder?
    public private(set) var isRecording: Bool = false
    public private(set) var currentRecordingURL: URL?

    public override init() {
        super.init()
    }

    public func startRecording() async throws -> URL {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        // Request microphone permission on iOS
        let permissionGranted: Bool
        if #available(iOS 17.0, *) {
            permissionGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            permissionGranted = await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        guard permissionGranted else {
            throw NSError(
                domain: "VoCoAudio",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Microphone permission was denied. Please enable it in Settings."]
            )
        }
        #endif

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voco_recording_\(UUID().uuidString).m4a"
        let fileURL = tempDir.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder.delegate = self
        guard audioRecorder.record() else {
            throw NSError(domain: "VoCoAudio", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to start recording."])
        }

        self.recorder = audioRecorder
        self.currentRecordingURL = fileURL
        self.isRecording = true
        return fileURL
    }

    public func stopRecording() async throws -> URL {
        guard let recorder = self.recorder, isRecording else {
            if let existingURL = currentRecordingURL {
                return existingURL
            }
            throw NSError(domain: "VoCoAudio", code: 400, userInfo: [NSLocalizedDescriptionKey: "No active recording found."])
        }

        recorder.stop()
        self.isRecording = false
        self.recorder = nil

        let url = recorder.url
        self.currentRecordingURL = url
        return url
    }

    // MARK: - AVAudioRecorderDelegate

    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self.isRecording = false
    }

    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        self.isRecording = false
    }
}
