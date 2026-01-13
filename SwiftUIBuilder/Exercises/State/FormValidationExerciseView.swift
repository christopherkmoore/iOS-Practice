import SwiftUI

// MARK: - Exercise: Build a form with validation
// Requirements:
// 1. Form with various input types (text, picker, toggle, stepper)
// 2. Real-time validation with error messages
// 3. Submit button disabled until form is valid
// 4. Show success state after submission

struct FormValidationExerciseView: View {
    @StateObject private var formModel = RegistrationFormModel()
    @State private var showSuccessAlert = false

    var body: some View {
        Form {
            Section("Personal Info") {
                TextField("Full Name", text: $formModel.fullName)
                    .textContentType(.name)

                if let error = formModel.fullNameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                TextField("Email", text: $formModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                if let error = formModel.emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section("Password") {
                SecureField("Password", text: $formModel.password)
                    .textContentType(.newPassword)

                if let error = formModel.passwordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                PasswordStrengthView(strength: formModel.passwordStrength)

                SecureField("Confirm Password", text: $formModel.confirmPassword)

                if let error = formModel.confirmPasswordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section("Preferences") {
                Picker("Country", selection: $formModel.country) {
                    Text("Select...").tag("")
                    ForEach(formModel.countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }

                if let error = formModel.countryError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Stepper("Age: \(formModel.age)", value: $formModel.age, in: 13...120)

                Toggle("Accept Terms & Conditions", isOn: $formModel.acceptedTerms)

                if let error = formModel.termsError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button {
                    submitForm()
                } label: {
                    HStack {
                        Spacer()
                        Text("Register")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!formModel.isValid)
            }
        }
        .navigationTitle("Registration")
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("OK") {
                formModel.reset()
            }
        } message: {
            Text("Account created for \(formModel.fullName)")
        }
    }

    private func submitForm() {
        guard formModel.isValid else { return }
        showSuccessAlert = true
    }
}

class RegistrationFormModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var country = ""
    @Published var age = 18
    @Published var acceptedTerms = false

    let countries = ["United States", "Canada", "United Kingdom", "Australia", "Germany", "France", "Japan"]

    var fullNameError: String? {
        guard !fullName.isEmpty else { return nil }
        if fullName.count < 2 {
            return "Name must be at least 2 characters"
        }
        return nil
    }

    var emailError: String? {
        guard !email.isEmpty else { return nil }
        let emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        if email.wholeMatch(of: emailRegex) == nil {
            return "Please enter a valid email address"
        }
        return nil
    }

    var passwordError: String? {
        guard !password.isEmpty else { return nil }
        if password.count < 8 {
            return "Password must be at least 8 characters"
        }
        return nil
    }

    var passwordStrength: PasswordStrength {
        if password.isEmpty { return .none }
        if password.count < 8 { return .weak }

        var score = 0
        if password.count >= 12 { score += 1 }
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { "!@#$%^&*()".contains($0) }) { score += 1 }

        switch score {
        case 0...1: return .weak
        case 2: return .medium
        default: return .strong
        }
    }

    var confirmPasswordError: String? {
        guard !confirmPassword.isEmpty else { return nil }
        if confirmPassword != password {
            return "Passwords do not match"
        }
        return nil
    }

    var countryError: String? {
        // Only show error after user has interacted
        nil
    }

    var termsError: String? {
        nil
    }

    var isValid: Bool {
        !fullName.isEmpty &&
        fullNameError == nil &&
        !email.isEmpty &&
        emailError == nil &&
        !password.isEmpty &&
        passwordError == nil &&
        !confirmPassword.isEmpty &&
        confirmPasswordError == nil &&
        !country.isEmpty &&
        acceptedTerms
    }

    func reset() {
        fullName = ""
        email = ""
        password = ""
        confirmPassword = ""
        country = ""
        age = 18
        acceptedTerms = false
    }
}

enum PasswordStrength {
    case none, weak, medium, strong

    var color: Color {
        switch self {
        case .none: return .gray
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }

    var label: String {
        switch self {
        case .none: return ""
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}

struct PasswordStrengthView: View {
    let strength: PasswordStrength

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < strengthLevel ? strength.color : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
            Text(strength.label)
                .font(.caption)
                .foregroundColor(strength.color)
        }
    }

    var strengthLevel: Int {
        switch strength {
        case .none: return 0
        case .weak: return 1
        case .medium: return 2
        case .strong: return 3
        }
    }
}

#Preview {
    NavigationStack {
        FormValidationExerciseView()
    }
}
