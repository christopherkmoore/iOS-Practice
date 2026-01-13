import SwiftUI

// MARK: - Exercise: Refactor singleton dependencies for testability
// The "Before" code directly accesses singletons, making it impossible to test in isolation

struct SingletonExerciseView: View {
    var body: some View {
        List {
            Section {
                Text("Compare the Before and After implementations. The After version uses dependency injection instead of direct singleton access.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Before (Untestable)") {
                Text("UserProfileManager directly accesses:\n• AnalyticsService.shared\n• AuthenticationManager.shared\n• APIClient.shared")
                    .font(.caption)
            }

            Section("After (Testable)") {
                Text("Dependencies are injected via protocols, allowing mock implementations in tests.")
                    .font(.caption)
            }

            Section("Key Refactoring Steps") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Extract protocols for each dependency")
                    Text("2. Have singletons conform to protocols")
                    Text("3. Inject dependencies via initializer")
                    Text("4. Provide default values for production use")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Singleton Dependencies")
    }
}

// MARK: - BEFORE: Untestable Code

class AnalyticsServiceSingleton {
    static let shared = AnalyticsServiceSingleton()
    private init() {}

    func track(event: String, properties: [String: Any]?) {
        print("Tracking: \(event)")
        // Send to analytics backend
    }
}

class AuthenticationManagerSingleton {
    static let shared = AuthenticationManagerSingleton()
    private init() {}

    var currentUserId: String? {
        // In real app, this would return actual user ID
        return "user_123"
    }

    var isAuthenticated: Bool {
        return currentUserId != nil
    }
}

class APIClientSingleton {
    static let shared = APIClientSingleton()
    private init() {}

    func fetchUserProfile(userId: String) async throws -> UserProfileData {
        // Real network call
        try await Task.sleep(nanoseconds: 500_000_000)
        return UserProfileData(id: userId, name: "John Doe", email: "john@example.com")
    }
}

struct UserProfileData {
    let id: String
    let name: String
    let email: String
}

// ❌ UNTESTABLE: Direct singleton access
class UserProfileManagerBefore {
    var profile: UserProfileData?
    var isLoading = false
    var error: Error?

    func loadProfile() async {
        // ❌ Can't test without hitting real analytics
        AnalyticsServiceSingleton.shared.track(event: "profile_load_started", properties: nil)

        // ❌ Can't control authentication state in tests
        guard let userId = AuthenticationManagerSingleton.shared.currentUserId else {
            error = ProfileError.notAuthenticated
            return
        }

        isLoading = true

        do {
            // ❌ Can't mock network responses
            profile = try await APIClientSingleton.shared.fetchUserProfile(userId: userId)
            AnalyticsServiceSingleton.shared.track(event: "profile_load_success", properties: ["userId": userId])
        } catch {
            self.error = error
            AnalyticsServiceSingleton.shared.track(event: "profile_load_error", properties: ["error": error.localizedDescription])
        }

        isLoading = false
    }
}

enum ProfileError: Error {
    case notAuthenticated
    case networkError
}

// MARK: - AFTER: Testable Code

// Step 1: Define protocols for each dependency
protocol AnalyticsTracking {
    func track(event: String, properties: [String: Any]?)
}

protocol AuthenticationProviding {
    var currentUserId: String? { get }
    var isAuthenticated: Bool { get }
}

protocol UserProfileFetching {
    func fetchUserProfile(userId: String) async throws -> UserProfileData
}

// Step 2: Make singletons conform to protocols
extension AnalyticsServiceSingleton: AnalyticsTracking {}
extension AuthenticationManagerSingleton: AuthenticationProviding {}
extension APIClientSingleton: UserProfileFetching {}

// Step 3: Refactor to accept dependencies
// ✅ TESTABLE: Dependencies are injected
class UserProfileManagerAfter {
    var profile: UserProfileData?
    var isLoading = false
    var error: Error?

    // Dependencies with default values for production
    private let analytics: AnalyticsTracking
    private let auth: AuthenticationProviding
    private let api: UserProfileFetching

    init(
        analytics: AnalyticsTracking = AnalyticsServiceSingleton.shared,
        auth: AuthenticationProviding = AuthenticationManagerSingleton.shared,
        api: UserProfileFetching = APIClientSingleton.shared
    ) {
        self.analytics = analytics
        self.auth = auth
        self.api = api
    }

    func loadProfile() async {
        analytics.track(event: "profile_load_started", properties: nil)

        guard let userId = auth.currentUserId else {
            error = ProfileError.notAuthenticated
            return
        }

        isLoading = true

        do {
            profile = try await api.fetchUserProfile(userId: userId)
            analytics.track(event: "profile_load_success", properties: ["userId": userId])
        } catch {
            self.error = error
            analytics.track(event: "profile_load_error", properties: ["error": error.localizedDescription])
        }

        isLoading = false
    }
}

// MARK: - Example Tests (would go in test target)
/*

 // Mock implementations for testing
 class MockAnalytics: AnalyticsTracking {
     var trackedEvents: [(event: String, properties: [String: Any]?)] = []

     func track(event: String, properties: [String: Any]?) {
         trackedEvents.append((event, properties))
     }
 }

 class MockAuth: AuthenticationProviding {
     var currentUserId: String?
     var isAuthenticated: Bool { currentUserId != nil }
 }

 class MockAPI: UserProfileFetching {
     var profileToReturn: UserProfileData?
     var errorToThrow: Error?

     func fetchUserProfile(userId: String) async throws -> UserProfileData {
         if let error = errorToThrow { throw error }
         return profileToReturn!
     }
 }

 // Test class
 class UserProfileManagerTests: XCTestCase {

     func test_loadProfile_whenNotAuthenticated_setsError() async {
         // Arrange
         let mockAuth = MockAuth()
         mockAuth.currentUserId = nil  // Not authenticated

         let sut = UserProfileManagerAfter(
             analytics: MockAnalytics(),
             auth: mockAuth,
             api: MockAPI()
         )

         // Act
         await sut.loadProfile()

         // Assert
         XCTAssertNotNil(sut.error)
         XCTAssertNil(sut.profile)
     }

     func test_loadProfile_tracksAnalyticsEvents() async {
         // Arrange
         let mockAnalytics = MockAnalytics()
         let mockAuth = MockAuth()
         mockAuth.currentUserId = "user_123"

         let mockAPI = MockAPI()
         mockAPI.profileToReturn = UserProfileData(id: "user_123", name: "Test", email: "test@test.com")

         let sut = UserProfileManagerAfter(
             analytics: mockAnalytics,
             auth: mockAuth,
             api: mockAPI
         )

         // Act
         await sut.loadProfile()

         // Assert
         XCTAssertEqual(mockAnalytics.trackedEvents.count, 2)
         XCTAssertEqual(mockAnalytics.trackedEvents[0].event, "profile_load_started")
         XCTAssertEqual(mockAnalytics.trackedEvents[1].event, "profile_load_success")
     }
 }

 */

#Preview {
    NavigationStack {
        SingletonExerciseView()
    }
}
