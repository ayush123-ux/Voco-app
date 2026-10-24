import SwiftUI

/// Accessible 4-Quadrant Home Dashboard preserving home.dart structure and features
public struct HomeDashboardView: View {
    @ObservedObject public var container: ServiceContainer
    @ObservedObject public var authViewModel: AuthViewModel

    public let onSelectPronunciation: () -> Void
    public let onSelectTalkWithVoCo: () -> Void
    public let onSelectVoCoGyan: () -> Void
    public let onSelectGames: () -> Void
    public let onSignOut: () -> Void

    @State private var isSpeakingBanner = false
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showingLanguageSheet = false

    public init(
        container: ServiceContainer,
        authViewModel: AuthViewModel,
        onSelectPronunciation: @escaping () -> Void,
        onSelectTalkWithVoCo: @escaping () -> Void,
        onSelectVoCoGyan: @escaping () -> Void,
        onSelectGames: @escaping () -> Void,
        onSignOut: @escaping () -> Void
    ) {
        self.container = container
        self.authViewModel = authViewModel
        self.onSelectPronunciation = onSelectPronunciation
        self.onSelectTalkWithVoCo = onSelectTalkWithVoCo
        self.onSelectVoCoGyan = onSelectVoCoGyan
        self.onSelectGames = onSelectGames
        self.onSignOut = onSignOut
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // User Welcome Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello,")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(authViewModel.currentUser?.displayName ?? "VoCo Learner")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Button {
                        showingLanguageSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(languageManager.currentLanguage.flagEmoji)
                            Text(languageManager.currentLanguage.name)
                                .font(.footnote)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                    .accessibilityLabel("Change Language. Current: \(languageManager.currentLanguage.name)")
                    .accessibilityHint("Opens language selector to switch between Indian and international languages")

                    Button {
                        Task {
                            await authViewModel.signOut()
                            onSignOut()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                    .accessibilityLabel("Sign Out")
                    .accessibilityHint("Logs you out and returns to the login screen")
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // Voice / Accessibility Audio Guide Banner
                HStack(spacing: 14) {
                    Button {
                        toggleSpokenGuide()
                    } label: {
                        Image(systemName: isSpeakingBanner ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Listen to Page Guide")

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spoken Audio Guide")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Tap any quadrant below to practice, listen, or learn.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(14)
                .background(Color.blue.opacity(0.06))
                .cornerRadius(14)
                .padding(.horizontal)

                // The 4 Quadrants (Preserving home.dart's 4 core sections)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    // Quadrant 1: Pronunciation Guide (Top-Left)
                    QuadrantCardView(
                        title: "Pronunciation Guide",
                        subtitle: "Practice sentences with speech synthesis",
                        systemImage: "waveform.badge.mic",
                        gradientColors: [.indigo, .blue],
                        accessibilityHint: "Opens sentence pronunciation guide",
                        action: onSelectPronunciation
                    )

                    // Quadrant 2: Talk with VoCo (Top-Right)
                    QuadrantCardView(
                        title: "Talk with VoCo",
                        subtitle: "Voice assistant and conversational drills",
                        systemImage: "bubble.left.and.bubble.right.fill",
                        gradientColors: [.teal, .cyan],
                        accessibilityHint: "Opens conversational companion",
                        action: onSelectTalkWithVoCo
                    )

                    // Quadrant 3: VoCo Gyan (Bottom-Left)
                    QuadrantCardView(
                        title: "VoCo Gyan",
                        subtitle: "Technical courses and moral stories",
                        systemImage: "book.fill",
                        gradientColors: [.orange, .yellow],
                        accessibilityHint: "Opens learning curriculum and lessons",
                        action: onSelectVoCoGyan
                    )

                    // Quadrant 4: Games (Bottom-Right)
                    QuadrantCardView(
                        title: "Games & Quiz",
                        subtitle: "Interactive true/false comprehension tests",
                        systemImage: "gamecontroller.fill",
                        gradientColors: [.purple, .pink],
                        accessibilityHint: "Opens quizzes and educational games",
                        action: onSelectGames
                    )
                }
                .padding(.horizontal)
                .padding(.top, 4)

                Spacer(minLength: 24)
            }
        }
        .navigationTitle("VoCo Dashboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingLanguageSheet) {
            LanguageSelectionView(languageManager: languageManager, container: container)
        }
    }

    private func toggleSpokenGuide() {
        if container.speechService.isSpeaking {
            container.speechService.stopSpeaking()
            isSpeakingBanner = false
        } else {
            isSpeakingBanner = true
            Task {
                await container.speechService.speak(
                    text: "Welcome to VoCo. Select Quadrant 1 for Pronunciation Guide, Quadrant 2 to Talk with VoCo, Quadrant 3 for VoCo Gyan learning courses, or Quadrant 4 for Interactive Games and Quizzes."
                )
                await MainActor.run {
                    self.isSpeakingBanner = false
                }
            }
        }
    }
}
