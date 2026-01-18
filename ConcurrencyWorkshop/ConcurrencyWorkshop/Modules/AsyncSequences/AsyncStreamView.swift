import SwiftUI

// MARK: - Exercise: Building AsyncStreams
// Create custom async sequences using AsyncStream and AsyncThrowingStream

struct AsyncStreamView: View {
    var body: some View {
        ExerciseTabView(
            tryItView: AsyncStreamTryItView(),
            learnView: QAListView(items: AsyncStreamContent.qaItems),
            codeView: CodeViewer(
                title: "AsyncStreamView.swift",
                code: AsyncStreamContent.sourceCode,
                exercises: AsyncStreamContent.exercises
            )
        )
        .navigationTitle("Building AsyncStreams")
    }
}

// MARK: - Try It Tab

private struct AsyncStreamTryItView: View {
    @State private var countdownValue: Int?
    @State private var events: [String] = []
    @State private var isCountingDown = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        List {
            Section {
                Text("AsyncStream lets you create custom AsyncSequences from any source: timers, callbacks, delegates, or manual yields.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Try It: Countdown Timer") {
                VStack(spacing: 16) {
                    if let value = countdownValue {
                        Text("\(value)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(value <= 3 ? .red : .primary)
                    } else {
                        Text("Ready")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }

                    HStack {
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
                .frame(maxWidth: .infinity)
                .padding()
            }

            Section("Try It: Event Stream") {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Generate Events") {
                        generateEvents()
                    }
                    .buttonStyle(.bordered)

                    ForEach(events, id: \.self) { event in
                        Text(event)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .onDisappear {
            task?.cancel()
        }
    }

    func startCountdown() {
        isCountingDown = true
        countdownValue = 10

        task = Task {
            let countdown = makeCountdownStream(from: 10)

            for await value in countdown {
                await MainActor.run {
                    countdownValue = value
                }
            }

            await MainActor.run {
                isCountingDown = false
                countdownValue = nil
            }
        }
    }

    func generateEvents() {
        events = []

        Task {
            let eventStream = makeEventStream()

            for await event in eventStream {
                await MainActor.run {
                    events.append(event)
                }
            }
        }
    }
}

// MARK: - AsyncStream Factories

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

func makeEventStream() -> AsyncStream<String> {
    AsyncStream { continuation in
        let events = ["User logged in", "Data fetched", "Cache updated", "Sync complete"]

        Task {
            for event in events {
                try? await Task.sleep(nanoseconds: 500_000_000)

                if Task.isCancelled {
                    continuation.finish()
                    return
                }

                let timestamp = Date().formatted(date: .omitted, time: .standard)
                continuation.yield("[\(timestamp)] \(event)")
            }
            continuation.finish()
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

#Preview {
    NavigationStack {
        AsyncStreamView()
    }
}
