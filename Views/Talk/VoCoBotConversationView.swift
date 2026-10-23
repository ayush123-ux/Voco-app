import SwiftUI

/// Message model for conversational bot practice
public struct ChatMessage: Identifiable, Equatable {
    public let id = UUID()
    public let text: String
    public let isUser: Bool
    public let timestamp = Date()
}

/// Interactive conversation screen with VoCo Bot
public struct VoCoBotConversationView: View {
    @ObservedObject public var container: ServiceContainer
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            text: "Hello! I am VoCo Bot, your pronunciation and language companion. What would you like to practice today?",
            isUser: false
        )
    ]
    @State private var isBotSpeaking = false

    public init(container: ServiceContainer) {
        self.container = container
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.isUser { Spacer() }

                                VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                                    Text(msg.text)
                                        .font(.body)
                                        .foregroundColor(msg.isUser ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            msg.isUser
                                                ? Color.blue
                                                : Color.gray.opacity(0.12)
                                        )
                                        .cornerRadius(18)

                                    if !msg.isUser {
                                        Button {
                                            speakText(msg.text)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "speaker.wave.2")
                                                Text("Listen")
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(.blue)
                                        }
                                        .padding(.leading, 6)
                                    }
                                }

                                if !msg.isUser { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Quick suggestion chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickChip("Help me practice vowels")
                    quickChip("Give me a tongue twister")
                    quickChip("Explain linked lists")
                    quickChip("Give me pronunciation tips")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            // Input Bar
            HStack(spacing: 12) {
                TextField("Type your message...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Send Message")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .navigationTitle("VoCo Bot")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onDisappear {
            container.speechService.stopSpeaking()
        }
    }

    private func quickChip(_ text: String) -> some View {
        Button {
            inputText = text
            sendMessage()
        } label: {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(text: text, isUser: true))
        inputText = ""

        // Generate intelligent reply matching VoCo curriculum
        let response = generateBotResponse(for: text)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            messages.append(ChatMessage(text: response, isUser: false))
            speakText(response)
        }
    }

    private func generateBotResponse(for query: String) -> String {
        let lower = query.lowercased()
        if lower.contains("vowel") {
            return "Try practicing the five pure vowels: A as in father, E as in met, I as in see, O as in note, and U as in rule. Open your mouth wide and resonate from your diaphragm!"
        } else if lower.contains("tongue twister") {
            return "Here is a classic twister: 'She sells seashells by the seashore.' Focus on contrasting the sharp 'S' sound with the soft 'SH' sound."
        } else if lower.contains("linked list") {
            return "A linked list is a linear data structure where elements are not stored at contiguous memory locations. Instead, each node stores a reference or pointer to the next node."
        } else if lower.contains("tip") || lower.contains("pronunciation") {
            return "A great speech tip is to slow down by twenty percent. Record your voice in the Pronunciation Guide, then listen to your recording right next to the VoCo benchmark!"
        } else {
            return "That's an interesting thought! Keep practicing speaking aloud. Pronunciation improves rapidly with daily active repetition."
        }
    }

    private func speakText(_ text: String) {
        Task {
            isBotSpeaking = true
            await container.speechService.speak(text: text)
            await MainActor.run {
                self.isBotSpeaking = false
            }
        }
    }
}
