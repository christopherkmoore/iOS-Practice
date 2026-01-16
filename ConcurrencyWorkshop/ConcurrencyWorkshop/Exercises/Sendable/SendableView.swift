import SwiftUI
import Combine

// MARK: - Exercise: Sendable Protocol
// Ensure thread-safe data transfer across actor boundaries

struct SendableView: View {
    @State private var showDemo = false

    var body: some View {
        List {
            Section {
                Text("Sendable is a marker protocol that indicates a type is safe to share across concurrency domains (threads, actors). Swift 6 enforces this strictly.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

            Section("Automatic Sendable Conformance") {
                Text("""
                // ✅ Automatically Sendable
                struct Point: Sendable {
                    let x: Double
                    let y: Double
                }

                // ✅ Enums with Sendable associated values
                enum Result: Sendable {
                    case success(String)
                    case failure(Error)  // ⚠️ Error isn't Sendable!
                }

                // ✅ Actors are always Sendable
                actor Counter {
                    var count = 0
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("Non-Sendable Types") {
                Text("""
                // ❌ Classes are NOT Sendable by default
                class UserSettings {
                    var theme: String = "light"  // Mutable = unsafe
                }

                // ❌ Closures that capture mutable state
                var count = 0
                let closure = { count += 1 }  // Not @Sendable
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("Making Classes Sendable") {
                Text("""
                // Option 1: final + immutable
                final class ImmutableUser: Sendable {
                    let id: Int
                    let name: String

                    init(id: Int, name: String) {
                        self.id = id
                        self.name = name
                    }
                }

                // Option 2: @unchecked Sendable (YOU handle safety)
                final class ThreadSafeCache: @unchecked Sendable {
                    private let lock = NSLock()
                    private var storage: [String: Any] = [:]

                    func get(_ key: String) -> Any? {
                        lock.lock()
                        defer { lock.unlock() }
                        return storage[key]
                    }
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("@Sendable Closures") {
                Text("""
                // Task closures must be @Sendable
                Task { @Sendable in
                    // This closure crosses concurrency boundaries
                    await someActor.doWork()
                }

                // Function parameters
                func process(action: @Sendable () async -> Void) async {
                    await action()
                }

                // Common error: capturing non-Sendable type
                class ViewModel: ObservableObject {
                    func fetch() {
                        Task {
                            // ⚠️ 'self' is not Sendable
                            await loadData()
                        }
                    }
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("Fixing Common Issues") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Problem: Passing class to actor").fontWeight(.bold)
                        Text("Fix: Make class final with only let properties, or use struct")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Problem: Closure captures mutable variable").fontWeight(.bold)
                        Text("Fix: Capture a copy, use let, or mark @Sendable with care")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Problem: ObservableObject in Task").fontWeight(.bold)
                        Text("Fix: Use @MainActor on the class")
                    }
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
        .navigationTitle("Sendable Protocol")
    }
}

// MARK: - Examples

// ✅ Automatically Sendable (all stored properties are Sendable)
struct UserData: Sendable {
    let id: UUID
    let name: String
    let email: String
}

// ✅ Enum with Sendable payloads
enum LoadingState: Sendable {
    case idle
    case loading
    case loaded(UserData)
    case failed(String)  // String is Sendable
}

// ✅ Final class with only immutable properties
final class ImmutableConfig: Sendable {
    let apiKey: String
    let baseURL: URL

    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
}

// ⚠️ @unchecked Sendable - YOU guarantee thread safety
final class AtomicCounter: @unchecked Sendable {
    private var _value: Int = 0
    private let lock = NSLock()

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        _value += 1
    }
}

// MARK: - Actor Example

actor DataStore {
    private var cache: [String: UserData] = [:]

    // ✅ UserData is Sendable, can cross actor boundary
    func store(_ user: UserData) {
        cache[user.id.uuidString] = user
    }

    func fetch(id: String) -> UserData? {
        cache[id]
    }
}

// MARK: - @MainActor Pattern for ViewModels

@MainActor
class SendableViewModel: ObservableObject {
    @Published var users: [UserData] = []

    func loadUsers() {
        Task {
            // Safe because class is @MainActor isolated
            let fetched = await fetchFromAPI()
            users = fetched
        }
    }

    private func fetchFromAPI() async -> [UserData] {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return [
            UserData(id: UUID(), name: "Alice", email: "alice@example.com"),
            UserData(id: UUID(), name: "Bob", email: "bob@example.com")
        ]
    }
}

// MARK: - Interview Tips

/*
 Key points for interviews:

 1. Sendable = "safe to share across threads/actors"
 2. Value types with Sendable properties are automatically Sendable
 3. Classes need: final + only let properties, OR @unchecked Sendable
 4. Actors are always Sendable (they provide isolation)
 5. @unchecked Sendable shifts responsibility to YOU
 6. Swift 6 makes violations errors, not warnings
 7. @MainActor is the common fix for ObservableObject issues
 */

#Preview {
    NavigationStack {
        SendableView()
    }
}
