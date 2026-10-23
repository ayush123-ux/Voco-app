import SwiftUI

/// Talk with VoCo selection hub matching talkVoCop1.dart, talkVoCop2.dart, and talkVoCop3.dart
public struct TalkWithVoCoHubView: View {
    public let onSelectBot: () -> Void
    public let onSelectLocked: (String) -> Void

    public init(
        onSelectBot: @escaping () -> Void,
        onSelectLocked: @escaping (String) -> Void
    ) {
        self.onSelectBot = onSelectBot
        self.onSelectLocked = onSelectLocked
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Talk with VoCo")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Select a conversation partner to practice free-form speaking.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 12)

                // Option 1: VoCo Mitra -> VoCo Bot (Active)
                Button(action: onSelectBot) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.teal, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 58, height: 58)

                            Image(systemName: "cpu.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Talk to VoCo Bot")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Interactive")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                            }

                            Text("Speak with the AI assistant for practice, feedback, and tips.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Talk to VoCo Bot, interactive speech practice")

                // Option 2: VoCo Friend (Locked in original Flutter)
                Button {
                    onSelectLocked("VoCo Friend Companion")
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 58, height: 58)

                            Image(systemName: "person.2.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Talk to VoCo Friend")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("Peer-to-peer audio room for conversational practice.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.04))
                    .cornerRadius(18)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Talk to VoCo Friend, locked")

                // Option 3: VoCo Professional (Locked in original Flutter)
                Button {
                    onSelectLocked("VoCo Professional Coaching")
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 58, height: 58)

                            Image(systemName: "briefcase.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("VoCo Professional")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("Accredited speech therapy and executive coaching sessions.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.04))
                    .cornerRadius(18)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("VoCo Professional, locked")
            }
            .padding(.horizontal)
        }
        .navigationTitle("Talk with VoCo")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
