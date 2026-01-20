import Testing
import Foundation
@testable import TestabilityWorkshop

// MARK: - Swift Testing Example
// This file demonstrates the same tests as WeatherManagerTests but using Swift Testing syntax.
// Compare with AsyncTestingExerciseTests.swift to see the differences.

@Suite("Weather Manager")
struct WeatherManagerSwiftTests {

    // MARK: - Setup via init (replaces setUp/tearDown)

    let mockService: MockWeatherService
    let sut: WeatherManager

    init() {
        mockService = MockWeatherService()
        sut = WeatherManager(service: mockService, cacheExpirationSeconds: 300)
    }

    // MARK: - Basic Fetch Tests

    @Test("Calls service when fetching weather")
    func callsService() async throws {
        _ = try await sut.getWeather(for: "London")

        #expect(mockService.fetchCurrentWeatherCallCount == 1)
    }

    @Test("Passes correct city to service")
    func passesCorrectCity() async throws {
        _ = try await sut.getWeather(for: "Tokyo")

        #expect(mockService.requestedCities == ["Tokyo"])
    }

    @Test("Returns weather from service")
    func returnsWeather() async throws {
        let expectedWeather = Weather(
            city: "Paris",
            temperature: 68,
            condition: "Cloudy",
            humidity: 65,
            date: Date()
        )
        mockService.weatherToReturn = expectedWeather

        let weather = try await sut.getWeather(for: "Paris")

        #expect(weather.city == expectedWeather.city)
        #expect(weather.temperature == expectedWeather.temperature)
        #expect(weather.condition == expectedWeather.condition)
    }

    // MARK: - Error Handling (so much cleaner!)

    @Test("Propagates cityNotFound error")
    func propagatesCityNotFound() async {
        mockService.errorToThrow = WeatherError.cityNotFound

        await #expect(throws: WeatherError.cityNotFound) {
            try await sut.getWeather(for: "FakeCity")
        }
    }

    @Test("Propagates network error")
    func propagatesNetworkError() async {
        mockService.errorToThrow = WeatherError.networkError

        await #expect(throws: WeatherError.networkError) {
            try await sut.getWeather(for: "London")
        }
    }

    // MARK: - Caching Tests

    @Test("Caches fresh data")
    func cachesFreshData() async throws {
        _ = try await sut.getWeather(for: "Tokyo")
        _ = try await sut.getWeather(for: "Tokyo")

        #expect(mockService.fetchCurrentWeatherCallCount == 1)
    }

    @Test("Caches different cities separately")
    func cachesDifferentCities() async throws {
        _ = try await sut.getWeather(for: "London")
        _ = try await sut.getWeather(for: "Paris")
        _ = try await sut.getWeather(for: "London")
        _ = try await sut.getWeather(for: "Paris")

        #expect(mockService.fetchCurrentWeatherCallCount == 2)
    }

    @Test("Force refresh bypasses cache")
    func forceRefreshBypassesCache() async throws {
        _ = try await sut.getWeather(for: "Berlin")
        _ = try await sut.getWeather(for: "Berlin", forceRefresh: true)

        #expect(mockService.fetchCurrentWeatherCallCount == 2)
    }

    // MARK: - Parameterized Tests (Swift Testing exclusive feature!)

    @Test("Fetches weather for various cities", arguments: ["NYC", "LA", "Tokyo", "London", "Paris"])
    func fetchesForCity(city: String) async throws {
        let weather = try await sut.getWeather(for: city)

        #expect(weather.city == city)
    }

    @Test("Handles empty city gracefully", arguments: ["", " ", "   "])
    func handlesEmptyCity(city: String) async {
        // This test runs 3 times with different empty/whitespace inputs
        // In XCTest you'd need 3 separate test methods
        mockService.errorToThrow = WeatherError.cityNotFound

        await #expect(throws: WeatherError.cityNotFound) {
            try await sut.getWeather(for: city)
        }
    }

    // MARK: - Multiple Cities Tests

    @Test("Fetches all cities concurrently")
    func fetchesAllCities() async {
        let results = await sut.getWeatherForMultipleCities(["A", "B", "C"])

        #expect(results.count == 3)
        #expect(mockService.fetchCurrentWeatherCallCount == 3)
    }

    @Test("Returns empty for empty input")
    func handlesEmptyArray() async {
        let results = await sut.getWeatherForMultipleCities([])

        #expect(results.isEmpty)
        #expect(mockService.fetchCurrentWeatherCallCount == 0)
    }
}

// MARK: - Nested Suite Example

@Suite("Search Manager")
struct SearchManagerSwiftTests {

    @Suite("Basic Search")
    struct BasicSearchTests {
        let mockService = MockSearchService()

        @Test("Calls service with query")
        func callsService() async throws {
            mockService.resultsToReturn = ["result1"]
            let sut = SearchManager(searchService: mockService)

            _ = try await sut.search(query: "test query")

            #expect(mockService.searchedQueries == ["test query"])
        }

        @Test("Returns results from service")
        func returnsResults() async throws {
            mockService.resultsToReturn = ["Apple", "Apricot", "Avocado"]
            let sut = SearchManager(searchService: mockService)

            let results = try await sut.search(query: "A")

            #expect(results == ["Apple", "Apricot", "Avocado"])
        }
    }

    @Suite("Error Handling")
    struct ErrorHandlingTests {

        @Test("Propagates service error")
        func propagatesError() async {
            let mockService = MockSearchService()
            mockService.errorToThrow = NSError(domain: "SearchError", code: 500)
            let sut = SearchManager(searchService: mockService)

            await #expect {
                try await sut.search(query: "test")
            } throws: { error in
                (error as NSError).code == 500
            }
        }
    }
}

// MARK: - Tags Example

extension Tag {
    @Tag static var networking: Self
    @Tag static var caching: Self
    @Tag static var slow: Self
}

@Suite("Tagged Tests Example")
struct TaggedTests {

    @Test(.tags(.networking))
    func networkingTest() async {
        // This test can be filtered to run only networking tests
        #expect(true)
    }

    @Test(.tags(.caching))
    func cachingTest() {
        #expect(true)
    }

    @Test(.tags(.networking, .slow))
    func slowNetworkTest() async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(true)
    }
}
