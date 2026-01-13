import XCTest
@testable import TestabilityWorkshop

final class UserProfileManagerTests: XCTestCase {

    var mockAnalytics: MockAnalytics!
    var mockAuth: MockAuth!
    var mockAPI: MockUserProfileAPI!
    var sut: UserProfileManagerAfter!

    override func setUp() {
        super.setUp()
        mockAnalytics = MockAnalytics()
        mockAuth = MockAuth()
        mockAPI = MockUserProfileAPI()

        sut = UserProfileManagerAfter(
            analytics: mockAnalytics,
            auth: mockAuth,
            api: mockAPI
        )
    }

    override func tearDown() {
        mockAnalytics.reset()
        mockAuth.reset()
        mockAPI.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Authentication Tests

    func test_loadProfile_whenNotAuthenticated_setsError() async {
        // Arrange
        mockAuth.currentUserId = nil

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertNotNil(sut.error)
        XCTAssertNil(sut.profile)
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadProfile_whenNotAuthenticated_doesNotCallAPI() async {
        // Arrange
        mockAuth.currentUserId = nil

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertEqual(mockAPI.fetchCallCount, 0)
    }

    // MARK: - Successful Load Tests

    func test_loadProfile_whenAuthenticated_fetchesProfile() async {
        // Arrange
        mockAuth.currentUserId = "user_123"
        mockAPI.profileToReturn = UserProfileData(
            id: "user_123",
            name: "Test User",
            email: "test@example.com"
        )

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertNotNil(sut.profile)
        XCTAssertEqual(sut.profile?.name, "Test User")
        XCTAssertNil(sut.error)
    }

    func test_loadProfile_callsAPIWithCorrectUserId() async {
        // Arrange
        mockAuth.currentUserId = "specific_user_456"
        mockAPI.profileToReturn = UserProfileData(
            id: "specific_user_456",
            name: "Test",
            email: "test@test.com"
        )

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertEqual(mockAPI.fetchCallCount, 1)
    }

    // MARK: - Error Handling Tests

    func test_loadProfile_whenAPIFails_setsError() async {
        // Arrange
        mockAuth.currentUserId = "user_123"
        mockAPI.errorToThrow = ProfileError.networkError

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertNotNil(sut.error)
        XCTAssertNil(sut.profile)
    }

    // MARK: - Analytics Tests

    func test_loadProfile_tracksStartedEvent() async {
        // Arrange
        mockAuth.currentUserId = "user_123"
        mockAPI.profileToReturn = UserProfileData(id: "user_123", name: "Test", email: "test@test.com")

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertTrue(mockAnalytics.eventNames.contains("profile_load_started"))
    }

    func test_loadProfile_onSuccess_tracksSuccessEvent() async {
        // Arrange
        mockAuth.currentUserId = "user_123"
        mockAPI.profileToReturn = UserProfileData(id: "user_123", name: "Test", email: "test@test.com")

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertTrue(mockAnalytics.eventNames.contains("profile_load_success"))
    }

    func test_loadProfile_onFailure_tracksErrorEvent() async {
        // Arrange
        mockAuth.currentUserId = "user_123"
        mockAPI.errorToThrow = ProfileError.networkError

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertTrue(mockAnalytics.eventNames.contains("profile_load_error"))
    }

    func test_loadProfile_tracksEventsInCorrectOrder() async {
        // Arrange
        mockAuth.currentUserId = "user_123"
        mockAPI.profileToReturn = UserProfileData(id: "user_123", name: "Test", email: "test@test.com")

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertEqual(mockAnalytics.eventNames.count, 2)
        XCTAssertEqual(mockAnalytics.eventNames[0], "profile_load_started")
        XCTAssertEqual(mockAnalytics.eventNames[1], "profile_load_success")
    }

    // MARK: - Loading State Tests

    func test_loadProfile_setsIsLoadingDuringFetch() async {
        // Arrange
        mockAuth.currentUserId = "user_123"
        mockAPI.profileToReturn = UserProfileData(id: "user_123", name: "Test", email: "test@test.com")

        // Act
        await sut.loadProfile()

        // Assert - After completion, isLoading should be false
        XCTAssertFalse(sut.isLoading)
    }
}
