import Foundation
import SwiftUI
import Combine

/// Manages pronunciation guide state matching guidep1.dart and guidep2.dart
@MainActor
public final class PronunciationViewModel: ObservableObject {
    @Published public private(set) var sentences: [PracticeSentence] = []
    @Published public private(set) var currentIndex: Int = 0
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?

    // Audio & Recording State
    @Published public private(set) var isRecording: Bool = false
    @Published public private(set) var recordingDuration: TimeInterval = 0
    @Published public private(set) var recordedAudioURL: URL?
    @Published public private(set) var isPlayingRecordedAudio: Bool = false
    @Published public private(set) var isSpeakingVoCo: Bool = false

    private let sentenceService: SentenceServiceProtocol
    private let speechService: SpeechServiceProtocol
    private let audioRecorder: AudioRecordingServiceProtocol
    private let audioPlayer: AudioPlaybackServiceProtocol

    private var timerTask: Task<Void, Never>?

    public init(
        sentenceService: SentenceServiceProtocol,
        speechService: SpeechServiceProtocol,
        audioRecorder: AudioRecordingServiceProtocol,
        audioPlayer: AudioPlaybackServiceProtocol
    ) {
        self.sentenceService = sentenceService
        self.speechService = speechService
        self.audioRecorder = audioRecorder
        self.audioPlayer = audioPlayer
    }

    public var currentSentence: PracticeSentence? {
        guard currentIndex >= 0 && currentIndex < sentences.count else { return nil }
        return sentences[currentIndex]
    }

    public var hasNextSentence: Bool {
        currentIndex + 1 < sentences.count
    }

    public func loadSentences() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await sentenceService.fetchSentences()
            self.sentences = fetched.isEmpty ? PracticeSentence.sampleSentences : fetched
            self.currentIndex = 0
        } catch {
            self.errorMessage = error.localizedDescription
            self.sentences = PracticeSentence.sampleSentences
        }
        self.isLoading = false
    }

    // MARK: - Recording Actions (guidep1.dart)

    public func toggleRecording() async {
        if isRecording {
            await stopRecording()
        } else {
            await startRecording()
        }
    }

    public func startRecording() async {
        do {
            let url = try await audioRecorder.startRecording()
            self.recordedAudioURL = url
            self.isRecording = true
            self.recordingDuration = 0

            // Start timer
            timerTask?.cancel()
            timerTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    _ = await MainActor.run {
                        self?.incrementTimer()
                    }
                }
            }
        } catch {
            self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    public func stopRecording() async {
        timerTask?.cancel()
        timerTask = nil

        do {
            let url = try await audioRecorder.stopRecording()
            self.recordedAudioURL = url
            self.isRecording = false
        } catch {
            self.errorMessage = "Failed to stop recording: \(error.localizedDescription)"
            self.isRecording = false
        }
    }

    private func incrementTimer() {
        guard isRecording else { return }
        recordingDuration += 0.5
    }

    // MARK: - Review & Playback Actions (guidep2.dart)

    public func listenToVoCo() async {
        guard let sentence = currentSentence else { return }

        // Stop any user audio first
        audioPlayer.stopPlayback()
        isPlayingRecordedAudio = false

        isSpeakingVoCo = true
        await speechService.speak(text: sentence.text)
        isSpeakingVoCo = false
    }

    public func listenToOwnAudio() async {
        guard let url = recordedAudioURL else {
            errorMessage = "No recording available to play."
            return
        }

        // Stop VoCo speech first
        speechService.stopSpeaking()
        isSpeakingVoCo = false

        isPlayingRecordedAudio = true
        do {
            try await audioPlayer.playAudio(from: url)
        } catch {
            errorMessage = "Playback error: \(error.localizedDescription)"
        }
        isPlayingRecordedAudio = false
    }

    public func moveToNextSentence() -> Bool {
        if hasNextSentence {
            currentIndex += 1
            recordedAudioURL = nil
            recordingDuration = 0
            return true
        }
        return false
    }

    public func resetForCurrentSentence() {
        recordedAudioURL = nil
        recordingDuration = 0
        audioPlayer.stopPlayback()
        speechService.stopSpeaking()
        isPlayingRecordedAudio = false
        isSpeakingVoCo = false
    }
}
