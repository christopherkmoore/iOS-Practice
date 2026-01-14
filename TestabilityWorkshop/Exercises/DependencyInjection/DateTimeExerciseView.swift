import SwiftUI
import Foundation

// MARK: - Exercise: Make date/time dependencies testable
// Code that uses Date() directly is impossible to test deterministically
//
// Try it yourself: Delete from line 96 (// MARK: - AFTER) onwards and refactor
// SubscriptionManagerBefore to be testable. Goal: make DateTimeExerciseTests.swift pass.

struct DateTimeExerciseView: View {
    var body: some View {
        List {
            Section {
                Text("Code using Date() directly can't be tested reliably because time keeps changing. Inject a date provider instead.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Common Problems") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Tests fail at midnight/year boundaries")
                    Text("• Can't test 'expired' scenarios")
                    Text("• Can't test time-based logic")
                    Text("• Flaky date comparison tests")
                }
                .font(.caption)
            }

            Section("Key Refactoring Steps") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Create DateProviding protocol")
                    Text("2. Create SystemDateProvider for production")
                    Text("3. Create MockDateProvider for tests")
                    Text("4. Inject provider instead of using Date()")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Date/Time Dependencies")
    }
}

// MARK: - BEFORE: Untestable Code

struct Subscription {
    let id: String
    let planName: String
    let expirationDate: Date
    let createdAt: Date
}

// ❌ UNTESTABLE: Direct Date() usage
class SubscriptionManagerBefore {

    func isSubscriptionValid(_ subscription: Subscription) -> Bool {
        // ❌ Can't control "now" in tests
        return subscription.expirationDate > Date()
    }

    func daysUntilExpiration(_ subscription: Subscription) -> Int {
        // ❌ Will give different results at different times
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: subscription.expirationDate)
        return max(0, components.day ?? 0)
    }

    func shouldShowRenewalReminder(_ subscription: Subscription) -> Bool {
        // ❌ Can't test the 7-day threshold
        let daysLeft = daysUntilExpiration(subscription)
        return daysLeft <= 7 && daysLeft > 0
    }

    func subscriptionAge(_ subscription: Subscription) -> TimeInterval {
        // ❌ Age changes every second
        return Date().timeIntervalSince(subscription.createdAt)
    }

    func formatExpirationMessage(_ subscription: Subscription) -> String {
        let days = daysUntilExpiration(subscription)

        if days == 0 {
            return "Expires today!"
        } else if days == 1 {
            return "Expires tomorrow"
        } else if days <= 7 {
            return "Expires in \(days) days"
        } else {
            return "Expires on \(formatDate(subscription.expirationDate))"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - AFTER: Testable Code

// Step 1: Define date provider protocol
protocol DateProviding {
    var now: Date { get }
}

// Step 2: Production implementation
struct SystemDateProvider: DateProviding {
    var now: Date { Date() }
}

// ✅ TESTABLE: Date provider is injected
class SubscriptionManagerAfter {
    private let dateProvider: DateProviding
    private let calendar: Calendar

    init(
        dateProvider: DateProviding = SystemDateProvider(),
        calendar: Calendar = .current
    ) {
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    func isSubscriptionValid(_ subscription: Subscription) -> Bool {
        return subscription.expirationDate > dateProvider.now
    }

    func daysUntilExpiration(_ subscription: Subscription) -> Int {
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: dateProvider.now),
            to: calendar.startOfDay(for: subscription.expirationDate)
        )
        return max(0, components.day ?? 0)
    }

    func shouldShowRenewalReminder(_ subscription: Subscription) -> Bool {
        let daysLeft = daysUntilExpiration(subscription)
        return daysLeft <= 7 && daysLeft > 0
    }

    func subscriptionAge(_ subscription: Subscription) -> TimeInterval {
        return dateProvider.now.timeIntervalSince(subscription.createdAt)
    }

    func formatExpirationMessage(_ subscription: Subscription) -> String {
        let days = daysUntilExpiration(subscription)

        if days == 0 {
            return "Expires today!"
        } else if days == 1 {
            return "Expires tomorrow"
        } else if days <= 7 {
            return "Expires in \(days) days"
        } else {
            return "Expires on \(formatDate(subscription.expirationDate))"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Example Tests
/*

 // Mock date provider
 class MockDateProvider: DateProviding {
     var now: Date

     init(now: Date = Date()) {
         self.now = now
     }

     // Helper to create dates relative to "now"
     func setNow(year: Int, month: Int, day: Int, hour: Int = 12) {
         var components = DateComponents()
         components.year = year
         components.month = month
         components.day = day
         components.hour = hour
         now = Calendar.current.date(from: components)!
     }
 }

 class SubscriptionManagerTests: XCTestCase {

     var mockDateProvider: MockDateProvider!
     var sut: SubscriptionManagerAfter!

     override func setUp() {
         mockDateProvider = MockDateProvider()
         sut = SubscriptionManagerAfter(dateProvider: mockDateProvider)
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

     func test_isSubscriptionValid_whenExpiringToday_returnsFalse() {
         // Arrange - expires at start of today, now is noon
         mockDateProvider.setNow(year: 2024, month: 6, day: 1, hour: 12)
         var components = DateComponents()
         components.year = 2024
         components.month = 6
         components.day = 1
         components.hour = 0
         let expirationDate = Calendar.current.date(from: components)!
         let subscription = Subscription(id: "1", planName: "Pro", expirationDate: expirationDate, createdAt: Date())

         // Act
         let isValid = sut.isSubscriptionValid(subscription)

         // Assert
         XCTAssertFalse(isValid)
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

         // Assert
         XCTAssertEqual(days, 0) // Never negative
     }

     // MARK: - shouldShowRenewalReminder Tests

     func test_shouldShowRenewalReminder_whenExpiresIn7Days_returnsTrue() {
         mockDateProvider.setNow(year: 2024, month: 6, day: 1)
         let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 8)

         XCTAssertTrue(sut.shouldShowRenewalReminder(subscription))
     }

     func test_shouldShowRenewalReminder_whenExpiresIn8Days_returnsFalse() {
         mockDateProvider.setNow(year: 2024, month: 6, day: 1)
         let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 9)

         XCTAssertFalse(sut.shouldShowRenewalReminder(subscription))
     }

     func test_shouldShowRenewalReminder_whenExpiresToday_returnsFalse() {
         mockDateProvider.setNow(year: 2024, month: 6, day: 1)
         let subscription = makeSubscription(expiresYear: 2024, expiresMonth: 6, expiresDay: 1)

         XCTAssertFalse(sut.shouldShowRenewalReminder(subscription))
     }

     // MARK: - Helpers

     func makeSubscription(expiresYear: Int, expiresMonth: Int, expiresDay: Int) -> Subscription {
         var components = DateComponents()
         components.year = expiresYear
         components.month = expiresMonth
         components.day = expiresDay
         components.hour = 23
         components.minute = 59
         let expirationDate = Calendar.current.date(from: components)!

         return Subscription(
             id: "test_sub",
             planName: "Pro",
             expirationDate: expirationDate,
             createdAt: Date().addingTimeInterval(-86400 * 30)
         )
     }
 }

 */

#Preview {
    NavigationStack {
        DateTimeExerciseView()
    }
}
