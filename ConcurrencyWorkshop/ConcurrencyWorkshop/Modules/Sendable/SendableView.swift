import SwiftUI
import Combine

// MARK: - Exercise: Sendable Protocol
// Ensure thread-safe data transfer across actor boundaries

struct SendableView: View {
    var body: some View {
        ExerciseTabView(
            tryItView: SendableTryItView(),
            learnView: QAListView(items: SendableContent.qaItems),
            codeView: CodeViewer(
                title: "SendableView.swift",
                code: SendableContent.sourceCode,
                exercises: SendableContent.exercises
            )
        )
        .navigationTitle("Sendable Protocol")
    }
}

// MARK: - Try It Tab

private struct SendableTryItView: View {
    @StateObject private var viewModel = SendableDemoViewModel()

    var body: some View {
        List {
            Section {
                Text("Sendable is a marker protocol that indicates a type is safe to share across concurrency domains (threads, actors). Swift 6 enforces this strictly.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Try It: Sendable Types") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Test Value Type") {
                        viewModel.testValueType()
                    }
                    .buttonStyle(.bordered)

                    Button("Test Actor") {
                        Task { await viewModel.testActor() }
                    }
                    .buttonStyle(.borderedProminent)

                    ForEach(viewModel.results, id: \.self) { result in
                        Text(result)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Section("Why Sendable Matters") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When you pass data to/from an actor or Task, Swift checks if it's safe:")
                    Text("• Value types (structs, enums) with Sendable properties = Safe")
                    Text("• Actors = Always safe (isolation)")
                    Text("• Classes = Unsafe unless immutable or synchronized")
                    Text("• Closures = Must be @Sendable")
                }
                .font(.caption)
            }

            Section("Swift 6 Strict Mode") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Swift 6 enables strict concurrency checking by default:")
                    Text("• All Sendable violations become errors")
                    Text("• Passing non-Sendable across boundaries = error")
                    Text("• @unchecked Sendable requires careful review")

                    Text("Enable now: Swift Settings → Strict Concurrency → Complete")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .font(.caption)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
    }
}

// MARK: - ViewModel

@MainActor
class SendableDemoViewModel: ObservableObject {
    @Published var results: [String] = []

    func testValueType() {
        results = []

        let point = SendablePoint(x: 10, y: 20)

        Task {
            let processed = await processPoint(point)
            results.append("Processed: \(processed)")
        }
    }

    func testActor() async {
        results = []

        let counter = SafeCounter()
        await counter.increment()
        await counter.increment()
        let value = await counter.count
        results.append("Counter: \(value)")
    }
}

// MARK: - Sendable Examples

struct SendablePoint: Sendable {
    let x: Double
    let y: Double
}

actor SafeCounter {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}

final class ThreadSafeCache: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: String] = [:]

    func get(_ key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func set(_ key: String, value: String) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
}

func processPoint(_ point: SendablePoint) async -> String {
    return "(\(point.x), \(point.y))"
}

// MARK: - Additional Types

struct UserData: Sendable {
    let id: UUID
    let name: String
    let email: String
}

enum LoadingState: Sendable {
    case idle
    case loading
    case loaded(UserData)
    case failed(String)
}

final class ImmutableConfig: Sendable {
    let apiKey: String
    let baseURL: URL

    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
}

#Preview {
    NavigationStack {
        SendableView()
    }
}
