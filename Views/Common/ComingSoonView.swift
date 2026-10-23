import SwiftUI

/// Coming soon placeholder screen preserving comingsoon.dart
public struct ComingSoonView: View {
    public let title: String
    public let onBack: () -> Void

    public init(
        title: String = "Feature In Development",
        onBack: @escaping () -> Void
    ) {
        self.title = title
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 130, height: 130)

                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("This module is undergoing active development and will be released in an upcoming update.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button(action: onBack) {
                Text("Return to Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
