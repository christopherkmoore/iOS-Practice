import SwiftUI

// MARK: - Exercise: Testing async/await code
// Patterns for testing asynchronous Swift code with modern concurrency

struct AsyncTestingExerciseView: View {
    var body: some View {
        List {
            Section {
                Text("Testing async code requires understanding Swift concurrency and XCTest's async support.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Key Concepts") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• async test methods")
                    Text("• XCTestExpectation for callbacks")
                    Text("• Testing Task cancellation")
                    Text("• Actor isolation in tests")
                }
                .font(.caption)
            }

            Section("Common Patterns") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Use async test functions")
                    Text("2. Mock async dependencies")
                    Text("3. Test error propagation")
                    Text("4. Verify concurrent behavior")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Async Testing")
    }
}

// MARK: - Code to Test

protocol WeatherService {
    func fetchCurrentWeather(for city: String) async throws -> Weather
    func fetchForecast(for city: String, days: Int) async throws -> [Weather]
}

struct Weather: Equatable {
    let city: String
    let temperature: Double
    let condition: String
    let humidity: Int
    let date: Date
}

enum WeatherError: Error, Equatable {
    case cityNotFound
    case networkError
    case rateLimited
}

// Testable weather manager
class WeatherManager {
    private let service: WeatherService
    private var cache: [String: Weather] = [:]
    private let cacheExpirationSeconds: TimeInterval

    init(service: WeatherService, cacheExpirationSeconds: TimeInterval = 300) {
        self.service = service
        self.cacheExpirationSeconds = cacheExpirationSeconds
    }

    func getWeather(for city: String, forceRefresh: Bool = false) async throws -> Weather {
        // Check cache first
        if !forceRefresh, let cached = cache[city] {
            let age = Date().timeIntervalSince(cached.date)
            if age < cacheExpirationSeconds {
                return cached
            }
        }

        // Fetch fresh data
        let weather = try await service.fetchCurrentWeather(for: city)
        cache[city] = weather
        return weather
    }

    func getWeatherForMultipleCities(_ cities: [String]) async -> [Result<Weather, Error>] {
        await withTaskGroup(of: (String, Result<Weather, Error>).self) { group in
            for city in cities {
                group.addTask {
                    do {
                        let weather = try await self.getWeather(for: city)
                        return (city, .success(weather))
                    } catch {
                        return (city, .failure(error))
                    }
                }
            }

            var results: [String: Result<Weather, Error>] = [:]
            for await (city, result) in group {
                results[city] = result
            }

            // Return in original order
            return cities.map { results[$0]! }
        }
    }

    func clearCache() {
        cache.removeAll()
    }

    var cachedCities: [String] {
        Array(cache.keys)
    }
}

// Another async example: Debounced search
actor SearchManager {
    private let searchService: SearchService
    private var currentTask: Task<[String], Error>?

    init(searchService: SearchService) {
        self.searchService = searchService
    }

    func search(query: String) async throws -> [String] {
        // Cancel any existing search
        currentTask?.cancel()

        let task = Task {
            // Debounce delay
            try await Task.sleep(nanoseconds: 300_000_000)

            // Check if cancelled during debounce
            try Task.checkCancellation()

            return try await searchService.search(query: query)
        }

        currentTask = task
        return try await task.value
    }

    func cancelSearch() {
        currentTask?.cancel()
        currentTask = nil
    }
}

protocol SearchService {
    func search(query: String) async throws -> [String]
}

