import Foundation
@testable import TestabilityWorkshop

// MARK: - Singleton Exercise Mocks

class MockAnalytics: AnalyticsTracking {
    var trackedEvents: [(event: String, properties: [String: Any]?)] = []

    func track(event: String, properties: [String: Any]?) {
        trackedEvents.append((event, properties))
    }

    var eventNames: [String] {
        trackedEvents.map { $0.event }
    }

    func reset() {
        trackedEvents = []
    }
}

class MockAuth: AuthenticationProviding {
    var currentUserId: String?
    var isAuthenticated: Bool { currentUserId != nil }

    func reset() {
        currentUserId = nil
    }
}

class MockUserProfileAPI: UserProfileFetching {
    var profileToReturn: UserProfileData?
    var errorToThrow: Error?
    var fetchCallCount = 0

    func fetchUserProfile(userId: String) async throws -> UserProfileData {
        fetchCallCount += 1
        if let error = errorToThrow { throw error }
        guard let profile = profileToReturn else {
            throw ProfileError.networkError
        }
        return profile
    }

    func reset() {
        profileToReturn = nil
        errorToThrow = nil
        fetchCallCount = 0
    }
}

// MARK: - Network Coupling Exercise Mocks

class MockHTTPClient: HTTPClient {
    var dataToReturn: Data = Data()
    var responseToReturn: URLResponse = HTTPURLResponse(
        url: URL(string: "https://test.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!
    var errorToThrow: Error?
    var requestedURLs: [URL] = []

    func data(from url: URL) async throws -> (Data, URLResponse) {
        requestedURLs.append(url)
        if let error = errorToThrow { throw error }
        return (dataToReturn, responseToReturn)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let url = request.url { requestedURLs.append(url) }
        if let error = errorToThrow { throw error }
        return (dataToReturn, responseToReturn)
    }

    func setResponse(statusCode: Int) {
        responseToReturn = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    func reset() {
        dataToReturn = Data()
        setResponse(statusCode: 200)
        errorToThrow = nil
        requestedURLs = []
    }
}

// MARK: - Date/Time Exercise Mocks

class MockDateProvider: DateProviding {
    var now: Date

    init(now: Date = Date()) {
        self.now = now
    }

    func setNow(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        now = Calendar.current.date(from: components)!
    }

    static func makeDate(year: Int, month: Int, day: Int, hour: Int = 23, minute: Int = 59) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }
}

// MARK: - UserDefaults Exercise Mocks

class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Any] = [:]

    func bool(forKey key: String) -> Bool {
        storage[key] as? Bool ?? false
    }

    func string(forKey key: String) -> String? {
        storage[key] as? String
    }

    func integer(forKey key: String) -> Int {
        storage[key] as? Int ?? 0
    }

    func setBool(_ value: Bool, forKey key: String) {
        storage[key] = value
    }

    func setString(_ value: String?, forKey key: String) {
        if let value = value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
    }

    func setInt(_ value: Int, forKey key: String) {
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    func reset() {
        storage.removeAll()
    }
}

// MARK: - File System Exercise Mocks

class InMemoryFileSystem: FileSystemProtocol {
    private var files: [String: Data] = [:]
    private var directories: Set<String> = []
    var writeError: Error?
    var readError: Error?

    func fileExists(atPath path: String) -> Bool {
        files[path] != nil
    }

    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        directories.insert(url.path)
    }

    func write(_ data: Data, to url: URL) throws {
        if let error = writeError { throw error }
        files[url.path] = data
    }

    func read(from url: URL) throws -> Data {
        if let error = readError { throw error }
        guard let data = files[url.path] else {
            throw NSError(domain: "FileNotFound", code: 404, userInfo: nil)
        }
        return data
    }

    func removeItem(at url: URL) throws {
        files.removeValue(forKey: url.path)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        files.keys
            .filter { $0.hasPrefix(url.path) && $0 != url.path }
            .map { URL(fileURLWithPath: $0) }
    }

    func reset() {
        files.removeAll()
        directories.removeAll()
        writeError = nil
        readError = nil
    }
}

