import SwiftUI

// MARK: - Exercise: Continuations - Bridging Callbacks to Async
// Convert completion handler APIs to async/await using continuations

struct ContinuationsView: View {
    @State private var result: String = ""
    @State private var isLoading = false

    var body: some View {
        List {
            Section {
                Text("Continuations let you wrap callback-based APIs (completion handlers) into async functions. Essential for bridging legacy code.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Key Concepts") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• `withCheckedContinuation` - safe, validates single resume")
                    Text("• `withCheckedThrowingContinuation` - for throwing APIs")
                    Text("• `withUnsafeContinuation` - no checks, slightly faster")
                    Text("• MUST resume exactly once - crash otherwise")
                }
                .font(.caption)
            }

            Section("The Problem: Callback Hell") {
                Text("""
                // Old completion handler pattern
                func fetchUser(completion: @escaping (User?) -> Void)
                func fetchPosts(for user: User, completion: @escaping ([Post]) -> Void)

                // Nested callbacks
                fetchUser { user in
                    guard let user = user else { return }
                    fetchPosts(for: user) { posts in
                        // More nesting...
                    }
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("The Solution: Continuations") {
                Text("""
                // Wrap with continuation
                func fetchUser() async -> User? {
                    await withCheckedContinuation { continuation in
                        fetchUser { user in
                            continuation.resume(returning: user)
                        }
                    }
                }

                // Clean linear code
                let user = await fetchUser()
                let posts = await fetchPosts(for: user)
                """)
                .font(.system(.caption2, design: .monospaced))
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
                    Text("⚠️ Resume exactly ONCE")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text("• Not resuming = task hangs forever")
                    Text("• Resuming twice = crash")
                    Text("• Use `withCheckedContinuation` to catch bugs")
                }
                .font(.caption)
            }

            Section("Error Handling Pattern") {
                Text("""
                func fetchData() async throws -> Data {
                    try await withCheckedThrowingContinuation { continuation in
                        legacyFetch { result in
                            switch result {
                            case .success(let data):
                                continuation.resume(returning: data)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }
        }
        .navigationTitle("Continuations")
    }

    func fetchWithCallback() {
        isLoading = true
        result = ""

        // Simulated legacy callback API
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

        // Using the wrapped async version
        let data = await LegacyAPI.fetchDataAsync()

        await MainActor.run {
            result = "Async result: \(data)"
            isLoading = false
        }
    }
}

// MARK: - Legacy API Simulation

enum LegacyAPI {
    // Old callback-based API
    static func fetchData(completion: @escaping (String) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            completion("Data from legacy API")
        }
    }

    // Wrapped with continuation
    static func fetchDataAsync() async -> String {
        await withCheckedContinuation { continuation in
            fetchData { data in
                continuation.resume(returning: data)
            }
        }
    }

    // Throwing version
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

// MARK: - Common Patterns

/*
 // 1. Wrapping URLSession (older iOS versions)
 extension URLSession {
     func data(from url: URL) async throws -> (Data, URLResponse) {
         try await withCheckedThrowingContinuation { continuation in
             let task = self.dataTask(with: url) { data, response, error in
                 if let error = error {
                     continuation.resume(throwing: error)
                 } else if let data = data, let response = response {
                     continuation.resume(returning: (data, response))
                 } else {
                     continuation.resume(throwing: URLError(.unknown))
                 }
             }
             task.resume()
         }
     }
 }

 // 2. Wrapping CoreLocation single request
 func requestLocation() async throws -> CLLocation {
     try await withCheckedThrowingContinuation { continuation in
         locationManager.requestLocation { location, error in
             if let error = error {
                 continuation.resume(throwing: error)
             } else if let location = location {
                 continuation.resume(returning: location)
             }
         }
     }
 }

 // 3. Wrapping Alert response
 func showAlert(title: String, message: String) async -> Bool {
     await withCheckedContinuation { continuation in
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
             continuation.resume(returning: false)
         })
         alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
             continuation.resume(returning: true)
         })
         present(alert, animated: true)
     }
 }
 */

// MARK: - Interview Tip

/*
 Key points for interviews:

 1. Use `withCheckedContinuation` during development - it validates correct usage
 2. Switch to `withUnsafeContinuation` for performance-critical code after testing
 3. Always handle ALL code paths - every branch must resume
 4. For APIs that can call completion multiple times, use AsyncStream instead
 5. Continuations are for one-shot operations; streams are for ongoing events
 */

#Preview {
    NavigationStack {
        ContinuationsView()
    }
}
