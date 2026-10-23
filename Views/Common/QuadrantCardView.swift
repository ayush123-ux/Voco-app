import SwiftUI

/// Accessible tactile quadrant card for the VoCo 4-quadrant layout
public struct QuadrantCardView: View {
    public let title: String
    public let subtitle: String
    public let systemImage: String
    public let gradientColors: [Color]
    public let accessibilityHint: String
    public let action: () -> Void

    public init(
        title: String,
        subtitle: String,
        systemImage: String,
        gradientColors: [Color],
        accessibilityHint: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.gradientColors = gradientColors
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                            .shadow(color: gradientColors.first?.opacity(0.3) ?? .clear, radius: 6, y: 3)

                        Image(systemName: systemImage)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            .background(Color.gray.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(18)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
}
