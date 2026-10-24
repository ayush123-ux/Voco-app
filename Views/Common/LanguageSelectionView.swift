import SwiftUI

/// Accessible language selector sheet supporting dynamic switching between Indian & International languages
public struct LanguageSelectionView: View {
    @ObservedObject public var languageManager: LanguageManager
    public let container: ServiceContainer
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery: String = ""

    @MainActor
    public init(languageManager: LanguageManager = LanguageManager.shared, container: ServiceContainer) {
        self.languageManager = languageManager
        self.container = container
    }

    private var filteredLanguages: [AppLanguage] {
        let all = AppLanguage.standardLanguages
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return all
        }
        let q = searchQuery.lowercased()
        return all.filter {
            $0.name.lowercased().contains(q) ||
            $0.nativeName.lowercased().contains(q) ||
            $0.id.lowercased().contains(q)
        }
    }

    private var indianLanguages: [AppLanguage] {
        filteredLanguages.filter { $0.region == .indian }
    }

    private var internationalLanguages: [AppLanguage] {
        filteredLanguages.filter { $0.region == .international }
    }

    public var body: some View {
        NavigationView {
            List {
                if !indianLanguages.isEmpty {
                    Section(header: Text("Indian Languages").font(.headline)) {
                        ForEach(indianLanguages) { lang in
                            languageRow(lang)
                        }
                    }
                }

                if !internationalLanguages.isEmpty {
                    Section(header: Text("International Languages").font(.headline)) {
                        ForEach(internationalLanguages) { lang in
                            languageRow(lang)
                        }
                    }
                }
            }
            .searchable(text: $searchQuery, prompt: "Search language or script...")
            .navigationTitle("Select Language")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Dismisses the language picker")
                }
            }
        }
    }

    @ViewBuilder
    private func languageRow(_ lang: AppLanguage) -> some View {
        let isSelected = languageManager.currentLanguage.id == lang.id

        Button {
            languageManager.setLanguage(lang, container: container)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Text(lang.flagEmoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(lang.nativeName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if !lang.isSpeechRecognitionAvailable {
                            Text("Fallback")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }

                    Text("\(lang.name) (\(lang.id))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .accessibilityLabel("\(lang.name), \(lang.nativeName)\(isSelected ? ", currently selected" : "")")
        .accessibilityHint("Double tap to switch speech recognition and voice guidance to \(lang.name)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
