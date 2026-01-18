import SwiftUI

// MARK: - Exercise: Continuations - Bridging Callbacks to Async
// Convert completion handler APIs to async/await using continuations

struct ContinuationsView: View {
    var body: some View {
        ExerciseTabView(
            tryItView: ContinuationsTryItView(),
            learnView: QAListView(items: ContinuationsContent.qaItems),
            codeView: CodeViewer(
                title: "ContinuationsView.swift",
                code: ContinuationsContent.sourceCode,
                exercises: ContinuationsContent.exercises
            )
        )
        .navigationTitle("Continuations")
    }
}

// MARK: - Try It Tab

private struct ContinuationsTryItView: View {
    @State private var result: String = ""
    @State private var isLoading = false

    var body: some View {
        List {
            Section {
                Text("Continuations let you wrap callback-based APIs (completion handlers) into async functions. Essential for bridging legacy code.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Try It") {
                VStack(spacing: 16) {
                    HStack {
                        Button("Fetch with Callback") {
                            fetchWithCallback()
                        }
                        .buttonStyle(.bordered)

                        Button("Fetch with Async") {
                            Task { await fetchWithAsync() }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if isLoading {
                        ProgressView()
                    }

                    if !result.isEmpty {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Section("Critical Rule") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resume exactly ONCE")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text("• Not resuming = task hangs forever")
                    Text("• Resuming twice = crash")
                    Text("• Use `withCheckedContinuation` to catch bugs")
                }
                .font(.caption)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
    }

    func fetchWithCallback() {
        isLoading = true
        result = ""

        LegacyAPI.fetchData { data in
            DispatchQueue.main.async {
                result = "Callback result: \(data)"
                isLoading = false
            }
        }
    }

    func fetchWithAsync() async {
        await MainActor.run {
            isLoading = true
            result = ""
        }

        let data = await LegacyAPI.fetchDataAsync()

        await MainActor.run {
            result = "Async result: \(data)"
            isLoading = false
        }
    }
}

// MARK: - Legacy API Simulation

enum LegacyAPI {
    static func fetchData(completion: @escaping (String) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            completion("Data from legacy API")
        }
    }

    static func fetchDataAsync() async -> String {
        await withCheckedContinuation { continuation in
            fetchData { data in
                continuation.resume(returning: data)
            }
        }
    }

    static func fetchDataWithError(shouldFail: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            if shouldFail {
                completion(.failure(NSError(domain: "API", code: 500)))
            } else {
                completion(.success("Success data"))
            }
        }
    }

    static func fetchDataWithErrorAsync(shouldFail: Bool) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            fetchDataWithError(shouldFail: shouldFail) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContinuationsView()
    }
}
