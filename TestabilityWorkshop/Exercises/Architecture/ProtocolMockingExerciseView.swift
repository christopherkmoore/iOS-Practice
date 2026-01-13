import SwiftUI

// MARK: - Exercise: Protocol-based mocking patterns
// Comprehensive examples of creating effective mocks for testing

struct ProtocolMockingExerciseView: View {
    var body: some View {
        List {
            Section {
                Text("Learn different mocking patterns: stubs, spies, fakes, and how to verify interactions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Mock Types") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stub: Returns canned responses")
                    Text("Spy: Records method calls for verification")
                    Text("Fake: Working implementation with shortcuts")
                    Text("Mock: Combines spy + stub")
                }
                .font(.caption)
            }

            Section("Best Practices") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Keep protocols focused (ISP)")
                    Text("• Name mock properties clearly")
                    Text("• Provide factory methods")
                    Text("• Reset state between tests")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Protocol Mocking")
    }
}

// MARK: - Protocols to Mock

protocol EmailService {
    func sendEmail(to recipient: String, subject: String, body: String) async throws
    func sendBulkEmail(to recipients: [String], subject: String, body: String) async throws
}

protocol PaymentProcessor {
    func processPayment(amount: Decimal, currency: String, cardToken: String) async throws -> PaymentResult
    func refund(transactionId: String, amount: Decimal) async throws -> RefundResult
}

protocol NotificationScheduler {
    func scheduleNotification(title: String, body: String, at date: Date) throws -> String
    func cancelNotification(id: String) throws
    func getPendingNotifications() -> [ScheduledNotification]
}

// Supporting types
struct PaymentResult {
    let transactionId: String
    let status: PaymentStatus
    let processedAt: Date
}

enum PaymentStatus: Equatable {
    case success
    case declined(reason: String)
    case pending
}

struct RefundResult {
    let refundId: String
    let status: RefundStatus
}

enum RefundStatus {
    case processed
    case pending
    case failed(reason: String)
}

struct ScheduledNotification: Equatable {
    let id: String
    let title: String
    let body: String
    let scheduledDate: Date
}

// MARK: - Business Logic to Test

class OrderService {
    private let paymentProcessor: PaymentProcessor
    private let emailService: EmailService
    private let notificationScheduler: NotificationScheduler

    init(
        paymentProcessor: PaymentProcessor,
        emailService: EmailService,
        notificationScheduler: NotificationScheduler
    ) {
        self.paymentProcessor = paymentProcessor
        self.emailService = emailService
        self.notificationScheduler = notificationScheduler
    }

    func placeOrder(
        amount: Decimal,
        currency: String,
        cardToken: String,
        customerEmail: String
    ) async throws -> OrderResult {
        // Process payment
        let paymentResult = try await paymentProcessor.processPayment(
            amount: amount,
            currency: currency,
            cardToken: cardToken
        )

        guard case .success = paymentResult.status else {
            if case .declined(let reason) = paymentResult.status {
                throw OrderError.paymentDeclined(reason)
            }
            throw OrderError.paymentFailed
        }

        // Send confirmation email
        try await emailService.sendEmail(
            to: customerEmail,
            subject: "Order Confirmed",
            body: "Your order for \(currency) \(amount) has been confirmed."
        )

        // Schedule delivery notification for tomorrow
        let deliveryDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let notificationId = try notificationScheduler.scheduleNotification(
            title: "Delivery Update",
            body: "Your order is out for delivery!",
            at: deliveryDate
        )

        return OrderResult(
            orderId: UUID().uuidString,
            transactionId: paymentResult.transactionId,
            notificationId: notificationId
        )
    }
}

struct OrderResult {
    let orderId: String
    let transactionId: String
    let notificationId: String
}

enum OrderError: Error, Equatable {
    case paymentDeclined(String)
    case paymentFailed
    case emailFailed
}

