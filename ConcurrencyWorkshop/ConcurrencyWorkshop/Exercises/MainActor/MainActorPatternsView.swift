import SwiftUI
import Combine

// MARK: - Exercise: MainActor Patterns
// Proper UI thread management with @MainActor and isolation

struct MainActorPatternsView: View {
    @StateObject private var viewModel = MainActorViewModel()

    var body: some View {
        List {
            Section {
                Text("@MainActor ensures code runs on the main thread. Essential for UI updates and working with UIKit/AppKit.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("What is MainActor?") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• A global actor representing the main thread")
                    Text("• All UI code must run here (UIKit/SwiftUI requirement)")
                    Text("• Prevents 'UI updated from background thread' crashes")
                    Text("• SwiftUI views are implicitly @MainActor")
                }
                .font(.caption)
            }

            Section("@MainActor on Classes") {
                Text("""
                // Entire class runs on main thread
                @MainActor
                class ViewModel: ObservableObject {
                    @Published var items: [Item] = []

                    func load() {
                        Task {
                            // Still on MainActor!
                            let data = await fetchData()
                            items = data  // ✅ Safe UI update
                        }
                    }
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("@MainActor on Functions") {
                Text("""
                // Only this function runs on main thread
                class DataService {
                    func fetchData() async -> [Item] {
                        // Runs on any thread
                        return await api.fetch()
                    }

                    @MainActor
                    func updateUI(with items: [Item]) {
                        // Guaranteed main thread
                        self.displayedItems = items
                    }
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("MainActor.run") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hop to main thread from anywhere:")
                        .font(.caption)

                    Text("""
                // From background task
                func processInBackground() async {
                    let result = await heavyComputation()

                    await MainActor.run {
                        self.result = result  // UI update
                    }
                }
                """)
                    .font(.system(.caption2, design: .monospaced))

                    Button("Demo: Background → MainActor") {
                        viewModel.demonstrateMainActorRun()
                    }
                    .buttonStyle(.bordered)

                    Text(viewModel.demoResult)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Section("nonisolated") {
                Text("""
                @MainActor
                class ViewModel: ObservableObject {
                    @Published var count = 0

                    // Opt OUT of MainActor for this method
                    nonisolated func computeHash(for data: Data) -> String {
                        // Can run on any thread
                        // Cannot access @Published properties!
                        return data.base64EncodedString()
                    }

                    // Computed property can also be nonisolated
                    nonisolated var appVersion: String {
                        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0"
                    }
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("Try It: Isolation Demo") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Fetch on Background, Update on Main") {
                        viewModel.fetchAndUpdate()
                    }
                    .buttonStyle(.borderedProminent)

                    if viewModel.isLoading {
                        ProgressView()
                    }

                    ForEach(viewModel.items, id: \.self) { item in
                        Text(item)
                            .font(.caption)
                    }
                }
            }

            Section("Common Patterns") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pattern 1: @MainActor ViewModel").fontWeight(.bold)
                        Text("Put @MainActor on the whole class. Most common for SwiftUI.")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pattern 2: MainActor.run for updates").fontWeight(.bold)
                        Text("Keep data processing off main, hop for UI updates.")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pattern 3: nonisolated for pure functions").fontWeight(.bold)
                        Text("Opt out for methods that don't need UI.")
                    }
                }
                .font(.caption)
            }

            Section("assumeIsolated (Advanced)") {
                Text("""
                // When you KNOW you're on MainActor but compiler doesn't
                // Use sparingly! Crashes if wrong.
                MainActor.assumeIsolated {
                    // You promise this is main thread
                    updateUI()
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }
        }
        .navigationTitle("MainActor Patterns")
    }
}

// MARK: - ViewModel

@MainActor
class MainActorViewModel: ObservableObject {
    @Published var items: [String] = []
    @Published var isLoading = false
    @Published var demoResult = ""

    func fetchAndUpdate() {
        isLoading = true
        items = []

        Task {
            // This is still on MainActor because the class is @MainActor
            // But the await lets other work happen

            let fetched = await fetchFromBackgroundService()

            // Back on MainActor after await
            items = fetched
            isLoading = false
        }
    }

    // This runs on MainActor, but the inner work doesn't have to
    private func fetchFromBackgroundService() async -> [String] {
        // Simulate network fetch
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        return ["Item 1 (fetched)", "Item 2 (fetched)", "Item 3 (fetched)"]
    }

    func demonstrateMainActorRun() {
        demoResult = "Starting on main..."

        Task.detached {
            // This is NOT on MainActor (detached task)
            let thread = Thread.isMainThread ? "Main" : "Background"
            let computed = "Computed on \(thread)"

            // Hop to MainActor for UI update
            await MainActor.run {
                self.demoResult = "\(computed) → Updated on Main: \(Thread.isMainThread)"
            }
        }
    }

    // Opt out of MainActor for pure computation
    nonisolated func pureComputation(value: Int) -> Int {
        // Cannot access @Published properties here!
        return value * 2
    }
}

// MARK: - Comparison: Different Approaches

/*
 // Approach 1: @MainActor class (Recommended for ViewModels)
 @MainActor
 class ViewModel: ObservableObject {
     @Published var data: [Item] = []

     func load() {
         Task {
             data = await api.fetch()  // ✅ Safe
         }
     }
 }

 // Approach 2: MainActor.run (Good for services)
 class DataService {
     func fetchAndNotify() async {
         let data = await api.fetch()

         await MainActor.run {
             NotificationCenter.default.post(...)  // ✅ Safe
         }
     }
 }

 // Approach 3: @MainActor on specific methods
 class MixedService {
     func backgroundWork() async -> Data {
         // Runs anywhere
     }

     @MainActor
     func updateUI(with data: Data) {
         // Guaranteed main thread
     }
 }
 */

// MARK: - Global Actors (Advanced)

/*
 // You can define your own global actors
 @globalActor
 actor DatabaseActor {
     static let shared = DatabaseActor()
 }

 // Use it like @MainActor
 @DatabaseActor
 class DatabaseService {
     func save(_ item: Item) {
         // Runs on DatabaseActor's executor
     }
 }
 */

// MARK: - Interview Tips

/*
 Key points for interviews:

 1. @MainActor guarantees code runs on main thread
 2. SwiftUI views are implicitly @MainActor
 3. Use @MainActor on ViewModels that update @Published properties
 4. MainActor.run {} is for hopping TO main from elsewhere
 5. nonisolated opts OUT of actor isolation for specific members
 6. Task {} inherits actor context, Task.detached {} does not
 7. Awaiting doesn't change your actor - you return to same context
 */

#Preview {
    NavigationStack {
        MainActorPatternsView()
    }
}