// MARK: - ViewModel Exercise Mocks

class MockArticleRepository: ArticleRepository {
    var articlesToReturn: [Article] = []
    var articleToReturn: Article?
    var errorToThrow: Error?
    var fetchArticlesCallCount = 0
    var fetchArticleCallCount = 0
    var fetchDelay: TimeInterval = 0

    func fetchArticles() async throws -> [Article] {
        fetchArticlesCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if let error = errorToThrow { throw error }
        return articlesToReturn
    }

    func fetchArticle(id: String) async throws -> Article {
        fetchArticleCallCount += 1
        if let error = errorToThrow { throw error }
        guard let article = articleToReturn else {
            throw NSError(domain: "NotFound", code: 404, userInfo: nil)
        }
        return article
    }

    static func makeArticle(
        id: String = "1",
        title: String = "Test Article",
        content: String = "Test content",
        author: String = "Test Author"
    ) -> Article {
        Article(
            id: id,
            title: title,
            content: content,
            author: author,
            publishedAt: Date()
        )
    }

    func reset() {
        articlesToReturn = []
        articleToReturn = nil
        errorToThrow = nil
        fetchArticlesCallCount = 0
        fetchArticleCallCount = 0
        fetchDelay = 0
    }
}

// MARK: - Protocol Mocking Exercise Mocks

class MockEmailService: EmailService {
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

class MockPaymentProcessor: PaymentProcessor {
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

    func setDeclinedResponse(reason: String) {
        paymentResultToReturn = PaymentResult(
            transactionId: "txn_declined",
            status: .declined(reason: reason),
            processedAt: Date()
        )
    }

    func reset() {
        paymentResultToReturn = PaymentResult(transactionId: "txn_123", status: .success, processedAt: Date())
        refundResultToReturn = RefundResult(refundId: "ref_123", status: .processed)
        errorToThrow = nil
        processPaymentCalls = []
        refundCalls = []
    }
}

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

    func hasNotification(withId id: String) -> Bool {
        notifications[id] != nil
    }

    func reset() {
        notifications = [:]
        nextId = 1
        shouldThrowError = nil
    }
}

// MARK: - Async Testing Exercise Mocks

class MockWeatherService: WeatherService {
    var weatherToReturn: Weather?
    var forecastToReturn: [Weather] = []
    var errorToThrow: Error?
    var fetchDelay: TimeInterval = 0

    private(set) var fetchCurrentWeatherCallCount = 0
    private(set) var fetchForecastCallCount = 0
    private(set) var requestedCities: [String] = []

    func fetchCurrentWeather(for city: String) async throws -> Weather {
        fetchCurrentWeatherCallCount += 1
        requestedCities.append(city)

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if let error = errorToThrow { throw error }

        return weatherToReturn ?? Weather(
            city: city,
            temperature: 72,
            condition: "Sunny",
            humidity: 50,
            date: Date()
        )
    }

    func fetchForecast(for city: String, days: Int) async throws -> [Weather] {
        fetchForecastCallCount += 1
        if let error = errorToThrow { throw error }
        return forecastToReturn
    }

    func reset() {
        weatherToReturn = nil
        forecastToReturn = []
        errorToThrow = nil
        fetchDelay = 0
        fetchCurrentWeatherCallCount = 0
        fetchForecastCallCount = 0
        requestedCities = []
    }
}

class MockSearchService: SearchService {
    var resultsToReturn: [String] = []
    var errorToThrow: Error?
    var searchDelay: TimeInterval = 0
    private(set) var searchCallCount = 0
    private(set) var searchedQueries: [String] = []

    func search(query: String) async throws -> [String] {
        searchCallCount += 1
        searchedQueries.append(query)

        if searchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(searchDelay * 1_000_000_000))
        }

        if let error = errorToThrow { throw error }
        return resultsToReturn
    }

    func reset() {
        resultsToReturn = []
        errorToThrow = nil
        searchDelay = 0
        searchCallCount = 0
        searchedQueries = []
    }
}
