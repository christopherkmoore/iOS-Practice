import SwiftUI
import Combine

// MARK: - Exercise: Transforming Streams
// Learn flatMap, switchToLatest, and scheduling operators

struct TransformingStreamsView: View {
    @StateObject private var viewModel = TransformingStreamsViewModel()

    var body: some View {
        List {
            Section {
                Text("Transform operators change how values flow through your publisher chain. Critical for async operations and UI updates.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("flatMap") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transforms each value into a NEW publisher, flattens results")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Search users...", text: $viewModel.flatMapQuery)
                        .textFieldStyle(.roundedBorder)

                    Text("Results (flatMap - may have race conditions):")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    ForEach(viewModel.flatMapResults, id: \.self) { result in
                        Text(result)
                            .font(.caption)
                    }
                }
            }

            Section("switchToLatest") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cancels previous inner publisher when new one arrives - perfect for search!")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Search users...", text: $viewModel.switchQuery)
                        .textFieldStyle(.roundedBorder)

                    Text("Results (switchToLatest - cancels old requests):")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    ForEach(viewModel.switchResults, id: \.self) { result in
                        Text(result)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Section("flatMap vs switchToLatest") {
                Text("""
                flatMap:
                • Keeps ALL inner publishers alive
                • Results may arrive out of order
                • Use for: parallel operations where you want all results

                switchToLatest:
                • Cancels previous when new arrives
                • Only latest request completes
                • Use for: search, typeahead, user input
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("Schedulers: receive(on:)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Controls which thread/queue receives values")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Fetch on Background, Receive on Main") {
                        viewModel.demonstrateSchedulers()
                    }
                    .buttonStyle(.bordered)

                    Text(viewModel.schedulerResult)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Section("Code Patterns") {
                Text("""
                // Search with switchToLatest (CORRECT)
                $searchText
                    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                    .map { query in
                        api.search(query)  // Returns Publisher
                    }
                    .switchToLatest()  // Cancel old, use new
                    .receive(on: DispatchQueue.main)
                    .sink { results in ... }

                // Parallel fetches with flatMap
                userIdsPublisher
                    .flatMap(maxPublishers: .max(3)) { userId in
                        api.fetchUser(userId)  // Run up to 3 at once
                    }
                    .collect()  // Wait for all
                    .sink { allUsers in ... }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("subscribe(on:) vs receive(on:)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("subscribe(on:)").fontWeight(.bold) + Text(" - Where work STARTS")
                    Text("receive(on:)").fontWeight(.bold) + Text(" - Where values are DELIVERED")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Transforming Streams")
    }
}

// MARK: - ViewModel

class TransformingStreamsViewModel: ObservableObject {
    @Published var flatMapQuery = ""
    @Published var flatMapResults: [String] = []

    @Published var switchQuery = ""
    @Published var switchResults: [String] = []

    @Published var schedulerResult = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupFlatMapDemo()
        setupSwitchToLatestDemo()
    }

    private func setupFlatMapDemo() {
        $flatMapQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .filter { !$0.isEmpty }
            .map { [weak self] query -> AnyPublisher<[String], Never> in
                self?.simulateSearch(query: query, id: "flatMap") ?? Empty().eraseToAnyPublisher()
            }
            .flatMap { $0 }  // Keeps all publishers alive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.flatMapResults = results
            }
            .store(in: &cancellables)
    }

    private func setupSwitchToLatestDemo() {
        $switchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .filter { !$0.isEmpty }
            .map { [weak self] query -> AnyPublisher<[String], Never> in
                self?.simulateSearch(query: query, id: "switch") ?? Empty().eraseToAnyPublisher()
            }
            .switchToLatest()  // Cancels previous, uses latest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.switchResults = results
            }
            .store(in: &cancellables)
    }

    private func simulateSearch(query: String, id: String) -> AnyPublisher<[String], Never> {
        // Simulate network delay (random to show race condition with flatMap)
        let delay = Double.random(in: 0.5...2.0)

        return Future<[String], Never> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                let results = (1...3).map { "\(query) result \($0) [\(id)]" }
                promise(.success(results))
            }
        }
        .eraseToAnyPublisher()
    }

    func demonstrateSchedulers() {
        schedulerResult = "Starting..."

        Just("data")
            .subscribe(on: DispatchQueue.global(qos: .background))  // Work starts here
            .map { value -> String in
                // This runs on background queue
                let thread = Thread.isMainThread ? "Main" : "Background"
                return "Processed '\(value)' on \(thread)"
            }
            .receive(on: DispatchQueue.main)  // Deliver here
            .sink { [weak self] result in
                // This runs on main queue
                let thread = Thread.isMainThread ? "Main" : "Background"
                self?.schedulerResult = "\(result), received on \(thread)"
            }
            .store(in: &cancellables)
    }
}

// MARK: - Other Transform Operators

/*
 // Map variants
 .map { $0.property }           // Transform value
 .compactMap { $0 }             // Remove nils
 .tryMap { try process($0) }    // Can throw

 // Filter variants
 .filter { $0 > 10 }            // Only pass matching
 .removeDuplicates()            // Skip consecutive dupes
 .first()                       // Only first value

 // Timing
 .debounce(for: .seconds(0.3), scheduler: RunLoop.main)  // Wait for pause
 .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)  // Rate limit

 // Error handling
 .replaceError(with: defaultValue)
 .catch { error in fallbackPublisher }
 .retry(3)  // Retry up to 3 times

 // Collect
 .collect()              // All values into array
 .collect(5)             // Batches of 5
 .first(where: { $0 > 10 })  // First matching
 */

#Preview {
    NavigationStack {
        TransformingStreamsView()
    }
}
