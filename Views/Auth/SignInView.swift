import SwiftUI

/// Sign-in screen preserving all behaviors from login.dart with biometric and voice-assisted email capabilities
public struct SignInView: View {
    @ObservedObject public var viewModel: AuthViewModel
    public let onNavigateToSignUp: () -> Void
    public let onSignInCompleted: () -> Void

    @State private var showForgotPasswordDialog = false
    @State private var forgotPasswordEmail = ""
    @State private var alertMessage: String?
    @State private var showAlert = false

    public init(
        viewModel: AuthViewModel,
        onNavigateToSignUp: @escaping () -> Void,
        onSignInCompleted: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onNavigateToSignUp = onNavigateToSignUp
        self.onSignInCompleted = onSignInCompleted
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Sign in to your VoCo account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)

                // Error Banner if present
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .accessibilityHidden(true)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error: \(errorMessage)")
                }

                // Spoken Email Feedback Banner
                if let feedback = viewModel.voiceSpokenFeedback {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.emailConfirmed ? "checkmark.circle.fill" : "mic.fill")
                            .foregroundColor(viewModel.emailConfirmed ? .green : .blue)
                            .accessibilityHidden(true)
                        Text(feedback)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Voice email status: \(feedback)")
                }

                // Biometric Quick Sign-in Button (if enrolled and available)
                if viewModel.isBiometricEnrollmentEnabled && viewModel.isBiometricAvailable {
                    Button {
                        Task {
                            let success = await viewModel.signInWithBiometrics()
                            if success {
                                onSignInCompleted()
                            } else if let error = viewModel.errorMessage {
                                AccessibilityHelper.announce("Biometric sign in failed: \(error)")
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: viewModel.biometricType == .faceID ? "faceid" : "touchid")
                                .font(.title3)
                            Text("Sign In with \(viewModel.biometricType.displayName)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.3), radius: 5, y: 2)
                    }
                    .disabled(viewModel.isProcessing)
                    .accessibilityLabel("Sign in with \(viewModel.biometricType.displayName)")
                    .accessibilityHint("Authenticates using your stored \(viewModel.biometricType.displayName) credentials")

                    HStack {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                        Text("OR SIGN IN WITH PASSWORD")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }
                    .accessibilityHidden(true)
                }

                // Input Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Email Address")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            if viewModel.emailConfirmed {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                    .accessibilityLabel("Confirmed")
                            }
                        }

                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            TextField("name@example.com", text: $viewModel.email)
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                #endif
                                .autocorrectionDisabled(true)
                                .accessibilityLabel("Email Address")
                                .accessibilityValue(viewModel.email.isEmpty ? "Empty" : viewModel.email)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            SecureField("Enter your password", text: $viewModel.password)
                                .accessibilityLabel("Password")
                                .accessibilityHint("Password input field. For security, passwords are typed securely and never spoken aloud.")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(12)
                    }
                }

                // Forgot Password Button
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        forgotPasswordEmail = viewModel.email
                        showForgotPasswordDialog = true
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .accessibilityHint("Opens password reset dialog")
                }

                // Sign In Button
                Button {
                    Task {
                        let success = await viewModel.signIn()
                        if success {
                            onSignInCompleted()
                        } else if let error = viewModel.errorMessage {
                            AccessibilityHelper.announce("Sign in failed: \(error)")
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 6)
                        }
                        Text("Sign In")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                    .shadow(color: .blue.opacity(0.3), radius: 6, y: 3)
                }
                .disabled(viewModel.isProcessing)
                .accessibilityLabel("Sign In")
                .accessibilityHint("Validates email and password to log in")

                Spacer(minLength: 20)

                // Sign Up Footer Link
                HStack {
                    Spacer()
                    Text("Don't have an account?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button("Sign Up", action: onNavigateToSignUp)
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .accessibilityHint("Navigates to the sign up screen")
                    Spacer()
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Sign In")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onChange(of: viewModel.errorMessage) { newError in
            if let err = newError {
                AccessibilityHelper.announce("Error: \(err)")
            }
        }
        .alert("Reset Password", isPresented: $showForgotPasswordDialog) {
            TextField("Your email address", text: $forgotPasswordEmail)
            Button("Send Reset Link") {
                Task {
                    viewModel.email = forgotPasswordEmail
                    let success = await viewModel.sendPasswordReset()
                    if success {
                        alertMessage = "Password reset instructions sent to \(forgotPasswordEmail)."
                        showAlert = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter the email address registered with VoCo.")
        }
        .alert("VoCo", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            if let alertMessage = alertMessage {
                Text(alertMessage)
            }
        }
        .alert("Enable \(viewModel.biometricType.displayName)?", isPresented: $viewModel.showBiometricEnrollmentPrompt) {
            Button("Enable") {
                viewModel.setBiometricEnrollment(enabled: true)
                onSignInCompleted()
            }
            Button("Not Now", role: .cancel) {
                viewModel.setBiometricEnrollment(enabled: false)
                onSignInCompleted()
            }
        } message: {
            Text("Would you like to use \(viewModel.biometricType.displayName) for faster, secure, hands-free authentication next time?")
        }
    }
}
