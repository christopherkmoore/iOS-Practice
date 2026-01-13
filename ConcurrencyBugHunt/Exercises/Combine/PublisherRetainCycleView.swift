import SwiftUI
import Combine

// MARK: - Exercise: Find the concurrency bug(s) in this code
// This demonstrates retain cycles with Combine publishers

class UserSessionManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var sessionToken: String?
    @Published var lastActivity: Date?

    private var cancellables = Set<AnyCancellable>()
    private var activityTimer: AnyCancellable?

    init() {
        setupSessionMonitoring()
    }

    private func setupSessionMonitoring() {
        // Monitor login state changes
        $isLoggedIn
            .sink { isLoggedIn in
                if isLoggedIn {
                    self.startActivityTracking()
                } else {
                    self.stopActivityTracking()
                }
            }
            .store(in: &cancellables)

        // Monitor token changes
        $sessionToken
            .compactMap { $0 }
            .sink { token in
                self.validateToken(token)
            }
            .store(in: &cancellables)
    }

    private func startActivityTracking() {
        activityTimer = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [self] date in
                self.lastActivity = date
                self.checkSessionTimeout()
            }
    }

    private func stopActivityTracking() {
        activityTimer?.cancel()
        activityTimer = nil
    }

    private func validateToken(_ token: String) {
        // Simulate token validation
        print("Validating token: \(token)")
    }

    private func checkSessionTimeout() {
        // Simulate timeout check
        print("Checking session timeout...")
    }

    func login(token: String) {
        sessionToken = token
        isLoggedIn = true
    }

    func logout() {
        isLoggedIn = false
        sessionToken = nil
    }

    deinit {
        print("UserSessionManager deallocated")
    }
}

// Another example with network request retain cycle
class SearchService: ObservableObject {
    @Published var searchText = ""
    @Published var results: [String] = []
    @Published var isSearching = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSearch()
    }

    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { query in
                self.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) {
        isSearching = true

        // Simulate async search
        Just(generateResults(for: query))
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .sink { results in
                self.results = results
                self.isSearching = false
            }
            .store(in: &cancellables)
    }

    private func generateResults(for query: String) -> [String] {
        return (1...5).map { "\(query) - Result \($0)" }
    }

    deinit {
        print("SearchService deallocated")
    }
}

struct PublisherRetainCycleView: View {
    @State private var showSessionDemo = false
    @State private var showSearchDemo = false
    @State private var deinitMessages: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Combine Retain Cycles")
                    .font(.headline)

                Text("These examples create retain cycles.\nWatch the console for deinit messages (or lack thereof).")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                GroupBox("Session Manager Demo") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Issues to find:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("• Strong self capture in sink closures")
                        Text("• Timer retains self")
                        Text("• Object never deallocates")

                        Button("Open Session Demo") {
                            showSessionDemo = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                GroupBox("Search Service Demo") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Issues to find:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("• Closure captures self strongly")
                        Text("• Each search creates new subscription")

                        Button("Open Search Demo") {
                            showSearchDemo = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                GroupBox("How to Test") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Open a demo sheet")
                        Text("2. Interact with it (login/search)")
                        Text("3. Dismiss the sheet")
                        Text("4. Check console for 'deallocated' message")
                        Text("5. If no message appears = memory leak!")
                    }
                    .font(.caption)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Retain Cycles")
        .sheet(isPresented: $showSessionDemo) {
            SessionDemoSheet()
        }
        .sheet(isPresented: $showSearchDemo) {
            SearchDemoSheet()
        }
    }
}

struct SessionDemoSheet: View {
    @StateObject private var sessionManager = UserSessionManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Session Status: \(sessionManager.isLoggedIn ? "Logged In" : "Logged Out")")

                if let lastActivity = sessionManager.lastActivity {
                    Text("Last activity: \(lastActivity.formatted())")
                        .font(.caption)
                }

                HStack {
                    Button("Login") {
                        sessionManager.login(token: "abc123")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sessionManager.isLoggedIn)

                    Button("Logout") {
                        sessionManager.logout()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!sessionManager.isLoggedIn)
                }

                Text("Dismiss this sheet and check if\n'UserSessionManager deallocated' prints")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Session Demo")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct SearchDemoSheet: View {
    @StateObject private var searchService = SearchService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Search...", text: $searchService.searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if searchService.isSearching {
                    ProgressView()
                }

                List(searchService.results, id: \.self) { result in
                    Text(result)
                }

                Text("Dismiss this sheet and check if\n'SearchService deallocated' prints")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Search Demo")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PublisherRetainCycleView()
    }
}
