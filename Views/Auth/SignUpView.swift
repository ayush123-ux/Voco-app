import SwiftUI

/// Sign-up screen preserving all behaviors from register.dart
public struct SignUpView: View {
    @ObservedObject public var viewModel: AuthViewModel
    public let onNavigateToSignIn: () -> Void
    public let onSignUpCompleted: () -> Void

    public init(
        viewModel: AuthViewModel,
        onNavigateToSignIn: @escaping () -> Void,
        onSignUpCompleted: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onNavigateToSignIn = onNavigateToSignIn
        self.onSignUpCompleted = onSignUpCompleted
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Join VoCo and begin your pronunciation training")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)

                // Error Banner
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

                // Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

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
                        }
                        .padding()
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password (at least 6 characters)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            SecureField("Choose password", text: $viewModel.password)
                                .accessibilityLabel("Password (at least 6 characters)")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "lock.rotation")
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            SecureField("Re-enter password", text: $viewModel.confirmPassword)
                                .accessibilityLabel("Confirm Password")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(12)
                    }
                }

                // Sign Up Action Button
                Button {
                    Task {
                        let success = await viewModel.signUp()
                        if success {
                            onSignUpCompleted()
                        } else if let error = viewModel.errorMessage {
                            AccessibilityHelper.announce("Sign up failed: \(error)")
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 6)
                        }
                        Text("Create VoCo Account")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                    .shadow(color: .blue.opacity(0.3), radius: 6, y: 3)
                }
                .disabled(viewModel.isProcessing)
                .accessibilityLabel("Create Account")
                .accessibilityHint("Validates information and registers a new VoCo profile")

                Spacer(minLength: 20)

                // Sign In Link
                HStack {
                    Spacer()
                    Text("Already have an account?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button("Sign In", action: onNavigateToSignIn)
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .accessibilityHint("Navigates back to the sign in screen")
                    Spacer()
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Sign Up")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onChange(of: viewModel.errorMessage) { newError in
            if let err = newError {
                AccessibilityHelper.announce("Error: \(err)")
            }
        }
    }
}
