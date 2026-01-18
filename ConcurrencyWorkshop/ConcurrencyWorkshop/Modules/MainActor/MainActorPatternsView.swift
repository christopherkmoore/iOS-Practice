import SwiftUI
import Combine

// MARK: - Exercise: MainActor Patterns
// Proper UI thread management with @MainActor and isolation

struct MainActorPatternsView: View {
    var body: some View {
        ExerciseTabView(
            tryItView: MainActorPatternsTryItView(),
            learnView: QAListView(items: MainActorPatternsContent.qaItems),
            codeView: CodeViewer(
                title: "MainActorPatternsView.swift",
                code: MainActorPatternsContent.sourceCode,
                exercises: MainActorPatternsContent.exercises
            )
        )
        .navigationTitle("MainActor Patterns")
    }
}

// MARK: - Try It Tab

private struct MainActorPatternsTryItView: View {
    @StateObject private var viewModel = MainActorViewModel()

    var body: some View {
        List {
            Section {
                Text("@MainActor ensures code runs on the main thread. Essential for UI updates and working with UIKit/AppKit.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Try It: @MainActor ViewModel") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Load Data") {
                        Task { await viewModel.loadData() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)

                    if viewModel.isLoading {
                        ProgressView()
                    }

                    ForEach(viewModel.items, id: \.self) { item in
                        Text(item)
                            .font(.caption)
                    }
                }
            }

            Section("Try It: Background Processing") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Process Heavy Task") {
                        Task { await viewModel.processHeavyTask() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isProcessing)

                    if viewModel.isProcessing {
                        ProgressView("Processing...")
                    }

                    if let result = viewModel.processedResult {
                        Text("Result: \(result)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Section("MainActor.run Demo") {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Background → MainActor") {
                        viewModel.demonstrateMainActorRun()
                    }
                    .buttonStyle(.bordered)

                    Text(viewModel.demoResult)
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

@MainActor
class MainActorViewModel: ObservableObject {
    @Published var items: [String] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var processedResult: String?
    @Published var demoResult = ""

    func loadData() async {
        isLoading = true
        items = []

        try? await Task.sleep(nanoseconds: 1_500_000_000)

        items = ["Item 1 (fetched)", "Item 2 (fetched)", "Item 3 (fetched)"]
        isLoading = false
    }

    nonisolated func heavyComputation(_ input: Int) -> Int {
        var result = input
        for i in 1...1000 {
            result = result &+ i
        }
        return result
    }

    func processHeavyTask() async {
        isProcessing = true
        processedResult = nil

        let result = await Task.detached(priority: .userInitiated) {
            self.heavyComputation(42)
        }.value

        processedResult = "Computed: \(result)"
        isProcessing = false
    }

    func demonstrateMainActorRun() {
        demoResult = "Starting on main..."

        Task.detached {
            let thread = Thread.isMainThread ? "Main" : "Background"
            let computed = "Computed on \(thread)"

            await MainActor.run {
                self.demoResult = "\(computed) → Updated on Main: \(Thread.isMainThread)"
            }
        }
    }

    nonisolated func pureComputation(value: Int) -> Int {
        return value * 2
    }
}

#Preview {
    NavigationStack {
        MainActorPatternsView()
    }
}
