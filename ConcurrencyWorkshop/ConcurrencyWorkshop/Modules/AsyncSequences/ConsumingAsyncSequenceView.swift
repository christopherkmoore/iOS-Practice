import SwiftUI
import Combine

// MARK: - Exercise: Consuming AsyncSequence
// Learn how to iterate over asynchronous sequences using for-await-in loops

struct ConsumingAsyncSequenceView: View {
    var body: some View {
        ExerciseTabView(
            tryItView: ConsumingAsyncSequenceTryItView(),
            learnView: QAListView(items: ConsumingAsyncSequenceContent.qaItems),
            codeView: CodeViewer(
                title: "ConsumingAsyncSequenceView.swift",
                code: ConsumingAsyncSequenceContent.sourceCode,
                exercises: ConsumingAsyncSequenceContent.exercises
            )
        )
        .navigationTitle("Consuming AsyncSequence")
    }
}

// MARK: - Try It Tab

private struct ConsumingAsyncSequenceTryItView: View {
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
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .onDisappear {
            task?.cancel()
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

#Preview {
    NavigationStack {
        ConsumingAsyncSequenceView()
    }
}
