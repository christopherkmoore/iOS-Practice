import XCTest
@testable import TestabilityWorkshop

final class SubscriptionManagerTests: XCTestCase {

    var mockDateProvider: MockDateProvider!
    var sut: SubscriptionManagerAfter!

    override func setUp() {
        super.setUp()
        mockDateProvider = MockDateProvider()
        sut = SubscriptionManagerAfter(dateProvider: mockDateProvider)
    }

    override func tearDown() {
        mockDateProvider = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    func makeSubscription(expiresYear: Int, expiresMonth: Int, expiresDay: Int) -> Subscription {
        let expirationDate = MockDateProvider.makeDate(
            year: expiresYear,
            month: expiresMonth,
            day: expiresDay
        )
        return Subscription(
            id: "test_sub",
            planName: "Pro",
            expirationDate: expirationDate,
            createdAt: Date().addingTimeInterval(-86400 * 30)
        )
    }

    // MARK: - isSubscriptionValid Tests

    func test_isSubscriptionValid_whenNotExpired_returnsTrue() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 12, expiresDay: 31)

        // Act
        let isValid = sut.isSubscriptionValid(subscription)

        // Assert
        XCTAssertTrue(isValid)
    }

    func test_isSubscriptionValid_whenExpired_returnsFalse() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 1, expiresDay: 1)

        // Act
        let isValid = sut.isSubscriptionValid(subscription)

        // Assert
        XCTAssertFalse(isValid)
    }

    func test_isSubscriptionValid_whenExpiringToday_comparisonIsCorrect() {
        // Arrange - Subscription expires at 11:59 PM, now is noon
        mockDateProvider.setNow(year: 2024, month: 6, day: 1, hour: 12)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 1)

        // Act
        let isValid = sut.isSubscriptionValid(subscription)

        // Assert - Subscription that expires at 11:59 PM is still valid at noon
        XCTAssertTrue(isValid)
    }

    // MARK: - daysUntilExpiration Tests

    func test_daysUntilExpiration_returns7_whenExpires7DaysFromNow() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 8)

        // Act
        let days = sut.daysUntilExpiration(subscription)

        // Assert
        XCTAssertEqual(days, 7)
    }

    func test_daysUntilExpiration_returns0_whenExpiresToday() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 1)

        // Act
        let days = sut.daysUntilExpiration(subscription)

        // Assert
        XCTAssertEqual(days, 0)
    }

    func test_daysUntilExpiration_returns0_whenAlreadyExpired() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 15)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 1)

        // Act
        let days = sut.daysUntilExpiration(subscription)

        // Assert - Should never return negative
        XCTAssertEqual(days, 0)
    }

    func test_daysUntilExpiration_returns30_forMonthAway() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 7, expiresDay: 1)

        // Act
        let days = sut.daysUntilExpiration(subscription)

        // Assert
        XCTAssertEqual(days, 30)
    }

    // MARK: - shouldShowRenewalReminder Tests

    func test_shouldShowRenewalReminder_whenExpiresIn7Days_returnsTrue() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 8)

        // Act & Assert
        XCTAssertTrue(sut.shouldShowRenewalReminder(subscription))
    }

    func test_shouldShowRenewalReminder_whenExpiresIn1Day_returnsTrue() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 2)

        // Act & Assert
        XCTAssertTrue(sut.shouldShowRenewalReminder(subscription))
    }

    func test_shouldShowRenewalReminder_whenExpiresIn8Days_returnsFalse() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 9)

        // Act & Assert
        XCTAssertFalse(sut.shouldShowRenewalReminder(subscription))
    }

    func test_shouldShowRenewalReminder_whenExpiresToday_returnsFalse() {
        // Arrange - 0 days is not > 0, so should return false
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 1)

        // Act & Assert
        XCTAssertFalse(sut.shouldShowRenewalReminder(subscription))
    }

    func test_shouldShowRenewalReminder_whenAlreadyExpired_returnsFalse() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 15)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 1)

        // Act & Assert
        XCTAssertFalse(sut.shouldShowRenewalReminder(subscription))
    }

    // MARK: - formatExpirationMessage Tests

    func test_formatExpirationMessage_whenExpiresToday_returnsCorrectMessage() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 1)

        // Act
        let message = sut.formatExpirationMessage(subscription)

        // Assert
        XCTAssertEqual(message, "Expires today!")
    }

    func test_formatExpirationMessage_whenExpiresTomorrow_returnsCorrectMessage() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 2)

        // Act
        let message = sut.formatExpirationMessage(subscription)

        // Assert
        XCTAssertEqual(message, "Expires tomorrow")
    }

    func test_formatExpirationMessage_whenExpiresIn5Days_returnsCorrectMessage() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 6)

        // Act
        let message = sut.formatExpirationMessage(subscription)

        // Assert
        XCTAssertEqual(message, "Expires in 5 days")
    }

    func test_formatExpirationMessage_whenExpiresIn30Days_containsExpiresOn() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1)
        let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 7, expiresDay: 1)

        // Act
        let message = sut.formatExpirationMessage(subscription)

        // Assert
        XCTAssertTrue(message.hasPrefix("Expires on"))
    }

    // MARK: - subscriptionAge Tests

    func test_subscriptionAge_returnsCorrectInterval() {
        // Arrange
        mockDateProvider.setNow(year: 2024, month: 6, day: 1, hour: 12)
        let createdAt = MockDateProvider.makeDate(year: 2024, month: 5, day: 1, hour: 12)
        let subscription = Subscription(
            id: "test",
            planName: "Pro",
            expirationDate: MockDateProvider.makeDate(year: 2024, month: 12, day: 31),
            createdAt: createdAt
        )

        // Act
        let age = sut.subscriptionAge(subscription)

        // Assert - Should be approximately 31 days in seconds
        let expectedAge: TimeInterval = 31 * 24 * 60 * 60
        XCTAssertEqual(age, expectedAge, accuracy: 60) // Allow 1 minute variance
    }
}
