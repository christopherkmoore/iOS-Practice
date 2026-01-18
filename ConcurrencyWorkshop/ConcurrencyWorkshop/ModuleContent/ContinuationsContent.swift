import Foundation

/// Q&A content extracted from blog posts 81-82
struct ContinuationsContent {

    static let qaItems: [QAItem] = [
        QAItem(
            question: "What are continuations and when do you use them?",
            answer: """
            Continuations let you wrap completion handlers as async functions without rewriting everything.

            // Old callback API
            func fetchUser(id: Int, completion: @escaping (User?) -> Void)

            // Wrapped as async
            func fetchUser(id: Int) async -> User? {
                await withCheckedContinuation { continuation in
                    fetchUser(id: id) { user in
                        continuation.resume(returning: user)
                    }
                }
            }
            """
        ),
        QAItem(
            question: "What is the critical rule for continuations?",
            answer: """
            Resume exactly once. Not zero times. Not twice. ONCE.

            // CRASH: Never resumed
            await withCheckedContinuation { continuation in
                if condition {
                    continuation.resume(returning: value)
                }
                // What if condition is false? Hangs forever!
            }

            // CRASH: Resumed twice
            await withCheckedContinuation { continuation in
                continuation.resume(returning: value1)
                continuation.resume(returning: value2)  // Fatal error!
            }
            """
        ),
        QAItem(
            question: "What's the difference between checked and unchecked continuations?",
            answer: """
            // Development: validates single resume
            await withCheckedContinuation { continuation in
                // Warns/crashes on misuse
            }

            // Production: no validation, slightly faster
            await withUnsafeContinuation { continuation in
                // You're on your own
            }

            Use withCheckedContinuation during development—it catches bugs. Switch to withUnsafeContinuation only for performance-critical code after thorough testing.
            """
        ),
        QAItem(
            question: "How do you handle multiple code paths with continuations?",
            answer: """
            Every path must resume. Use a flag to ensure exactly one resume:

            func fetchWithTimeout() async throws -> Data {
                try await withCheckedThrowingContinuation { continuation in
                    var didResume = false

                    api.fetch { data in
                        guard !didResume else { return }
                        didResume = true
                        continuation.resume(returning: data)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        guard !didResume else { return }
                        didResume = true
                        continuation.resume(throwing: TimeoutError())
                    }
                }
            }
            """
        ),
        QAItem(
            question: "When should you use Continuation vs AsyncStream?",
            answer: """
            | Situation | Use |
            |-----------|-----|
            | Single callback (one result) | Continuation |
            | Multiple callbacks (stream of results) | AsyncStream |
            | Delegate with one method | Continuation |
            | Delegate with ongoing events | AsyncStream |

            Continuation = one-shot result
            AsyncStream = multiple values over time
            """
        ),
        QAItem(
            question: "How do you wrap UIAlertController with a continuation?",
            answer: """
            extension UIViewController {
                func showConfirmation(title: String, message: String) async -> Bool {
                    await withCheckedContinuation { continuation in
                        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                            continuation.resume(returning: false)
                        })

                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            continuation.resume(returning: true)
                        })

                        present(alert, animated: true)
                    }
                }
            }

            // Usage
            if await showConfirmation(title: "Delete?", message: "This cannot be undone.") {
                deleteItem()
            }
            """
        ),
        QAItem(
            question: "How do you wrap animations with continuations?",
            answer: """
            Wait for animation to finish:

            func animate(view: UIView, to point: CGPoint) async {
                await withCheckedContinuation { continuation in
                    UIView.animate(withDuration: 0.3, animations: {
                        view.center = point
                    }, completion: { _ in
                        continuation.resume()
                    })
                }
            }

            // Sequential animations become linear
            await animate(view: box, to: CGPoint(x: 100, y: 100))
            await animate(view: box, to: CGPoint(x: 200, y: 100))
            await animate(view: box, to: CGPoint(x: 200, y: 200))
            """
        ),
        QAItem(
            question: "Interview Tip: How would you adopt async/await in a legacy codebase?",
            answer: """
            Continuations are the bridge between old and new. Explain: wrap existing completion handlers with continuations incrementally—no need to rewrite everything at once.

            Picker/alert continuation wrappers dramatically simplify flow—no more nested completion handlers.
            """
        )
    ]

    static let exercises: [ExerciseItem] = [
        ExerciseItem(
            title: "Spot the Bug: Missing Resume Path",
            prompt: "Write a continuation wrapper for an API that calls completion with nil on failure. What happens if you only resume on success?",
            hint: "Every code path must resume exactly once. If the API returns nil and you don't resume, the caller hangs forever."
        ),
        ExerciseItem(
            title: "Spot the Bug: Double Resume",
            prompt: "A timeout wrapper has both a success callback and a timer fallback. If the success fires, then the timer fires, what happens?",
            hint: "Use a `didResume` flag to ensure only one path resumes. Check the flag before each resume call."
        ),
        ExerciseItem(
            title: "Convert to Async",
            prompt: "Take a completion-handler API you use regularly and wrap it with withCheckedContinuation. Test that all code paths resume.",
            hint: "Common candidates: UIAlertController, PHPickerViewController, or any delegate-based API with a single callback."
        )
    ]

    static let sourceCode: String = """
    import SwiftUI

    struct ContinuationsView: View {
        @State private var result: String?
        @State private var isLoading = false

        var body: some View {
            List {
                Section("Try It: Wrap a Callback") {
                    Button("Simulate Legacy API Call") {
                        Task { await callLegacyAPI() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    if isLoading {
                        ProgressView()
                    }

                    if let result {
                        Text("Result: \\(result)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }

        func callLegacyAPI() async {
            isLoading = true
            result = nil

            // Wrap legacy callback API
            let data = await withCheckedContinuation { continuation in
                legacyFetch { result in
                    continuation.resume(returning: result)
                }
            }

            result = data
            isLoading = false
        }
    }

    // MARK: - Legacy API Simulation

    func legacyFetch(completion: @escaping (String) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            completion("Data from legacy API")
        }
    }

    // MARK: - Throwing Continuation Example

    func fetchWithTimeout() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            var didResume = false

            // Success path
            legacyFetch { result in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: result)
            }

            // Timeout path
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                guard !didResume else { return }
                didResume = true
                continuation.resume(throwing: TimeoutError())
            }
        }
    }

    struct TimeoutError: Error {}
    """
}
