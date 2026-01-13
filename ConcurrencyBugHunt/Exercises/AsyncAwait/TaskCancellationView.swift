import SwiftUI

// MARK: - Exercise: Find the concurrency bug(s) in this code
// This view demonstrates improper task cancellation handling

struct TaskCancellationView: View {
    @State private var searchResults: [String] = []
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var currentTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            Text("Search with Debounce")
                .font(.headline)

            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchText) { _, newValue in
                    performSearch(query: newValue)
                }

            if isSearching {
                ProgressView("Searching...")
            }

            List(searchResults, id: \.self) { result in
                Text(result)
            }
            .listStyle(.plain)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Try typing quickly, then check:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("• Are old searches properly cancelled?")
                Text("• Could results appear out of order?")
                Text("• What happens if you clear the field?")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Task Cancellation")
    }

    func performSearch(query: String) {
        // Cancel any existing search
        currentTask?.cancel()

        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        currentTask = Task {
            // Simulate network delay - different queries take different times
            let delay = Double.random(in: 0.5...2.0)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            // Simulate search results
            let results = generateResults(for: query)

            // Update UI
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        }
    }

    func generateResults(for query: String) -> [String] {
        return (1...5).map { "\(query) result \($0)" }
    }
}

// Another problematic example: Long-running task without cancellation checks
class DataProcessor: ObservableObject {
    @Published var progress: Double = 0
    @Published var status: String = "Ready"
    @Published var processedItems: [String] = []

    func processLargeDataset(items: [String]) async {
        status = "Processing..."
        processedItems = []

        for (index, item) in items.enumerated() {
            // Simulate expensive processing
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            let processed = "Processed: \(item.uppercased())"
            processedItems.append(processed)

            progress = Double(index + 1) / Double(items.count)
        }

        status = "Complete!"
    }
}

struct DataProcessorView: View {
    @StateObject private var processor = DataProcessor()
    @State private var processingTask: Task<Void, Never>?

    let sampleData = (1...50).map { "Item \($0)" }

    var body: some View {
        VStack(spacing: 20) {
            Text(processor.status)
                .font(.headline)

            ProgressView(value: processor.progress)
                .progressViewStyle(.linear)

            Text("\(Int(processor.progress * 100))%")

            HStack {
                Button("Start Processing") {
                    processingTask = Task {
                        await processor.processLargeDataset(items: sampleData)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel") {
                    processingTask?.cancel()
                }
                .buttonStyle(.bordered)
            }

            List(processor.processedItems, id: \.self) { item in
                Text(item)
                    .font(.caption)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        TaskCancellationView()
    }
}
