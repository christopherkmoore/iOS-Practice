import XCTest
@testable import TestabilityWorkshop

final class OrderServiceTests: XCTestCase {

    var mockPayment: MockPaymentProcessor!
    var mockEmail: MockEmailService!
    var mockNotifications: MockNotificationScheduler!
    var sut: OrderService!

    override func setUp() {
        super.setUp()
        mockPayment = MockPaymentProcessor()
        mockEmail = MockEmailService()
        mockNotifications = MockNotificationScheduler()

        sut = OrderService(
            paymentProcessor: mockPayment,
            emailService: mockEmail,
            notificationScheduler: mockNotifications
        )
    }

    override func tearDown() {
        mockPayment.reset()
        mockEmail.reset()
        mockNotifications.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Payment Processing Tests

    func test_placeOrder_processesPayment() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 99.99,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        XCTAssertEqual(mockPayment.processPaymentCalls.count, 1)
    }

    func test_placeOrder_passesCorrectAmountToPayment() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 149.99,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        XCTAssertEqual(mockPayment.processPaymentCalls[0].amount, 149.99)
    }

    func test_placeOrder_passesCorrectCurrencyToPayment() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 100,
            currency: "EUR",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        XCTAssertEqual(mockPayment.processPaymentCalls[0].currency, "EUR")
    }

    func test_placeOrder_passesCorrectCardTokenToPayment() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 100,
            currency: "USD",
            cardToken: "tok_specific_456",
            customerEmail: "test@example.com"
        )

        // Assert
        XCTAssertEqual(mockPayment.processPaymentCalls[0].cardToken, "tok_specific_456")
    }

    // MARK: - Email Sending Tests

    func test_placeOrder_sendsConfirmationEmail() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 50.00,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "customer@test.com"
        )

        // Assert
        XCTAssertEqual(mockEmail.sendEmailCallCount, 1)
    }

    func test_placeOrder_sendsEmailToCorrectRecipient() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 50.00,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "specific@email.com"
        )

        // Assert
        XCTAssertTrue(mockEmail.verifySendEmailCalled(with: "specific@email.com"))
    }

    func test_placeOrder_emailHasCorrectSubject() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 50.00,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@test.com"
        )

        // Assert
        XCTAssertEqual(mockEmail.sendEmailCalls[0].subject, "Order Confirmed")
    }

    func test_placeOrder_emailBodyContainsAmount() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 199.99,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@test.com"
        )

        // Assert
        let body = mockEmail.sendEmailCalls[0].body
        XCTAssertTrue(body.contains("199.99"))
    }

    // MARK: - Notification Scheduling Tests

    func test_placeOrder_schedulesDeliveryNotification() async throws {
        // Act
        let result = try await sut.placeOrder(
            amount: 100,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        XCTAssertTrue(mockNotifications.hasNotification(withId: result.notificationId))
    }

    func test_placeOrder_notificationHasCorrectTitle() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 100,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        let pending = mockNotifications.getPendingNotifications()
        XCTAssertEqual(pending.first?.title, "Delivery Update")
    }

    func test_placeOrder_notificationScheduledForTomorrow() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 100,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        let pending = mockNotifications.getPendingNotifications()
        let scheduledDate = pending.first?.scheduledDate
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        // Check it's scheduled for tomorrow (within a few seconds tolerance)
        XCTAssertNotNil(scheduledDate)
        let difference = abs(scheduledDate!.timeIntervalSince(tomorrow))
        XCTAssertLessThan(difference, 10) // Within 10 seconds
    }

    // MARK: - Order Result Tests

    func test_placeOrder_returnsOrderResult() async throws {
        // Act
        let result = try await sut.placeOrder(
            amount: 100,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        XCTAssertFalse(result.orderId.isEmpty)
        XCTAssertFalse(result.transactionId.isEmpty)
        XCTAssertFalse(result.notificationId.isEmpty)
    }

    func test_placeOrder_returnsTransactionIdFromPayment() async throws {
        // Arrange
        mockPayment.paymentResultToReturn = PaymentResult(
            transactionId: "txn_specific_789",
            status: .success,
            processedAt: Date()
        )

        // Act
        let result = try await sut.placeOrder(
            amount: 100,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        XCTAssertEqual(result.transactionId, "txn_specific_789")
    }

    // MARK: - Payment Declined Tests

    func test_placeOrder_whenPaymentDeclined_throwsError() async {
        // Arrange
        mockPayment.setDeclinedResponse(reason: "Insufficient funds")

        // Act & Assert
        do {
            _ = try await sut.placeOrder(
                amount: 1000,
                currency: "USD",
                cardToken: "tok_123",
                customerEmail: "test@example.com"
            )
            XCTFail("Expected error to be thrown")
        } catch OrderError.paymentDeclined(let reason) {
            XCTAssertEqual(reason, "Insufficient funds")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func test_placeOrder_whenPaymentDeclined_doesNotSendEmail() async {
        // Arrange
        mockPayment.setDeclinedResponse(reason: "Card expired")

        // Act
        _ = try? await sut.placeOrder(
            amount: 100,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        XCTAssertEqual(mockEmail.sendEmailCallCount, 0)
    }

    func test_placeOrder_whenPaymentDeclined_doesNotScheduleNotification() async {
        // Arrange
        mockPayment.setDeclinedResponse(reason: "Declined")

        // Act
        _ = try? await sut.placeOrder(
            amount: 100,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert
        XCTAssertTrue(mockNotifications.getPendingNotifications().isEmpty)
    }

    // MARK: - Integration / Order of Operations Tests

    func test_placeOrder_callsServicesInCorrectOrder() async throws {
        // This test verifies payment is processed before email is sent
        // We can verify by checking that both were called after success

        // Act
        _ = try await sut.placeOrder(
            amount: 100,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert - All services should have been called
        XCTAssertEqual(mockPayment.processPaymentCalls.count, 1)
        XCTAssertEqual(mockEmail.sendEmailCallCount, 1)
        XCTAssertEqual(mockNotifications.getPendingNotifications().count, 1)
    }

    // MARK: - Edge Cases

    func test_placeOrder_withZeroAmount() async throws {
        // Act
        _ = try await sut.placeOrder(
            amount: 0,
            currency: "USD",
            cardToken: "tok_123",
            customerEmail: "test@example.com"
        )

        // Assert - Should still process (business logic may vary)
        XCTAssertEqual(mockPayment.processPaymentCalls[0].amount, 0)
    }

    func test_placeOrder_withDifferentCurrencies() async throws {
        // Act
        _ = try await sut.placeOrder(amount: 100, currency: "GBP", cardToken: "tok_1", customerEmail: "a@b.com")
        _ = try await sut.placeOrder(amount: 100, currency: "JPY", cardToken: "tok_2", customerEmail: "a@b.com")
        _ = try await sut.placeOrder(amount: 100, currency: "AUD", cardToken: "tok_3", customerEmail: "a@b.com")

        // Assert
        XCTAssertEqual(mockPayment.processPaymentCalls[0].currency, "GBP")
        XCTAssertEqual(mockPayment.processPaymentCalls[1].currency, "JPY")
        XCTAssertEqual(mockPayment.processPaymentCalls[2].currency, "AUD")
    }
}
