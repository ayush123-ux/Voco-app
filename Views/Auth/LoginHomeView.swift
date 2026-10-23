import SwiftUI

/// Welcome landing screen matching LoginHome.dart with direct Login / Sign-up actions and biometric access
public struct LoginHomeView: View {
    @ObservedObject public var viewModel: AuthViewModel
    public let onNavigateToSignIn: () -> Void
    public let onNavigateToSignUp: () -> Void
    public var onBiometricSignInCompleted: (() -> Void)?

    public init(
        viewModel: AuthViewModel,
        onNavigateToSignIn: @escaping () -> Void,
        onNavigateToSignUp: @escaping () -> Void,
        onBiometricSignInCompleted: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onNavigateToSignIn = onNavigateToSignIn
        self.onNavigateToSignUp = onNavigateToSignUp
        self.onBiometricSignInCompleted = onBiometricSignInCompleted
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.18, blue: 0.32), Color(red: 0.05, green: 0.08, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Brand Emblem
                Image(systemName: "waveform.and.person.filled")
                    .font(.system(size: 80))
                    .foregroundStyle(.linearGradient(colors: [.teal, .blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .cyan.opacity(0.3), radius: 12)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Welcome to VoCo")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .accessibilityAddTraits(.isHeader)

                    Text("Pronunciation practice, courses, and interactive speech learning.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 16) {
                    // Biometric Fast Login if enrolled
                    if viewModel.isBiometricEnrollmentEnabled && viewModel.isBiometricAvailable {
                        Button {
                            Task {
                                let success = await viewModel.signInWithBiometrics()
                                if success {
                                    onBiometricSignInCompleted?()
                                } else if let error = viewModel.errorMessage {
                                    AccessibilityHelper.announce("Biometric login failed: \(error)")
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: viewModel.biometricType == .faceID ? "faceid" : "touchid")
                                    .font(.title3)
                                Text("SIGN IN WITH \(viewModel.biometricType.displayName.uppercased())")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.green)
                            )
                            .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                        }
                        .disabled(viewModel.isProcessing)
                        .accessibilityLabel("Sign In with \(viewModel.biometricType.displayName)")
                        .accessibilityHint("Logs into your enrolled VoCo account using \(viewModel.biometricType.displayName)")
                    }

                    Button(action: onNavigateToSignIn) {
                        Text("LOGIN")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                            )
                            .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                    }
                    .accessibilityLabel("Log In")
                    .accessibilityHint("Navigates to the sign in screen")

                    Button(action: onNavigateToSignUp) {
                        Text("SIGN-UP")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                            )
                    }
                    .accessibilityLabel("Sign Up")
                    .accessibilityHint("Navigates to create a new VoCo account")
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }
}
