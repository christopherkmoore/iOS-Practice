import Foundation

/// Q&A content extracted from blog posts 75-76
struct ConsumingAsyncSequenceContent {

    static let qaItems: [QAItem] = [
        QAItem(
            question: "What is AsyncSequence and how do you consume it?",
            answer: """
            AsyncSequence is like Sequence, but each element is delivered asynchronously. You consume it with `for await`:

            for await number in numberStream {
                print("Got: \\(number)")
            }

            The loop suspends at each iteration, waiting for the next value. When the sequence ends, the loop exits normally.
            """
        ),
        QAItem(
            question: "How does an AsyncSequence work under the hood?",
            answer: """
            AsyncSequence requires two things:
            1. An AsyncIterator with a `next()` method
            2. A `makeAsyncIterator()` function

            The key method is `next()`:
            • Returns the next value when available
            • Returns `nil` to signal the end
            • Can throw errors
            """
        ),
        QAItem(
            question: "How does task cancellation work with for-await loops?",
            answer: """
            Task cancellation works automatically—one of the best features!

            let task = Task {
                for await value in someStream {
                    process(value)
                }
            }
            task.cancel()  // Loop exits cleanly

            When the task is cancelled, the `for await` loop stops iterating. No manual checking required.
            """
        ),
        QAItem(
            question: "How do you handle errors in throwing async sequences?",
            answer: """
            For throwing sequences, use `for try await` and wrap in do-catch:

            do {
                for try await data in networkStream {
                    process(data)
                }
            } catch {
                print("Stream failed: \\(error)")
            }
            """
        ),
        QAItem(
            question: "What's the mental model for for-await?",
            answer: """
            Think of `for await` as:
            1. Pull-based: You request the next value
            2. Suspending: Waits without blocking a thread
            3. Cancellation-aware: Respects task cancellation
            4. Sequential: One value at a time, in order
            """
        ),
        QAItem(
            question: "What built-in AsyncSequences does Swift provide?",
            answer: """
            Swift provides several built-in AsyncSequences:

            • URL.lines - Read files line by line
            • FileHandle.bytes - Stream bytes from a file
            • NotificationCenter.notifications - Subscribe to notifications
            • URLSession.bytes - Stream download data as it arrives

            These cover most common use cases without building custom sequences.
            """
        ),
        QAItem(
            question: "Interview Tip: How would you explain AsyncSequence?",
            answer: """
            AsyncSequence is the async equivalent of Sequence—same protocol pattern (makeAsyncIterator, next()), but with suspension points.

            This shows you understand the design philosophy, not just the syntax. Knowing built-in sequences like URL.lines and URLSession.bytes demonstrates practical experience.
            """
        )
    ]

    static let exercises: [ExerciseItem] = [
        ExerciseItem(
            title: "Spot the Bug: Ignored Cancellation",
            prompt: "If you remove `try Task.checkCancellation()` from the loop, what happens when the user taps Cancel? Does the stream stop immediately?",
            hint: "Without cancellation checking, the loop continues processing all remaining items. Task.sleep throws on cancellation, but try? swallows it."
        ),
        ExerciseItem(
            title: "Modify: Add Early Exit",
            prompt: "Add logic to break out of the for-await loop when a specific number (e.g., 5) is received.",
            hint: "Use `if number == 5 { break }` inside the loop. The stream will stop being consumed."
        )
    ]

    static let sourceCode: String = """
    import SwiftUI
    import Combine

    struct ConsumingAsyncSequenceView: View {
        @State private var numbers: [Int] = []
        @State private var isRunning = false
        @State private var task: Task<Void, Never>?

        var body: some View {
            List {
                Section("Try It: Number Stream") {
                    HStack {
                        Button(isRunning ? "Cancel" : "Start Stream") {
                            if isRunning {
                                task?.cancel()
                                isRunning = false
                            } else {
                                startNumberStream()
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Spacer()

                        Button("Clear") { numbers = [] }
                            .buttonStyle(.bordered)
                            .disabled(isRunning)
                    }

                    ForEach(numbers, id: \\.self) { number in
                        Text("Received: \\(number)")
                    }
                }
            }
        }

        func startNumberStream() {
            isRunning = true
            numbers = []

            task = Task {
                let stream = NumberStream(count: 10, delay: 0.5)

                do {
                    for try await number in stream {
                        try Task.checkCancellation()
                        await MainActor.run {
                            numbers.append(number)
                        }
                    }
                } catch {
                    // Cancelled or error
                }

                await MainActor.run {
                    isRunning = false
                }
            }
        }
    }

    // Custom AsyncSequence
    struct NumberStream: AsyncSequence {
        typealias Element = Int

        let count: Int
        let delay: TimeInterval

        struct AsyncIterator: AsyncIteratorProtocol {
            var current = 0
            let count: Int
            let delay: TimeInterval

            mutating func next() async throws -> Int? {
                guard current < count else { return nil }
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                current += 1
                return current
            }
        }

        func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(count: count, delay: delay)
        }
    }
    """
}
