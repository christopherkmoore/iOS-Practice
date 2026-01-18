import Foundation

/// Q&A content extracted from blog posts 85-86
struct TransformingStreamsContent {

    static let qaItems: [QAItem] = [
        QAItem(
            question: "What's the difference between flatMap and switchToLatest?",
            answer: """
            Both handle "publisher of publishers"—but very differently.

            flatMap: Keeps ALL inner publishers alive
            switchToLatest: Cancels previous when new arrives

            For search:
            • flatMap: Results arrive out of order (race condition!)
            • switchToLatest: Only latest search results shown
            """
        ),
        QAItem(
            question: "When should you use switchToLatest?",
            answer: """
            Use switchToLatest for user input, search, typeahead—anywhere you only care about the LATEST request.

            $searchText
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                .map { query in api.search(query) }
                .switchToLatest()
                .sink { results in
                    self.results = results  // Always matches current search text
                }

            Old requests are cancelled, preventing race conditions.
            """
        ),
        QAItem(
            question: "When should you use flatMap?",
            answer: """
            Use flatMap when you want ALL results, or with maxPublishers to limit concurrency:

            userIdsPublisher
                .flatMap(maxPublishers: .max(3)) { userId in
                    api.fetchUser(userId)  // Max 3 concurrent requests
                }
                .collect()
                .sink { allUsers in
                    // All users fetched, max 3 at a time
                }
            """
        ),
        QAItem(
            question: "What do receive(on:) and subscribe(on:) do?",
            answer: """
            .subscribe(on:)   // Where work STARTS
            .receive(on:)     // Where values are DELIVERED

            Most common pattern:
            api.fetchUsers()
                .receive(on: DispatchQueue.main)
                .sink { users in
                    self.users = users  // Safe: on main thread
                }

            Everything AFTER receive(on:) runs on that scheduler.
            """
        ),
        QAItem(
            question: "Why does scheduler order matter?",
            answer: """
            // Processing on background, delivery on main
            publisher
                .subscribe(on: DispatchQueue.global())  // Upstream work
                .map { heavyTransform($0) }              // Runs on global queue
                .receive(on: DispatchQueue.main)         // Switch to main
                .sink { /* On main thread */ }

            vs

            publisher
                .receive(on: DispatchQueue.main)         // Switch early
                .map { heavyTransform($0) }              // Runs on main (bad!)
                .sink { /* On main thread */ }
            """
        ),
        QAItem(
            question: "What's the difference between RunLoop.main and DispatchQueue.main?",
            answer: """
            Both target the main thread, but behave differently:

            // DispatchQueue.main - always async dispatch
            .receive(on: DispatchQueue.main)

            // RunLoop.main - integrates with run loop
            .receive(on: RunLoop.main)

            RunLoop.main is often better for UI because it integrates with the app's event loop. DispatchQueue.main is more predictable.
            """
        ),
        QAItem(
            question: "Interview Tip: How do you handle search with Combine?",
            answer: """
            The answer involves debounce + switchToLatest:

            $searchText
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                .removeDuplicates()
                .map { query in api.search(query) }
                .switchToLatest()
                .receive(on: DispatchQueue.main)
                .sink { self.results = $0 }

            Explain WHY switchToLatest—cancelling stale requests prevents race conditions.

            Also mention: "I always use receive(on: DispatchQueue.main) before updating @Published properties to avoid main thread violations."
            """
        )
    ]

    static let exercises: [ExerciseItem] = [
        ExerciseItem(
            title: "Spot the Bug: Race Condition",
            prompt: "If you replaced switchToLatest() with flatMap { $0 }, what would happen when a user types 'swift' then 'swiftui' quickly?",
            hint: "With flatMap, both searches run in parallel. The 'swift' results might arrive AFTER 'swiftui' results, showing stale data."
        ),
        ExerciseItem(
            title: "Spot the Bug: Main Thread Violation",
            prompt: "What happens if you remove receive(on: DispatchQueue.main)? Where does the sink closure run?",
            hint: "Network responses arrive on background threads. Updating @Published without receive(on:) causes main thread violations."
        ),
        ExerciseItem(
            title: "Optimize: Add Caching",
            prompt: "The current implementation makes a new request for every search. How would you add caching to avoid duplicate requests?",
            hint: "Use a dictionary cache. In the map closure, check if the query is cached before making a new request."
        )
    ]

    static let sourceCode: String = """
    import SwiftUI
    import Combine

    struct TransformingStreamsView: View {
        @StateObject private var viewModel = SearchViewModel()

        var body: some View {
            List {
                Section("Try It: Search") {
                    TextField("Search...", text: $viewModel.searchText)

                    if viewModel.isSearching {
                        ProgressView()
                    }

                    ForEach(viewModel.results, id: \\.self) { result in
                        Text(result)
                            .font(.caption)
                    }
                }
            }
        }
    }

    class SearchViewModel: ObservableObject {
        @Published var searchText = ""
        @Published var results: [String] = []
        @Published var isSearching = false

        private var cancellables = Set<AnyCancellable>()

        init() {
            $searchText
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                .removeDuplicates()
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.isSearching = true
                })
                .map { [weak self] query -> AnyPublisher<[String], Never> in
                    guard !query.isEmpty else {
                        return Just([]).eraseToAnyPublisher()
                    }
                    return self?.simulateSearch(query: query) ?? Just([]).eraseToAnyPublisher()
                }
                .switchToLatest()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] results in
                    self?.results = results
                    self?.isSearching = false
                }
                .store(in: &cancellables)
        }

        private func simulateSearch(query: String) -> AnyPublisher<[String], Never> {
            Just(["\\(query) result 1", "\\(query) result 2", "\\(query) result 3"])
                .delay(for: .seconds(0.5), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
    """
}
