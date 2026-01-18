import SwiftUI
import Combine

// MARK: - Exercise: Transforming Streams
// Learn flatMap, switchToLatest, and scheduling operators

struct TransformingStreamsView: View {
    var body: some View {
        ExerciseTabView(
            tryItView: TransformingStreamsTryItView(),
            learnView: QAListView(items: TransformingStreamsContent.qaItems),
            codeView: CodeViewer(
                title: "TransformingStreamsView.swift",
                code: TransformingStreamsContent.sourceCode,
                exercises: TransformingStreamsContent.exercises
            )
        )
        .navigationTitle("Transforming Streams")
    }
}

// MARK: - Try It Tab

private struct TransformingStreamsTryItView: View {
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
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
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
            .flatMap { $0 }
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
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.switchResults = results
            }
            .store(in: &cancellables)
    }

    private func simulateSearch(query: String, id: String) -> AnyPublisher<[String], Never> {
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
            .subscribe(on: DispatchQueue.global(qos: .background))
            .map { value -> String in
                let thread = Thread.isMainThread ? "Main" : "Background"
                return "Processed '\(value)' on \(thread)"
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                let thread = Thread.isMainThread ? "Main" : "Background"
                self?.schedulerResult = "\(result), received on \(thread)"
            }
            .store(in: &cancellables)
    }
}

#Preview {
    NavigationStack {
        TransformingStreamsView()
    }
}
