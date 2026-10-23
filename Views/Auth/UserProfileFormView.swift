import SwiftUI

/// Profile intake form matching form.dart with accessible native pickers and validation
public struct UserProfileFormView: View {
    @State private var profile: UserProfile
    public let onProfileSaved: (UserProfile) -> Void

    @State private var validationError: String?
    @State private var showSuccessAlert = false

    public init(
        initialProfile: UserProfile = UserProfile(),
        onProfileSaved: @escaping (UserProfile) -> Void
    ) {
        _profile = State(initialValue: initialProfile)
        self.onProfileSaved = onProfileSaved
    }

    public var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Full Name", text: $profile.name)
                    .autocorrectionDisabled(true)

                TextField("Email Address", text: $profile.email)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled(true)

                Stepper(value: $profile.age, in: 5...120) {
                    HStack {
                        Text("Age")
                        Spacer()
                        Text("\(profile.age) years")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Demographics")) {
                Picker("Gender", selection: $profile.gender) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Marital Status", selection: $profile.maritalStatus) {
                    ForEach(MaritalStatus.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Education Level", selection: $profile.educationLevel) {
                    ForEach(EducationLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
            }

            Section(header: Text("Agreements")) {
                Toggle(isOn: $profile.termsAccepted) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I accept the Terms & Conditions")
                            .font(.subheadline)
                        Text("Required to personalize your pronunciation curriculum")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let error = validationError {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Section {
                Button(action: saveProfile) {
                    Text("Save & Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Learner Profile")
        .alert("Profile Saved", isPresented: $showSuccessAlert) {
            Button("Done") {
                onProfileSaved(profile)
            }
        } message: {
            Text("Your learner profile has been updated successfully.")
        }
    }

    private func saveProfile() {
        guard !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationError = "Please enter your name."
            return
        }

        guard !profile.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationError = "Please enter your email."
            return
        }

        guard profile.termsAccepted else {
            validationError = "You must agree to the Terms & Conditions to proceed."
            return
        }

        validationError = nil
        showSuccessAlert = true
    }
}
