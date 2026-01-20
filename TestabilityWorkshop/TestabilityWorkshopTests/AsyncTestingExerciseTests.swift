import XCTest
import Testing
@testable import TestabilityWorkshop

struct WeatherManagerTestsTesting {
    
    @Test("GET Weather calls service")
    func getWeatherCallsService() async throws {
        let mockService = MockWeatherService()
        let sut = WeatherManager(service: mockService, cacheExpirationSeconds: 300)
        
        _ = try await sut.getWeather(for: "London")
        
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 1)
    }
}


final class WeatherManagerTests: XCTestCase {

    var mockService: MockWeatherService!
    var sut: WeatherManager!

    override func setUp() {
        super.setUp()
        mockService = MockWeatherService()
        sut = WeatherManager(service: mockService, cacheExpirationSeconds: 300)
    }

    override func tearDown() {
        mockService.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Fetch Tests

    func test_getWeather_callsService() async throws {
        // Act
        _ = try await sut.getWeather(for: "London")

        // Assert
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 1)
    }

    func test_getWeather_passesCorrectCity() async throws {
        // Act
        _ = try await sut.getWeather(for: "Tokyo")

        // Assert
        XCTAssertEqual(mockService.requestedCities, ["Tokyo"])
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
        XCTAssertEqual(weather.condition, expectedWeather.condition)
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

    func test_getWeather_whenNetworkError_propagatesError() async {
        // Arrange
        mockService.errorToThrow = WeatherError.networkError

        // Act & Assert
        do {
            _ = try await sut.getWeather(for: "London")
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .networkError)
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

    func test_getWeather_cachesDifferentCitiesSeparately() async throws {
        // Act
        _ = try await sut.getWeather(for: "London")
        _ = try await sut.getWeather(for: "Paris")
        _ = try await sut.getWeather(for: "London")
        _ = try await sut.getWeather(for: "Paris")

        // Assert - Each city fetched once
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 2)
    }

    func test_getWeather_forceRefresh_bypassesCache() async throws {
        // Arrange
        _ = try await sut.getWeather(for: "Berlin")

        // Act
        _ = try await sut.getWeather(for: "Berlin", forceRefresh: true)

        // Assert
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 2)
    }

    func test_getWeather_forceRefresh_updatesCache() async throws {
        // Arrange - First fetch
        mockService.weatherToReturn = Weather(city: "NYC", temperature: 70, condition: "Sunny", humidity: 50, date: Date())
        _ = try await sut.getWeather(for: "NYC")

        // Change what service returns
        mockService.weatherToReturn = Weather(city: "NYC", temperature: 80, condition: "Hot", humidity: 40, date: Date())

        // Act - Force refresh
        let weather = try await sut.getWeather(for: "NYC", forceRefresh: true)

        // Assert - Should have new data
        XCTAssertEqual(weather.temperature, 80)
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

    func test_clearCache_causesNextFetchToCallService() async throws {
        // Arrange
        _ = try await sut.getWeather(for: "London")
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 1)

        // Act
        sut.clearCache()
        _ = try await sut.getWeather(for: "London")

        // Assert - Should have fetched again
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 2)
    }

    // MARK: - Multiple Cities Tests

    func test_getWeatherForMultipleCities_fetchesAllCities() async {
        // Act
        let results = await sut.getWeatherForMultipleCities(["A", "B", "C"])

        // Assert
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 3)
    }

    func test_getWeatherForMultipleCities_returnsResultsInOrder() async {
        // Arrange
        mockService.weatherToReturn = nil // Use default which includes city name

        // Act
        let results = await sut.getWeatherForMultipleCities(["London", "Paris", "Tokyo"])

        // Assert - Results should be in same order as input
        XCTAssertEqual(results.count, 3)

        if case .success(let london) = results[0] {
            XCTAssertEqual(london.city, "London")
        } else {
            XCTFail("Expected success for London")
        }

        if case .success(let paris) = results[1] {
            XCTAssertEqual(paris.city, "Paris")
        } else {
            XCTFail("Expected success for Paris")
        }

        if case .success(let tokyo) = results[2] {
            XCTAssertEqual(tokyo.city, "Tokyo")
        } else {
            XCTFail("Expected success for Tokyo")
        }
    }

    func test_getWeatherForMultipleCities_handlesEmptyArray() async {
        // Act
        let results = await sut.getWeatherForMultipleCities([])

        // Assert
        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 0)
    }

    // MARK: - Cache Expiration Tests

    func test_getWeather_withExpiredCache_fetchesFreshData() async throws {
        // Arrange - Create manager with very short cache expiration
        let shortCacheSUT = WeatherManager(service: mockService, cacheExpirationSeconds: 0.1)

        // First fetch
        _ = try await shortCacheSUT.getWeather(for: "London")
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 1)

        // Wait for cache to expire
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Act - Second fetch should hit service again
        _ = try await shortCacheSUT.getWeather(for: "London")

        // Assert
        XCTAssertEqual(mockService.fetchCurrentWeatherCallCount, 2)
    }

    // MARK: - Concurrent Fetch Tests

    func test_getWeatherForMultipleCities_fetchesConcurrently() async {
        // Arrange - Add delay to simulate network latency
        mockService.fetchDelay = 0.1

        let startTime = Date()

        // Act - Fetch 5 cities
        _ = await sut.getWeatherForMultipleCities(["A", "B", "C", "D", "E"])

        let elapsed = Date().timeIntervalSince(startTime)

        // Assert - If sequential, would take ~0.5s. Concurrent should be ~0.1s
        // Using 0.3s as threshold to account for test overhead
        XCTAssertLessThan(elapsed, 0.3)
    }

    // MARK: - cachedCities Tests

    func test_cachedCities_returnsEmptyInitially() {
        XCTAssertTrue(sut.cachedCities.isEmpty)
    }

    func test_cachedCities_returnsCachedCityNames() async throws {
        // Act
        _ = try await sut.getWeather(for: "London")
        _ = try await sut.getWeather(for: "Paris")

        // Assert
        XCTAssertEqual(Set(sut.cachedCities), Set(["London", "Paris"]))
    }
}

