import Foundation

/// Q&A content extracted from blog posts 87-88
struct SendableContent {

    static let qaItems: [QAItem] = [
        QAItem(
            question: "What is Sendable and why does it exist?",
            answer: """
            Sendable is a marker protocol that says "this type is safe to share across concurrency boundaries."

            When you pass data to a Task or actor, it crosses a concurrency boundary. If that data is mutable and shared, you get data races. Sendable is the compiler's way of ensuring this can't happen.

            Swift 6 enforces this strictly—what's a warning today becomes an error.
            """
        ),
        QAItem(
            question: "What types are automatically Sendable?",
            answer: """
            | Type | Sendable? |
            |------|-----------|
            | Int, Double, Bool | Yes |
            | String | Yes |
            | Array, Dictionary (of Sendable) | Yes |
            | Struct (all props Sendable) | Yes |
            | Enum (all payloads Sendable) | Yes |
            | Actor | Yes |
            | Class (mutable) | No |
            | NSObject subclasses | Usually no |

            The compiler auto-synthesizes Sendable for structs/enums with all Sendable properties.
            """
        ),
        QAItem(
            question: "How do you make a class Sendable?",
            answer: """
            Option 1: Make it immutable
            final class Config: Sendable {
                let apiKey: String  // Only let properties
                let environment: String
            }

            Option 2: Use @unchecked Sendable (you guarantee safety)
            final class ThreadSafeCache: @unchecked Sendable {
                private let lock = NSLock()
                private var storage: [String: Data] = [:]
                // All access through synchronized methods
            }
            """
        ),
        QAItem(
            question: "What are @Sendable closures?",
            answer: """
            Closures that cross concurrency boundaries must be @Sendable:

            Task { @Sendable in
                await actor.doWork()
            }

            Sendable closures can't capture mutable variables:

            var count = 0
            Task {
                count += 1  // ERROR: Mutation of captured var in Sendable closure
            }
            """
        ),
        QAItem(
            question: "When should you use @unchecked Sendable?",
            answer: """
            Use @unchecked Sendable when:
            1. Lock-based synchronization (NSLock, os_unfair_lock)
            2. Dispatch queue synchronization
            3. Wrapping non-Sendable system types (DateFormatter, etc.)

            DANGER: @unchecked disables compiler checks. If you're wrong, you get data races that crash randomly at runtime.

            Consider using an Actor instead—they provide synchronization automatically and are safer than manual locks.
            """
        ),
        QAItem(
            question: "Interview Tip: How would you explain Sendable to someone?",
            answer: """
            Sendable is foundational to Swift concurrency safety. Explain: "Data passed across actor boundaries must be Sendable, either value types or carefully designed reference types."

            For @unchecked Sendable, show you understand the trade-off: "It's an escape hatch when you need manual synchronization, but actors are usually safer. I only use @unchecked for legacy code or when wrapping thread-unsafe system types."
            """
        )
    ]

    static let exercises: [ExerciseItem] = [
        ExerciseItem(
            title: "Spot the Bug: Non-Sendable Class",
            prompt: "If you try to pass a regular mutable class to a Task, what error do you get? Try removing `Sendable` from SendablePoint and making it a class.",
            hint: "Mutable classes can't cross concurrency boundaries safely—two threads could mutate the same instance simultaneously."
        ),
        ExerciseItem(
            title: "Spot the Bug: Missing Lock",
            prompt: "In ThreadSafeCache, what happens if you remove the lock.lock()/unlock() calls but keep @unchecked Sendable?",
            hint: "The compiler trusts @unchecked Sendable. Without the lock, you get data races that may crash randomly at runtime."
        ),
        ExerciseItem(
            title: "Refactor: Replace Lock with Actor",
            prompt: "Rewrite ThreadSafeCache as an actor instead of using @unchecked Sendable. Which approach is simpler and safer?",
            hint: "Actors provide automatic synchronization. Replace `final class` with `actor` and remove the lock entirely."
        )
    ]

    static let sourceCode: String = """
    import SwiftUI
    import Combine

    struct SendableView: View {
        @StateObject private var viewModel = SendableViewModel()

        var body: some View {
            List {
                Section("Try It: Sendable Types") {
                    Button("Test Value Type") {
                        viewModel.testValueType()
                    }

                    Button("Test Actor") {
                        Task { await viewModel.testActor() }
                    }

                    ForEach(viewModel.results, id: \\.self) { result in
                        Text(result)
                            .font(.caption)
                    }
                }
            }
        }
    }

    @MainActor
    class SendableViewModel: ObservableObject {
        @Published var results: [String] = []

        func testValueType() {
            results = []

            // Value types are automatically Sendable
            let point = SendablePoint(x: 10, y: 20)

            Task {
                // Safe to pass across concurrency boundary
                let processed = await processPoint(point)
                results.append("Processed: \\(processed)")
            }
        }

        func testActor() async {
            results = []

            // Actors are always Sendable
            let counter = SafeCounter()
            await counter.increment()
            await counter.increment()
            let value = await counter.count
            results.append("Counter: \\(value)")
        }
    }

    // MARK: - Sendable Examples

    // Automatically Sendable (struct with Sendable properties)
    struct SendablePoint: Sendable {
        let x: Double
        let y: Double
    }

    // Actor is always Sendable
    actor SafeCounter {
        private(set) var count = 0

        func increment() {
            count += 1
        }
    }

    // Manual Sendable with synchronization
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
        return "(\\(point.x), \\(point.y))"
    }
    """
}
