import Foundation

/// Q&A content extracted from blog posts 83-84
struct CombiningPublishersContent {

    static let qaItems: [QAItem] = [
        QAItem(
            question: "How does combineLatest work and when do you use it?",
            answer: """
            combineLatest emits whenever ANY input changes, using the latest values from ALL inputs. Perfect for form validation.

            Publishers.CombineLatest3($email, $password, $acceptedTerms)
                .map { email, password, terms in
                    isValidEmail(email) && password.count >= 8 && terms
                }
                .assign(to: &$isFormValid)

            Every time ANY input emits, the combined output fires with the latest from all three.
            """
        ),
        QAItem(
            question: "How does merge work and when do you use it?",
            answer: """
            merge combines publishers of the SAME type into a single stream. Values pass through as they arrive.

            Publishers.Merge3(taps1, taps2, taps3)
                .sink { print("Tapped: \\($0)") }

            Use merge when:
            • Multiple event sources of the same type
            • You don't care which source emitted
            • Order is "as they arrive"
            """
        ),
        QAItem(
            question: "How does zip work and when do you use it?",
            answer: """
            zip waits for BOTH publishers to emit, then pairs them in order.

            Publishers.Zip(names, ages)
                .sink { print("\\($0) is \\($1) years old") }

            names.send("Alice")  // Nothing yet, waiting for age
            ages.send(30)        // Prints: Alice is 30 years old

            Use zip when:
            • Pairing related values from separate streams
            • Parallel requests that need to complete together
            • Strict 1:1 correspondence required
            """
        ),
        QAItem(
            question: "What's the difference between merge, zip, and combineLatest?",
            answer: """
            | Operator | Behavior | Use Case |
            |----------|----------|----------|
            | merge | Pass through as received | Multiple event sources |
            | zip | Pair 1:1 in order | Parallel operations needing both results |
            | combineLatest | Latest from all on any change | Derived state |

            Visual:
            merge: Events pass through as they arrive
            zip: Waits to pair values in order
            combineLatest: Fires on any change with latest values
            """
        ),
        QAItem(
            question: "What's a common mistake when combining publishers?",
            answer: """
            Using zip when you mean combineLatest:

            // WRONG: zip waits for new values from BOTH
            // If user rarely changes, you'll miss post updates
            Publishers.Zip($currentUser, $latestPosts)

            // RIGHT: combineLatest uses latest from each
            Publishers.CombineLatest($currentUser, $latestPosts)
            """
        ),
        QAItem(
            question: "How do you combine more than 4 publishers?",
            answer: """
            Nest them:

            Publishers.CombineLatest(
                Publishers.CombineLatest(pub1, pub2),
                Publishers.CombineLatest(pub3, pub4)
            )
            .map { (pair1, pair2) in
                let (v1, v2) = pair1
                let (v3, v4) = pair2
                return (v1, v2, v3, v4)
            }
            """
        ),
        QAItem(
            question: "Interview Tip: When asked about combining publishers, what should you clarify?",
            answer: """
            Clarify the requirements: "Do you need to pair them strictly (zip), merge into one stream (merge), or react to any change (combineLatest)?"

            This shows you understand the semantic differences between operators.

            combineLatest is the go-to for derived state from multiple sources. When asked about reactive form validation, this is the standard answer. Emphasize that it fires on ANY change, using the LATEST values.
            """
        )
    ]

    static let exercises: [ExerciseItem] = [
        ExerciseItem(
            title: "Spot the Bug: Wrong Operator",
            prompt: "If the form used zip instead of combineLatest, what would happen when only the email changes? Would isFormValid update?",
            hint: "zip waits for ALL publishers to emit new values. Changing just email wouldn't trigger validation—you'd need to change password AND toggle terms too."
        ),
        ExerciseItem(
            title: "Modify: Add Validation Feedback",
            prompt: "Extend the form to show specific error messages (e.g., 'Invalid email', 'Password too short'). How would you change the combineLatest pipeline?",
            hint: "Change the map output from Bool to a ValidationResult struct containing isValid and optional error messages."
        )
    ]

    static let sourceCode: String = """
    import SwiftUI
    import Combine

    struct CombiningPublishersView: View {
        @StateObject private var viewModel = FormViewModel()

        var body: some View {
            List {
                Section("Try It: Form Validation") {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password (8+ chars)", text: $viewModel.password)

                    Toggle("Accept Terms", isOn: $viewModel.acceptedTerms)

                    Button("Submit") {
                        // Handle submit
                    }
                    .disabled(!viewModel.isFormValid)

                    Text(viewModel.isFormValid ? "Form is valid" : "Please fill all fields correctly")
                        .font(.caption)
                        .foregroundColor(viewModel.isFormValid ? .green : .secondary)
                }
            }
        }
    }

    class FormViewModel: ObservableObject {
        @Published var email = ""
        @Published var password = ""
        @Published var acceptedTerms = false
        @Published var isFormValid = false

        private var cancellables = Set<AnyCancellable>()

        init() {
            Publishers.CombineLatest3($email, $password, $acceptedTerms)
                .map { email, password, terms in
                    self.isValidEmail(email) &&
                    password.count >= 8 &&
                    terms
                }
                .assign(to: &$isFormValid)
        }

        private func isValidEmail(_ email: String) -> Bool {
            email.contains("@") && email.contains(".")
        }
    }
    """
}