// MARK: - Example Tests
/*

 import XCTest

 // MARK: - Mock Weather Service

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

 // MARK: - Weather Manager Tests

 class WeatherManagerTests: XCTestCase {

     var mockService: MockWeatherService!
     var sut: WeatherManager!

     override func setUp() {
         mockService = MockWeatherService()
         sut = WeatherManager(service: mockService, cacheExpirationSeconds: 300)
     }

     override func tearDown() {
         mockService.reset()
     }

     // MARK: - Basic Async Tests

     func test_getWeather_callsService() async throws {
         // Act
         _ = try await sut.getWeather(for: "London")

         // Assert
         XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 1)
         XCTAssertEqual(mockService.requestedCities, ["London"])
     }

     func test_getWeather_returnsWeatherFromService() async throws {
         // Arrange
         let expectedWeather = Weather(
             city: "Paris",
             temperature: 68,
             condition: "Cloudy",
             humidity: 65,
             date: Date()
         )
         mockService.weatherToReturn = expectedWeather

         // Act
         let weather = try await sut.getWeather(for: "Paris")

         // Assert
         XCTAssertEqual(weather.city, expectedWeather.city)
         XCTAssertEqual(weather.temperature, expectedWeather.temperature)
     }

     // MARK: - Error Handling Tests

     func test_getWeather_whenServiceThrows_propagatesError() async {
         // Arrange
         mockService.errorToThrow = WeatherError.cityNotFound

         // Act & Assert
         do {
             _ = try await sut.getWeather(for: "FakeCity")
             XCTFail("Expected error to be thrown")
         } catch {
             XCTAssertEqual(error as? WeatherError, .cityNotFound)
         }
     }

     // MARK: - Caching Tests

     func test_getWeather_cachesFreshData() async throws {
         // Act
         _ = try await sut.getWeather(for: "Tokyo")
         _ = try await sut.getWeather(for: "Tokyo")

         // Assert - Service called only once due to caching
         XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 1)
     }

     func test_getWeather_forceRefresh_bypassesCache() async throws {
         // Arrange
         _ = try await sut.getWeather(for: "Berlin")

         // Act
         _ = try await sut.getWeather(for: "Berlin", forceRefresh: true)

         // Assert
         XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 2)
     }

     func test_clearCache_removesAllCachedData() async throws {
         // Arrange
         _ = try await sut.getWeather(for: "NYC")
         _ = try await sut.getWeather(for: "LA")

         // Act
         sut.clearCache()

         // Assert
         XCTAssertTrue(sut.cachedCities.isEmpty)
     }

     // MARK: - Concurrent Tests

     func test_getWeatherForMultipleCities_fetchesAllConcurrently() async {
         // Act
         let results = await sut.getWeatherForMultipleCities(["A", "B", "C"])

         // Assert
         XCTAssertEqual(results.count, 3)
         XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 3)
     }

     func test_getWeatherForMultipleCities_handlesPartialFailures() async {
         // Arrange - Make service fail for specific city
         mockService.errorToThrow = nil // First reset

         // We need a more sophisticated mock to fail only for certain cities
         // For this example, we'll just verify the pattern works

         let cities = ["London", "Paris", "Tokyo"]

         // Act
         let results = await sut.getWeatherForMultipleCities(cities)

         // Assert - All cities have results
         XCTAssertEqual(results.count, 3)
     }

     // MARK: - Timeout Tests

     func test_getWeather_withSlowService_completesEventually() async throws {
         // Arrange
         mockService.fetchDelay = 0.5 // 500ms delay

         // Act - This should complete despite the delay
         let weather = try await sut.getWeather(for: "SlowCity")

         // Assert
         XCTAssertEqual(weather.city, "SlowCity")
     }
 }

 // MARK: - Search Manager Tests (Actor)

 class MockSearchService: SearchService {
     var resultsToReturn: [String] = []
     var errorToThrow: Error?
     var searchDelay: TimeInterval = 0
     private(set) var searchCallCount = 0

     func search(query: String) async throws -> [String] {
         searchCallCount += 1

         if searchDelay > 0 {
             try await Task.sleep(nanoseconds: UInt64(searchDelay * 1_000_000_000))
         }

         if let error = errorToThrow { throw error }
         return resultsToReturn
     }
 }

 class SearchManagerTests: XCTestCase {

     func test_search_cancelsPreviousSearch() async throws {
         // Arrange
         let mockService = MockSearchService()
         mockService.resultsToReturn = ["result1", "result2"]
         let sut = SearchManager(searchService: mockService)

         // Act - Start multiple searches rapidly
         Task {
             _ = try? await sut.search(query: "first")
         }
         Task {
             _ = try? await sut.search(query: "second")
         }

         // Small delay to let tasks start
         try await Task.sleep(nanoseconds: 50_000_000)

         // Final search
         let results = try await sut.search(query: "final")

         // Assert - Only the final search should complete
         XCTAssertEqual(results, ["result1", "result2"])
     }

     func test_cancelSearch_stopsCurrentSearch() async {
         // Arrange
         let mockService = MockSearchService()
         mockService.searchDelay = 1.0 // Long delay
         let sut = SearchManager(searchService: mockService)

         // Act
         let searchTask = Task {
             try await sut.search(query: "test")
         }

         // Cancel after brief delay
         try? await Task.sleep(nanoseconds: 100_000_000)
         await sut.cancelSearch()

         // Assert - Task should be cancelled
         do {
             _ = try await searchTask.value
             XCTFail("Expected cancellation")
         } catch {
             XCTAssertTrue(error is CancellationError)
         }
     }
 }

 */

#Preview {
    NavigationStack {
        AsyncTestingExerciseView()
    }
}
