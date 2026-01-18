import Foundation

/// Q&A content extracted from blog posts 77-78
struct AsyncStreamContent {

    static let qaItems: [QAItem] = [
        QAItem(
            question: "What is AsyncStream and when do you use it?",
            answer: """
            AsyncStream lets you create custom AsyncSequences from any source: timers, callbacks, delegates, or manual yields. It's how you bridge imperative code to structured concurrency.

            Three key operations:
            • yield(_:) — emit a value
            • finish() — end the stream
            • finish(throwing:) — end with an error (AsyncThrowingStream only)
            """
        ),
        QAItem(
            question: "How do you convert a Timer to an AsyncStream?",
            answer: """
            Use the continuation to yield values and onTermination for cleanup:

            func makeTimerStream(interval: TimeInterval) -> AsyncStream<Date> {
                AsyncStream { continuation in
                    let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                        continuation.yield(Date())
                    }

                    continuation.onTermination = { @Sendable _ in
                        timer.invalidate()
                    }
                }
            }
            """
        ),
        QAItem(
            question: "What is the onTermination handler and when does it run?",
            answer: """
            onTermination is critical for cleanup. It runs when:
            • Consumer stops iterating
            • Task is cancelled
            • You call finish()

            You can also inspect what caused termination:
            - .cancelled — stream was cancelled
            - .finished — stream finished normally
            """
        ),
        QAItem(
            question: "What's a common mistake when creating AsyncStreams?",
            answer: """
            Forgetting to finish the stream!

            // BAD: Stream never ends
            AsyncStream<Int> { continuation in
                continuation.yield(1)
                continuation.yield(2)
                // Consumer waits forever for next value!
            }

            // GOOD: Signal completion
            AsyncStream<Int> { continuation in
                continuation.yield(1)
                continuation.yield(2)
                continuation.finish()  // Consumer's loop exits
            }
            """
        ),
        QAItem(
            question: "When should you use AsyncThrowingStream vs AsyncStream?",
            answer: """
            | Type | Use When |
            |------|----------|
            | AsyncStream | Errors are handled internally or impossible |
            | AsyncThrowingStream | Errors should propagate to consumer |

            With AsyncThrowingStream, you're saying "the consumer should handle failures."
            With AsyncStream, you're saying "I'll handle errors internally."
            """
        ),
        QAItem(
            question: "How do you consume an AsyncThrowingStream with error handling?",
            answer: """
            Use do-catch with for try await:

            do {
                for try await data in dataStream {
                    process(data)
                }
                // Only reaches here if finish() was called (no error)
                print("Stream completed successfully")
            } catch {
                // Only reaches here if finish(throwing:) was called
                print("Stream failed: \\(error)")
            }
            """
        ),
        QAItem(
            question: "Interview Tip: How would you modernize callback-based code?",
            answer: """
            AsyncStream is how you bridge imperative code (callbacks, delegates, timers) to structured concurrency. When asked about modernizing legacy code, this is often the answer.

            The continuation is thread-safe—you can yield from any context (main queue, background queue, etc.).
            """
        )
    ]

    static let exercises: [ExerciseItem] = [
        ExerciseItem(
            title: "Spot the Bug: Missing Finish",
            prompt: "In makeThrowingStream(), what happens if the loop completes normally without hitting the random failure? Trace through the code to find the missing call.",
            hint: "The stream yields values 1-5, but what happens after yielding 5 if it doesn't randomly fail?"
        ),
        ExerciseItem(
            title: "Spot the Bug: try? Swallows Cancellation",
            prompt: "In makeThrowingStream(), `try? await Task.sleep` swallows all errors including CancellationError. What happens if the consumer cancels while waiting?",
            hint: "Change try? to try and handle cancellation explicitly with Task.isCancelled"
        ),
        ExerciseItem(
            title: "Add Cleanup",
            prompt: "The makeThrowingStream function doesn't have an onTermination handler. What resource might leak if the consumer cancels mid-stream?",
            hint: "The internal Task keeps running even if the consumer stops iterating"
        )
    ]

    static let sourceCode: String = """
    import SwiftUI

    struct AsyncStreamView: View {
        @State private var countdownValue: Int?
        @State private var events: [String] = []
        @State private var isCountingDown = false
        @State private var task: Task<Void, Never>?

        var body: some View {
            List {
                Section("Try It: Countdown Timer") {
                    VStack(spacing: 16) {
                        if let value = countdownValue {
                            Text("\\(value)")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(value <= 3 ? .red : .primary)
                        } else {
                            Text("Ready")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }

                        Button(isCountingDown ? "Cancel" : "Start Countdown") {
                            if isCountingDown {
                                task?.cancel()
                            } else {
                                startCountdown()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }

        func startCountdown() {
            isCountingDown = true
            task = Task {
                let countdown = makeCountdownStream(from: 10)
                for await value in countdown {
                    await MainActor.run { countdownValue = value }
                }
                await MainActor.run {
                    isCountingDown = false
                    countdownValue = nil
                }
            }
        }
    }

    // MARK: - AsyncStream Factory

    func makeCountdownStream(from start: Int) -> AsyncStream<Int> {
        AsyncStream { continuation in
            var current = start

            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if current > 0 {
                    continuation.yield(current)
                    current -= 1
                } else {
                    continuation.yield(0)
                    continuation.finish()
                    timer.invalidate()
                }
            }

            RunLoop.main.add(timer, forMode: .common)

            continuation.onTermination = { @Sendable _ in
                timer.invalidate()
            }
        }
    }

    // MARK: - AsyncThrowingStream Example

    enum StreamError: Error {
        case connectionLost
        case timeout
    }

    func makeThrowingStream() -> AsyncThrowingStream<Int, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for i in 1...5 {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if i == 4 && Bool.random() {
                        continuation.finish(throwing: StreamError.connectionLost)
                        return
                    }
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
    }
    """
}
