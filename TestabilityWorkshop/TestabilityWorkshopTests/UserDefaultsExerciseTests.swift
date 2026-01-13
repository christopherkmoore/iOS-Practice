import XCTest
@testable import TestabilityWorkshop

final class OnboardingManagerTests: XCTestCase {

    var store: InMemoryKeyValueStore!
    var sut: OnboardingManagerAfter!

    override func setUp() {
        super.setUp()
        store = InMemoryKeyValueStore()
        sut = OnboardingManagerAfter(store: store)
    }

    override func tearDown() {
        store.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - shouldShowOnboarding Tests

    func test_shouldShowOnboarding_onFirstLaunch_returnsTrue() {
        // Fresh store, no onboarding completed
        XCTAssertTrue(sut.shouldShowOnboarding())
    }

    func test_shouldShowOnboarding_afterCompletion_returnsFalse() {
        // Arrange
        sut.completeOnboarding()

        // Act & Assert
        XCTAssertFalse(sut.shouldShowOnboarding())
    }

    func test_shouldShowOnboarding_whenExplicitlySetToTrue_returnsTrue() {
        // Arrange - User somehow resets onboarding
        sut.completeOnboarding()
        sut.hasSeenOnboarding = false

        // Act & Assert
        XCTAssertTrue(sut.shouldShowOnboarding())
    }

    // MARK: - shouldShowWhatsNew Tests

    func test_shouldShowWhatsNew_onFirstInstall_returnsFalse() {
        // No previous version stored
        XCTAssertFalse(sut.shouldShowWhatsNew(currentVersion: "1.0.0"))
    }

    func test_shouldShowWhatsNew_whenVersionChanged_returnsTrue() {
        // Arrange
        sut.updateVersion(to: "1.0.0")

        // Act & Assert
        XCTAssertTrue(sut.shouldShowWhatsNew(currentVersion: "2.0.0"))
    }

    func test_shouldShowWhatsNew_whenVersionSame_returnsFalse() {
        // Arrange
        sut.updateVersion(to: "1.0.0")

        // Act & Assert
        XCTAssertFalse(sut.shouldShowWhatsNew(currentVersion: "1.0.0"))
    }

    func test_shouldShowWhatsNew_forMinorVersionBump_returnsTrue() {
        // Arrange
        sut.updateVersion(to: "1.0.0")

        // Act & Assert
        XCTAssertTrue(sut.shouldShowWhatsNew(currentVersion: "1.1.0"))
    }

    func test_shouldShowWhatsNew_forPatchVersionBump_returnsTrue() {
        // Arrange
        sut.updateVersion(to: "1.0.0")

        // Act & Assert - Even patch versions trigger what's new
        XCTAssertTrue(sut.shouldShowWhatsNew(currentVersion: "1.0.1"))
    }

    // MARK: - shouldShowRatePrompt Tests

    func test_shouldShowRatePrompt_atLaunchCount0_returnsFalse() {
        // Fresh install
        XCTAssertFalse(sut.shouldShowRatePrompt())
    }

    func test_shouldShowRatePrompt_atLaunchCount5_returnsFalse() {
        // Arrange - 5 is >= 5 but 5 % 10 != 0
        store.setInt(5, forKey: "launchCount")

        // Act & Assert
        XCTAssertFalse(sut.shouldShowRatePrompt())
    }

    func test_shouldShowRatePrompt_atLaunchCount10_returnsTrue() {
        // Arrange
        store.setInt(10, forKey: "launchCount")

        // Act & Assert
        XCTAssertTrue(sut.shouldShowRatePrompt())
    }

    func test_shouldShowRatePrompt_atLaunchCount20_returnsTrue() {
        // Arrange
        store.setInt(20, forKey: "launchCount")

        // Act & Assert
        XCTAssertTrue(sut.shouldShowRatePrompt())
    }

    func test_shouldShowRatePrompt_atLaunchCount15_returnsFalse() {
        // Arrange - 15 >= 5 but 15 % 10 != 0
        store.setInt(15, forKey: "launchCount")

        // Act & Assert
        XCTAssertFalse(sut.shouldShowRatePrompt())
    }

    func test_shouldShowRatePrompt_atLaunchCount3_returnsFalse() {
        // Arrange - Less than 5
        store.setInt(3, forKey: "launchCount")

        // Act & Assert
        XCTAssertFalse(sut.shouldShowRatePrompt())
    }

    // MARK: - incrementLaunchCount Tests

    func test_incrementLaunchCount_incrementsFromZero() {
        // Act
        sut.incrementLaunchCount()

        // Assert
        XCTAssertEqual(sut.launchCount, 1)
    }

    func test_incrementLaunchCount_incrementsExistingValue() {
        // Arrange
        store.setInt(10, forKey: "launchCount")

        // Act
        sut.incrementLaunchCount()

        // Assert
        XCTAssertEqual(sut.launchCount, 11)
    }

    func test_incrementLaunchCount_calledMultipleTimes() {
        // Act
        sut.incrementLaunchCount()
        sut.incrementLaunchCount()
        sut.incrementLaunchCount()

        // Assert
        XCTAssertEqual(sut.launchCount, 3)
    }

    // MARK: - completeOnboarding Tests

    func test_completeOnboarding_setsHasSeenOnboardingToTrue() {
        // Arrange
        XCTAssertFalse(sut.hasSeenOnboarding)

        // Act
        sut.completeOnboarding()

        // Assert
        XCTAssertTrue(sut.hasSeenOnboarding)
    }

    // MARK: - updateVersion Tests

    func test_updateVersion_storesVersion() {
        // Act
        sut.updateVersion(to: "3.2.1")

        // Assert
        XCTAssertEqual(sut.lastAppVersion, "3.2.1")
    }

    func test_updateVersion_overwritesPreviousVersion() {
        // Arrange
        sut.updateVersion(to: "1.0.0")

        // Act
        sut.updateVersion(to: "2.0.0")

        // Assert
        XCTAssertEqual(sut.lastAppVersion, "2.0.0")
    }

    // MARK: - Integration Tests

    func test_typicalUserFlow_firstLaunch() {
        // First launch - should show onboarding
        XCTAssertTrue(sut.shouldShowOnboarding())
        XCTAssertFalse(sut.shouldShowWhatsNew(currentVersion: "1.0.0"))
        XCTAssertFalse(sut.shouldShowRatePrompt())

        // Complete onboarding
        sut.completeOnboarding()
        sut.updateVersion(to: "1.0.0")
        sut.incrementLaunchCount()

        // Second launch
        XCTAssertFalse(sut.shouldShowOnboarding())
        XCTAssertFalse(sut.shouldShowWhatsNew(currentVersion: "1.0.0"))
    }

    func test_typicalUserFlow_afterUpdate() {
        // Setup: User has used app before
        sut.completeOnboarding()
        sut.updateVersion(to: "1.0.0")
        store.setInt(15, forKey: "launchCount")

        // App updates to 2.0.0
        XCTAssertFalse(sut.shouldShowOnboarding()) // Already seen
        XCTAssertTrue(sut.shouldShowWhatsNew(currentVersion: "2.0.0")) // New version
    }
}