// MARK: - SearchManager Tests

final class SearchManagerTests: XCTestCase {

    func test_search_callsServiceWithQuery() async throws {
        // Arrange
        let mockService = MockSearchService()
        mockService.resultsToReturn = ["result1"]
        let sut = SearchManager(searchService: mockService)

        // Act
        _ = try await sut.search(query: "test query")

        // Assert
        XCTAssertEqual(mockService.searchedQueries, ["test query"])
    }

    func test_search_returnsResultsFromService() async throws {
        // Arrange
        let mockService = MockSearchService()
        mockService.resultsToReturn = ["Apple", "Apricot", "Avocado"]
        let sut = SearchManager(searchService: mockService)

        // Act
        let results = try await sut.search(query: "A")

        // Assert
        XCTAssertEqual(results, ["Apple", "Apricot", "Avocado"])
    }

    func test_search_propagatesServiceError() async {
        // Arrange
        let mockService = MockSearchService()
        mockService.errorToThrow = NSError(domain: "SearchError", code: 500, userInfo: nil)
        let sut = SearchManager(searchService: mockService)

        // Act & Assert
        do {
            _ = try await sut.search(query: "test")
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    func test_cancelSearch_stopsCurrentSearch() async {
        // Arrange
        let mockService = MockSearchService()
        mockService.searchDelay = 1.0 // Long delay
        let sut = SearchManager(searchService: mockService)

        // Act - Start search and immediately cancel
        let searchTask = Task {
            try await sut.search(query: "test")
        }

        // Small delay to let search start
        try? await Task.sleep(nanoseconds: 50_000_000)
        await sut.cancelSearch()

        // Assert
        do {
            _ = try await searchTask.value
            XCTFail("Expected cancellation error")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    func test_search_multipleRapidSearches_onlyLastCompletes() async throws {
        // Arrange
        let mockService = MockSearchService()
        mockService.resultsToReturn = ["final result"]
        mockService.searchDelay = 0.4 // Longer than debounce
        let sut = SearchManager(searchService: mockService)

        // Act - Start multiple searches rapidly
        // The first two should get cancelled by the debounce
        async let search1: [String] = {
            try? await sut.search(query: "first")
            return []
        }()

        try? await Task.sleep(nanoseconds: 50_000_000)

        async let search2: [String] = {
            try? await sut.search(query: "second")
            return []
        }()

        try? await Task.sleep(nanoseconds: 50_000_000)

        // This one should complete
        let finalResults = try await sut.search(query: "final")

        // Assert
        XCTAssertEqual(finalResults, ["final result"])
    }
}
