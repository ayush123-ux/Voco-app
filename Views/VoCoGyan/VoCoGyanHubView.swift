import SwiftUI

/// VoCo Gyan Hub matching story1.dart with Technical and Non-Technical categories
public struct VoCoGyanHubView: View {
    public let onSelectCategory: (CourseCategory) -> Void

    public init(onSelectCategory: @escaping (CourseCategory) -> Void) {
        self.onSelectCategory = onSelectCategory
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header info
                VStack(alignment: .leading, spacing: 6) {
                    Text("VoCo Gyan")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Choose a learning domain to expand your technical and conversational mastery.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 12)

                ForEach(CourseCategory.allCases) { category in
                    Button {
                        onSelectCategory(category)
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(category == .technical ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                                    .frame(width: 60, height: 60)

                                Image(systemName: category.iconName)
                                    .font(.title2)
                                    .foregroundColor(category == .technical ? .blue : .orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.rawValue)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Text(category.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(category.rawValue). \(category.subtitle)")
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("VoCo Gyan")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
