import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Sentence practice and audio recording view preserving guidep1.dart features
public struct PronunciationRecordView: View {
    @ObservedObject public var viewModel: PronunciationViewModel
    public let onProceedToReview: () -> Void
    public let onBackToDashboard: () -> Void

    @State private var isPulsing = false
    @State private var showPermissionAlert = false

    public init(
        viewModel: PronunciationViewModel,
        onProceedToReview: @escaping () -> Void,
        onBackToDashboard: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onProceedToReview = onProceedToReview
        self.onBackToDashboard = onBackToDashboard
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Header Progress
            HStack {
                Button(action: onBackToDashboard) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding(8)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Back to Dashboard")
                .accessibilityHint("Returns to the main dashboard")
                .accessibilityAddTraits(.isButton)

                Spacer()

                if !viewModel.sentences.isEmpty {
                    Text("Sentence \(viewModel.currentIndex + 1) of \(viewModel.sentences.count)")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                        .accessibilityLabel("Sentence \(viewModel.currentIndex + 1) of \(viewModel.sentences.count)")
                }

                Spacer()

                // Balance spacing
                Circle()
                    .fill(Color.clear)
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Error Banner if present
            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .accessibilityHidden(true)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Recording error: \(errorMessage)")
            }

            Spacer()

            // Sentence Practice Card
            VStack(spacing: 16) {
                if let sentence = viewModel.currentSentence {
                    Text(sentence.category.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1.2)
                        .foregroundColor(.blue)

                    Text(sentence.text)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 8)

                    if let hint = sentence.phoneticHint {
                        Text(hint)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                } else {
                    ProgressView()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sentence to practice: \(viewModel.currentSentence?.text ?? ""). Phonetic guide: \(viewModel.currentSentence?.phoneticHint ?? "")")

            Spacer()

            // Microphone Record Button & Mascot Area
            VStack(spacing: 16) {
                if viewModel.isRecording {
                    Text(String(format: "Recording... %02d:%02d", Int(viewModel.recordingDuration) / 60, Int(viewModel.recordingDuration) % 60))
                        .font(.headline)
                        .foregroundColor(.red)
                        .accessibilityLabel("Recording in progress, duration \(Int(viewModel.recordingDuration)) seconds")
                } else if viewModel.recordedAudioURL != nil {
                    Text("Recording saved. Tap below to review or re-record.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Tap the microphone and speak aloud")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Big Accessible Record Button
                Button {
                    Task {
                        await viewModel.toggleRecording()
                        if viewModel.isRecording {
                            AccessibilityHelper.announce("Recording started. Speak now.")
                        } else if viewModel.recordedAudioURL != nil {
                            AccessibilityHelper.announce("Recording stopped and saved. Tap Review and Compare to continue.")
                            onProceedToReview()
                        } else if let error = viewModel.errorMessage {
                            AccessibilityHelper.announce("Recording error: \(error)")
                            if error.contains("permission") || error.contains("Settings") {
                                showPermissionAlert = true
                            }
                        }
                    }
                } label: {
                    ZStack {
                        if viewModel.isRecording {
                            Circle()
                                .stroke(Color.red.opacity(0.4), lineWidth: 4)
                                .frame(width: 110, height: 110)
                                .scaleEffect(isPulsing ? 1.25 : 1.0)
                        }

                        Circle()
                            .fill(viewModel.isRecording ? Color.red : Color.blue)
                            .frame(width: 88, height: 88)
                            .shadow(color: (viewModel.isRecording ? Color.red : Color.blue).opacity(0.4), radius: 10, y: 5)

                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                .accessibilityHint("Records your pronunciation through the microphone")
                .accessibilityAddTraits(.isButton)
                .onChange(of: viewModel.isRecording) { isRec in
                    if isRec {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            isPulsing = true
                        }
                    } else {
                        isPulsing = false
                    }
                }

                if viewModel.recordedAudioURL != nil && !viewModel.isRecording {
                    Button(action: onProceedToReview) {
                        HStack {
                            Text("Review & Compare")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                    }
                    .accessibilityLabel("Review and Compare")
                    .accessibilityHint("Opens the comparison screen to listen to your voice and native VoCo pronunciation")
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                }
            }
            .padding(.bottom, 36)
        }
        .task {
            if viewModel.sentences.isEmpty {
                await viewModel.loadSentences()
            }
        }
        .onChange(of: viewModel.errorMessage) { newError in
            if let err = newError {
                AccessibilityHelper.announce("Error: \(err)")
                if err.contains("permission") || err.contains("Settings") {
                    showPermissionAlert = true
                }
            }
        }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            #if os(iOS)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            #endif
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("VoCo needs microphone access to record and analyze your pronunciation. Please allow Microphone in Settings.")
        }
    }
}
