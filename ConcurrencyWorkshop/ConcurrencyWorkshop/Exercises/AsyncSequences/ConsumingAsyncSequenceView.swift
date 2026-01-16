import SwiftUI
import Combine

// MARK: - Exercise: Consuming AsyncSequence
// Learn how to iterate over asynchronous sequences using for-await-in loops

struct ConsumingAsyncSequenceView: View {
    @State private var numbers: [Int] = []
    @State private var isRunning = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        List {
            Section {
                Text("AsyncSequence is a protocol for sequences that deliver elements asynchronously. Use `for await` to consume them.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Key Concepts") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• `for await item in sequence` - iterate async")
                    Text("• Suspends at each iteration until next value")
                    Text("• Automatically handles cancellation")
                    Text("• Works with any AsyncSequence type")
                }
                .font(.caption)
            }

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

                    Button("Clear") {
                        numbers = []
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRunning)
                }

                if isRunning {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }

                ForEach(numbers, id: \.self) { number in
                    Text("Received: \(number)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Section("Built-in AsyncSequences") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• `URL.lines` - async lines from a file/URL")
                    Text("• `FileHandle.bytes` - async byte stream")
                    Text("• `NotificationCenter.notifications`")
                    Text("• `URLSession.bytes(from:)` - streaming download")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Consuming AsyncSequence")
        .onDisappear {
            task?.cancel()
        }
    }

    func startNumberStream() {
        isRunning = true
        numbers = []

        task = Task {
            // Create a simple async sequence
            let stream = NumberStream(count: 10, delay: 0.5)

            do {
                for try await number in stream {
                    // Check cancellation
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

// MARK: - Custom AsyncSequence Example

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

// MARK: - URL Lines Example

class URLLinesDemo: ObservableObject {
    @Published var lines: [String] = []
    @Published var isLoading = false

    func fetchLines(from url: URL) async {
        await MainActor.run { isLoading = true; lines = [] }

        do {
            // url.lines is an AsyncSequence!
            for try await line in url.lines {
                await MainActor.run {
                    lines.append(line)
                }
            }
        } catch {
            print("Error: \(error)")
        }

        await MainActor.run { isLoading = false }
    }
}

// MARK: - NotificationCenter Example

/*
 // NotificationCenter provides an AsyncSequence for notifications:

 func observeNotifications() async {
     let notifications = NotificationCenter.default.notifications(
         named: UIApplication.didBecomeActiveNotification
     )

     for await notification in notifications {
         print("App became active: \(notification)")
     }
 }
 */

#Preview {
    NavigationStack {
        ConsumingAsyncSequenceView()
    }
}
