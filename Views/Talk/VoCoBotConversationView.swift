import SwiftUI

/// Message model for conversational bot practice
public struct ChatMessage: Identifiable, Equatable {
    public let id = UUID()
    public let text: String
    public let isUser: Bool
    public let timestamp = Date()

    public init(text: String, isUser: Bool) {
        self.text = text
        self.isUser = isUser
    }
}

/// Interactive conversation screen with VoCo Bot powered by Gemini Conversational AI
public struct VoCoBotConversationView: View {
    @ObservedObject public var container: ServiceContainer
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = []
    @State private var conversationHistory: [AIChatMessage] = []
    @State private var isBotThinking = false
    @State private var isBotSpeaking = false
    @State private var lastSpokenBotText: String = ""

    public init(container: ServiceContainer) {
        self.container = container
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header status banner
            HStack {
                Circle()
                    .fill(isBotSpeaking ? Color.green : (isBotThinking ? Color.orange : Color.blue))
                    .frame(width: 10, height: 10)
                Text(isBotSpeaking ? "VoCo is speaking..." : (isBotThinking ? "VoCo is thinking..." : "Ready to chat"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()

                if isBotSpeaking {
                    Button {
                        stopSpeaking()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .accessibilityLabel("Stop speaking")
                } else if !lastSpokenBotText.isEmpty {
                    Button {
                        speakText(lastSpokenBotText)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Repeat")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Repeat last answer")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.06))

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
                                        .accessibilityLabel("Listen to message: \(msg.text)")
                                    }
                                }

                                if !msg.isUser { Spacer() }
                            }
                            .id(msg.id)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(msg.isUser ? "You said" : "VoCo replied"): \(msg.text)")
                        }

                        if isBotThinking {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 6)
                                Text("VoCo is preparing your explanation...")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
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
                    quickChip("Explain binary search in simple words")
                    quickChip("Give me a speech tip")
                    quickChip("Ab Hindi mein samjhao")
                    quickChip("What is a linked list?")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            // Input Bar
            HStack(spacing: 12) {
                TextField("Ask anything or practice speaking...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .accessibilityLabel("Chat message input")

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isBotThinking)
                .accessibilityLabel("Send message")
                .accessibilityHint("Sends your question to VoCo AI")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .navigationTitle("Talk with VoCo")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    startNewConversation()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Start new conversation and clear chat history")
            }
        }
        .onAppear {
            if messages.isEmpty {
                startNewConversation()
            }
        }
        .onDisappear {
            stopSpeaking()
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
        .accessibilityLabel("Suggestion: \(text)")
        .accessibilityHint("Double tap to send this query")
    }

    private func startNewConversation() {
        stopSpeaking()
        conversationHistory.removeAll()
        let currentLangId = LanguageManager.shared.currentLanguage.id
        let greeting: String
        if currentLangId.contains("mr") {
            greeting = "नमस्कार! मी व्होको AI आहे. आज तुम्हाला काय शिकायचे किंवा विचारायचे आहे?"
        } else if currentLangId.contains("hi") {
            greeting = "नमस्ते! मैं वोको AI हूँ। आज आप क्या सीखना या पूछना चाहते हैं?"
        } else {
            greeting = "Hello! I am VoCo, your AI learning and language companion. Ask me any doubt or concept you would like to explore!"
        }
        messages = [ChatMessage(text: greeting, isUser: false)]
        lastSpokenBotText = greeting
        speakText(greeting)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(text: text, isUser: true))
        inputText = ""
        isBotThinking = true

        let activeLanguage = LanguageManager.shared.currentLanguage.name

        Task {
            let aiResponse = await container.aiService.sendMessage(
                text,
                history: conversationHistory,
                language: activeLanguage
            )

            await MainActor.run {
                self.isBotThinking = false
                let reply = aiResponse.reply
                self.messages.append(ChatMessage(text: reply, isUser: false))
                self.lastSpokenBotText = reply

                // Record history for conversational context
                self.conversationHistory.append(AIChatMessage(role: "user", text: text))
                self.conversationHistory.append(AIChatMessage(role: "model", text: reply))

                // Bound history
                if self.conversationHistory.count > 12 {
                    self.conversationHistory.removeFirst(2)
                }

                self.speakText(reply)
            }
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

    private func stopSpeaking() {
        container.speechService.stopSpeaking()
        isBotSpeaking = false
    }
}
