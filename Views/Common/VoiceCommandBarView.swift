import SwiftUI

/// Accessible voice command control bar providing hands-free continuous voice navigation and privacy controls
public struct VoiceCommandBarView: View {
    @ObservedObject public var viewModel: VoiceCommandViewModel
    public let onCommandRecognized: (VoiceCommandIntent) -> Void

    @State private var isPulsing = false

    public init(
        viewModel: VoiceCommandViewModel,
        onCommandRecognized: @escaping (VoiceCommandIntent) -> Void
    ) {
        self.viewModel = viewModel
        self.onCommandRecognized = onCommandRecognized
    }

    public var body: some View {
        VStack(spacing: 6) {
            // Main control strip
            HStack(spacing: 10) {
                // 1. Microphone Activation Button
                Button {
                    Task {
                        await viewModel.toggleListening(onIntentRecognized: onCommandRecognized)
                    }
                } label: {
                    ZStack {
                        if viewModel.isListening {
                            Circle()
                                .stroke(Color.red.opacity(0.35), lineWidth: 3)
                                .frame(width: 50, height: 50)
                                .scaleEffect(isPulsing ? 1.25 : 1.0)
                        }

                        Circle()
                            .fill(buttonBackgroundColor)
                            .frame(width: 42, height: 42)
                            .shadow(color: buttonBackgroundColor.opacity(0.3), radius: 6, y: 3)

                        Image(systemName: buttonIconName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel(viewModel.listeningState.accessibilityLabel)
                .accessibilityHint("Double-tap to start or stop listening.")
                .accessibilityAddTraits(.isButton)
                .onChange(of: viewModel.isListening) { listening in
                    if listening {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            isPulsing = true
                        }
                    } else {
                        isPulsing = false
                    }
                }

                // 2. Textual Status & Transcription Display (Not conveyed by color alone)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        // Textual state badge
                        Text(viewModel.listeningState.statusDescription.uppercased())
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badgeBackgroundColor)
                            .foregroundColor(badgeForegroundColor)
                            .cornerRadius(4)

                        if viewModel.isHandsFreeModeEnabled {
                            Text("HANDS-FREE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }

                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                // 3. Manual Pause / Resume Privacy Control Button
                if viewModel.isHandsFreeModeEnabled || viewModel.isListening || viewModel.isPaused {
                    Button {
                        Task {
                            if viewModel.isPaused {
                                await viewModel.resumeListening(onIntentRecognized: onCommandRecognized)
                            } else {
                                await viewModel.pauseListening()
                            }
                        }
                    } label: {
                        Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.title2)
                            .foregroundColor(viewModel.isPaused ? .green : .orange)
                            .padding(4)
                    }
                    .accessibilityLabel(viewModel.isPaused ? "Resume listening" : "Pause listening")
                    .accessibilityHint(viewModel.isPaused ? "Resumes continuous voice listening." : "Temporarily pauses microphone listening.")
                }

                // 4. Hands-Free Mode Toggle Button
                Button {
                    Task {
                        await viewModel.toggleHandsFreeMode(onIntentRecognized: onCommandRecognized)
                    }
                } label: {
                    Image(systemName: viewModel.isHandsFreeModeEnabled ? "waveform.badge.mic" : "waveform.slash")
                        .font(.title3)
                        .foregroundColor(viewModel.isHandsFreeModeEnabled ? .blue : .secondary)
                        .padding(4)
                }
                .accessibilityLabel(viewModel.isHandsFreeModeEnabled ? "Hands-Free Mode: On" : "Hands-Free Mode: Off")
                .accessibilityHint("Double-tap to toggle continuous hands-free voice control.")

                // 5. Spoken Help Button
                Button {
                    Task {
                        await viewModel.dispatchDirectIntent(.help, onExecute: onCommandRecognized)
                    }
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(4)
                }
                .accessibilityLabel("Voice Commands Help")
                .accessibilityHint("Reads list of supported voice commands aloud.")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Material.ultraThinMaterial)
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(borderStrokeColor, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
            .padding(.horizontal, 14)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Visual Helpers

    private var buttonBackgroundColor: Color {
        switch viewModel.listeningState {
        case .listening: return .red
        case .processing: return .purple
        case .speaking: return .green
        case .awaitingAnswer: return .blue
        case .clarificationRequired: return .orange
        case .paused: return .orange
        case .permissionRequired: return .red
        case .idle: return viewModel.isHandsFreeModeEnabled ? .blue : .secondary
        case .error: return .red
        }
    }

    private var buttonIconName: String {
        switch viewModel.listeningState {
        case .listening: return "stop.fill"
        case .processing: return "ellipsis"
        case .speaking: return "speaker.wave.2.fill"
        case .awaitingAnswer: return "mic.badge.plus"
        case .clarificationRequired: return "questionmark.bubble"
        case .paused: return "pause.fill"
        case .permissionRequired: return "lock.fill"
        case .idle: return "mic.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var badgeBackgroundColor: Color {
        switch viewModel.listeningState {
        case .listening: return Color.red.opacity(0.2)
        case .processing: return Color.purple.opacity(0.2)
        case .speaking: return Color.green.opacity(0.2)
        case .awaitingAnswer: return Color.blue.opacity(0.2)
        case .clarificationRequired: return Color.orange.opacity(0.2)
        case .paused: return Color.orange.opacity(0.2)
        case .permissionRequired: return Color.red.opacity(0.2)
        case .idle: return Color.gray.opacity(0.2)
        case .error: return Color.red.opacity(0.2)
        }
    }

    private var badgeForegroundColor: Color {
        switch viewModel.listeningState {
        case .listening: return .red
        case .processing: return .purple
        case .speaking: return .green
        case .awaitingAnswer: return .blue
        case .clarificationRequired: return .orange
        case .paused: return .orange
        case .permissionRequired: return .red
        case .idle: return .secondary
        case .error: return .red
        }
    }

    private var borderStrokeColor: Color {
        switch viewModel.listeningState {
        case .listening: return Color.red.opacity(0.5)
        case .paused: return Color.orange.opacity(0.5)
        default: return Color.gray.opacity(0.25)
        }
    }
}
