import Foundation

/// Q&A content extracted from blog posts 89-91
struct MainActorPatternsContent {

    static let qaItems: [QAItem] = [
        QAItem(
            question: "Why do ViewModels need @MainActor?",
            answer: """
            ViewModels update @Published properties that drive UI. Those updates MUST happen on the main thread:

            // Without @MainActor - potential crash
            class UserViewModel: ObservableObject {
                @Published var user: User?

                func load() async {
                    let user = await api.fetchUser()  // Background thread
                    self.user = user  // Main thread violation!
                }
            }

            Marking the class with @MainActor guarantees all methods and properties run on main thread by default.
            """
        ),
        QAItem(
            question: "How do you use @MainActor on a class?",
            answer: """
            @MainActor
            class UserViewModel: ObservableObject {
                @Published var user: User?
                @Published var isLoading = false

                func load() async {
                    isLoading = true
                    let user = await api.fetchUser()
                    self.user = user  // Guaranteed main thread
                    isLoading = false
                }
            }

            Now ALL methods and properties run on the main thread by default.
            """
        ),
        QAItem(
            question: "What is nonisolated and when do you use it?",
            answer: """
            nonisolated lets specific methods escape the main thread in a @MainActor class:

            @MainActor
            class DataProcessor: ObservableObject {
                @Published var result: Data?

                // This runs on main thread - blocks UI!
                func process(_ input: Data) -> Data {
                    return heavyComputation(input)
                }

                // Free from main actor - can run anywhere
                nonisolated func processAsync(_ input: Data) -> Data {
                    return heavyComputation(input)
                }
            }

            Use nonisolated for heavy computation that doesn't touch actor state.
            """
        ),
        QAItem(
            question: "What are the rules for nonisolated methods?",
            answer: """
            nonisolated methods CANNOT access mutable actor state:

            @MainActor
            class Counter: ObservableObject {
                @Published var count = 0

                nonisolated func getCount() -> Int {
                    count  // ERROR: can't access actor state
                }

                nonisolated func compute(_ value: Int) -> Int {
                    value * 2  // OK: doesn't touch state
                }
            }

            nonisolated is for pure computations that don't need actor isolation.
            """
        ),
        QAItem(
            question: "How do you prepare for Swift 6 strict concurrency?",
            answer: """
            Swift 6 treats data race warnings as ERRORS.

            Enable strict checking now in Xcode Build Settings:
            • Set "Strict Concurrency Checking" to "Complete"

            Common fixes:
            1. Add Sendable to simple value types
            2. Mark ViewModels with @MainActor
            3. Use let instead of var where possible
            4. Convert mutable classes to actors
            """
        ),
        QAItem(
            question: "What are common Swift 6 migration issues?",
            answer: """
            1. Captured mutable variables:
            var results: [String] = []
            Task { results.append(item) }  // ERROR

            2. Non-Sendable types crossing boundaries:
            class Manager { var data = [] }
            Task { manager.data = newData }  // ERROR

            3. Closures capturing self:
            Task { self.data = await fetch() }  // ERROR if self not Sendable

            Fix by using @MainActor, actors, or making types Sendable.
            """
        ),
        QAItem(
            question: "Interview Tip: How would you discuss @MainActor in an interview?",
            answer: """
            When discussing ViewModels: "I mark my ViewModels with @MainActor to guarantee all @Published updates happen on the main thread. This eliminates an entire class of threading bugs and is cleaner than manual MainActor.run calls."

            For nonisolated: "I use nonisolated to move heavy computation off the main thread while keeping state updates on main actor. The key is understanding what accesses actor state and what's a pure computation."

            For Swift 6: "I've been preparing by enabling strict concurrency checking. It's better to fix warnings now than face errors later."
            """
        )
    ]

    static let exercises: [ExerciseItem] = [
        ExerciseItem(
            title: "Spot the Bug: Main Thread Blocking",
            prompt: "What if heavyComputation wasn't marked nonisolated? How would that affect the UI while processing?",
            hint: "Without nonisolated, the heavy computation runs on MainActor, blocking UI updates and making the app feel frozen."
        ),
        ExerciseItem(
            title: "Spot the Bug: try? Swallows Errors",
            prompt: "In loadData(), `try? await Task.sleep` swallows all errors. What if the task is cancelled while sleeping?",
            hint: "Task.sleep throws CancellationError when cancelled. Using try? means cancellation is ignored and loading continues."
        ),
        ExerciseItem(
            title: "Refactor: Remove Task.detached",
            prompt: "Instead of Task.detached for heavy work, use a nonisolated async function. Which pattern is cleaner?",
            hint: "Create `nonisolated func computeAsync(_ input: Int) async -> Int` and call it directly. No need for Task.detached."
        )
    ]

    static let sourceCode: String = """
    import SwiftUI
    import Combine

    struct MainActorPatternsView: View {
        @StateObject private var viewModel = MainActorViewModel()

        var body: some View {
            List {
                Section("Try It: @MainActor ViewModel") {
                    Button("Load Data") {
                        Task { await viewModel.loadData() }
                    }
                    .disabled(viewModel.isLoading)

                    if viewModel.isLoading {
                        ProgressView()
                    }

                    ForEach(viewModel.items, id: \\.self) { item in
                        Text(item)
                            .font(.caption)
                    }
                }

                Section("Try It: Background Processing") {
                    Button("Process Heavy Task") {
                        Task { await viewModel.processHeavyTask() }
                    }
                    .disabled(viewModel.isProcessing)

                    if viewModel.isProcessing {
                        ProgressView("Processing...")
                    }

                    if let result = viewModel.processedResult {
                        Text("Result: \\(result)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    @MainActor
    class MainActorViewModel: ObservableObject {
        @Published var items: [String] = []
        @Published var isLoading = false
        @Published var isProcessing = false
        @Published var processedResult: String?

        func loadData() async {
            isLoading = true
            items = []

            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
            isLoading = false
        }

        // Heavy work should be nonisolated
        nonisolated func heavyComputation(_ input: Int) -> Int {
            // Simulate CPU-intensive work
            var result = input
            for i in 1...1000 {
                result = result &+ i
            }
            return result
        }

        func processHeavyTask() async {
            isProcessing = true
            processedResult = nil

            // Run heavy work off main thread
            let result = await Task.detached(priority: .userInitiated) {
                self.heavyComputation(42)
            }.value

            // Back on main actor for UI update
            processedResult = "Computed: \\(result)"
            isProcessing = false
        }
    }
    """
}
