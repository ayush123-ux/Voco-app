import SwiftUI

/// Welcome splash screen matching welcome.dart (3-second duration with auto-advance)
public struct SplashScreenView: View {
    public let onFinished: () -> Void

    @State private var isAnimating = false
    @State private var opacity = 0.0

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.28, blue: 0.45), Color(red: 0.08, green: 0.14, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Animated VoCo Mascot / Wave Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.15 : 0.95)

                    Image(systemName: "waveform.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.linearGradient(colors: [.cyan, .white], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .blue.opacity(0.5), radius: 10, y: 5)
                }
                .accessibilityLabel("VoCo Logo")

                Text("VoCo")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)

                Text("Empowering Your Voice & Fluency")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.bottom, 48)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }

            // Matches Flutter 3-second splash timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onFinished()
            }
        }
    }
}