// MARK: - Example Mocks and Tests
/*

 // MARK: - Mock Email Service (Spy Pattern)
 class MockEmailService: EmailService {
     // Track all calls for verification
     struct SendEmailCall: Equatable {
         let recipient: String
         let subject: String
         let body: String
     }

     private(set) var sendEmailCalls: [SendEmailCall] = []
     private(set) var sendBulkEmailCalls: [(recipients: [String], subject: String, body: String)] = []

     var shouldThrowError: Error?

     func sendEmail(to recipient: String, subject: String, body: String) async throws {
         sendEmailCalls.append(SendEmailCall(recipient: recipient, subject: subject, body: body))
         if let error = shouldThrowError { throw error }
     }

     func sendBulkEmail(to recipients: [String], subject: String, body: String) async throws {
         sendBulkEmailCalls.append((recipients, subject, body))
         if let error = shouldThrowError { throw error }
     }

     // Verification helpers
     var sendEmailCallCount: Int { sendEmailCalls.count }

     func verifySendEmailCalled(with recipient: String) -> Bool {
         sendEmailCalls.contains { $0.recipient == recipient }
     }

     func reset() {
         sendEmailCalls = []
         sendBulkEmailCalls = []
         shouldThrowError = nil
     }
 }

 // MARK: - Mock Payment Processor (Stub + Spy Pattern)
 class MockPaymentProcessor: PaymentProcessor {
     // Configurable responses
     var paymentResultToReturn: PaymentResult = PaymentResult(
         transactionId: "txn_123",
         status: .success,
         processedAt: Date()
     )
     var refundResultToReturn: RefundResult = RefundResult(
         refundId: "ref_123",
         status: .processed
     )
     var errorToThrow: Error?

     // Call tracking
     struct ProcessPaymentCall {
         let amount: Decimal
         let currency: String
         let cardToken: String
     }

     private(set) var processPaymentCalls: [ProcessPaymentCall] = []
     private(set) var refundCalls: [(transactionId: String, amount: Decimal)] = []

     func processPayment(amount: Decimal, currency: String, cardToken: String) async throws -> PaymentResult {
         processPaymentCalls.append(ProcessPaymentCall(amount: amount, currency: currency, cardToken: cardToken))
         if let error = errorToThrow { throw error }
         return paymentResultToReturn
     }

     func refund(transactionId: String, amount: Decimal) async throws -> RefundResult {
         refundCalls.append((transactionId, amount))
         if let error = errorToThrow { throw error }
         return refundResultToReturn
     }

     // Helpers
     func setDeclinedResponse(reason: String) {
         paymentResultToReturn = PaymentResult(
             transactionId: "txn_declined",
             status: .declined(reason: reason),
             processedAt: Date()
         )
     }

     func reset() {
         paymentResultToReturn = PaymentResult(transactionId: "txn_123", status: .success, processedAt: Date())
         errorToThrow = nil
         processPaymentCalls = []
         refundCalls = []
     }
 }

 // MARK: - Mock Notification Scheduler (Fake Pattern)
 class MockNotificationScheduler: NotificationScheduler {
     private var notifications: [String: ScheduledNotification] = [:]
     private var nextId = 1

     var shouldThrowError: Error?

     func scheduleNotification(title: String, body: String, at date: Date) throws -> String {
         if let error = shouldThrowError { throw error }

         let id = "notif_\(nextId)"
         nextId += 1

         notifications[id] = ScheduledNotification(
             id: id,
             title: title,
             body: body,
             scheduledDate: date
         )

         return id
     }

     func cancelNotification(id: String) throws {
         notifications.removeValue(forKey: id)
     }

     func getPendingNotifications() -> [ScheduledNotification] {
         Array(notifications.values)
     }

     // Test helpers
     func hasNotification(withId id: String) -> Bool {
         notifications[id] != nil
     }

     func reset() {
         notifications = [:]
         nextId = 1
         shouldThrowError = nil
     }
 }

 // MARK: - Tests

 class OrderServiceTests: XCTestCase {

     var mockPayment: MockPaymentProcessor!
     var mockEmail: MockEmailService!
     var mockNotifications: MockNotificationScheduler!
     var sut: OrderService!

     override func setUp() {
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
     }

     func test_placeOrder_processesPayment() async throws {
         // Act
         _ = try await sut.placeOrder(
             amount: 99.99,
             currency: "USD",
             cardToken: "tok_123",
             customerEmail: "test@example.com"
         )

         // Assert - Payment was processed with correct parameters
         XCTAssertEqual(mockPayment.processPaymentCalls.count, 1)
         XCTAssertEqual(mockPayment.processPaymentCalls[0].amount, 99.99)
         XCTAssertEqual(mockPayment.processPaymentCalls[0].currency, "USD")
         XCTAssertEqual(mockPayment.processPaymentCalls[0].cardToken, "tok_123")
     }

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
         XCTAssertTrue(mockEmail.verifySendEmailCalled(with: "customer@test.com"))
         XCTAssertEqual(mockEmail.sendEmailCalls[0].subject, "Order Confirmed")
     }

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
         let pending = mockNotifications.getPendingNotifications()
         XCTAssertEqual(pending.count, 1)
         XCTAssertEqual(pending[0].title, "Delivery Update")
     }

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
             XCTFail("Expected error")
         } catch OrderError.paymentDeclined(let reason) {
             XCTAssertEqual(reason, "Insufficient funds")
         } catch {
             XCTFail("Wrong error type: \(error)")
         }

         // Verify email was NOT sent
         XCTAssertEqual(mockEmail.sendEmailCallCount, 0)
     }

     func test_placeOrder_whenPaymentDeclined_doesNotScheduleNotification() async {
         // Arrange
         mockPayment.setDeclinedResponse(reason: "Card expired")

         // Act
         _ = try? await sut.placeOrder(
             amount: 100,
             currency: "USD",
             cardToken: "tok_123",
             customerEmail: "test@example.com"
         )

         // Assert - No notifications scheduled
         XCTAssertTrue(mockNotifications.getPendingNotifications().isEmpty)
     }
 }

 */

#Preview {
    NavigationStack {
        ProtocolMockingExerciseView()
    }
}
