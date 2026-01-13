import XCTest
@testable import TestabilityWorkshop

final class ProductServiceTests: XCTestCase {

    var mockClient: MockHTTPClient!
    var sut: ProductServiceAfter!

    override func setUp() {
        super.setUp()
        mockClient = MockHTTPClient()
        sut = ProductServiceAfter(httpClient: mockClient)
    }

    override func tearDown() {
        mockClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - fetchProducts Tests

    func test_fetchProducts_callsCorrectURL() async throws {
        // Arrange
        let products = [ProductDTO(id: 1, name: "Test", price: 10)]
        mockClient.dataToReturn = try JSONEncoder().encode(products)

        // Act
        _ = try await sut.fetchProducts()

        // Assert
        XCTAssertEqual(mockClient.requestedURLs.count, 1)
        XCTAssertTrue(mockClient.requestedURLs[0].absoluteString.contains("/products"))
    }

    func test_fetchProducts_returnsDecodedProducts() async throws {
        // Arrange
        let expectedProducts = [
            ProductDTO(id: 1, name: "iPhone", price: 999),
            ProductDTO(id: 2, name: "MacBook", price: 1999)
        ]
        mockClient.dataToReturn = try JSONEncoder().encode(expectedProducts)

        // Act
        let products = try await sut.fetchProducts()

        // Assert
        XCTAssertEqual(products.count, 2)
        XCTAssertEqual(products[0].name, "iPhone")
        XCTAssertEqual(products[1].name, "MacBook")
    }

    func test_fetchProducts_whenServerReturns500_throwsInvalidResponse() async {
        // Arrange
        mockClient.setResponse(statusCode: 500)

        // Act & Assert
        do {
            _ = try await sut.fetchProducts()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .invalidResponse)
        }
    }

    func test_fetchProducts_whenInvalidJSON_throwsDecodingError() async {
        // Arrange
        mockClient.dataToReturn = "invalid json".data(using: .utf8)!

        // Act & Assert
        do {
            _ = try await sut.fetchProducts()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .decodingError)
        }
    }

    func test_fetchProducts_whenNetworkFails_propagatesError() async {
        // Arrange
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        // Act & Assert
        do {
            _ = try await sut.fetchProducts()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    // MARK: - fetchProduct(id:) Tests

    func test_fetchProduct_usesCorrectURL() async throws {
        // Arrange
        let product = ProductDTO(id: 42, name: "Test", price: 10)
        mockClient.dataToReturn = try JSONEncoder().encode(product)

        // Act
        _ = try await sut.fetchProduct(id: 42)

        // Assert
        XCTAssertEqual(mockClient.requestedURLs.first?.absoluteString, "https://api.example.com/products/42")
    }

    func test_fetchProduct_returnsDecodedProduct() async throws {
        // Arrange
        let expectedProduct = ProductDTO(id: 1, name: "AirPods", price: 249)
        mockClient.dataToReturn = try JSONEncoder().encode(expectedProduct)

        // Act
        let product = try await sut.fetchProduct(id: 1)

        // Assert
        XCTAssertEqual(product.name, "AirPods")
        XCTAssertEqual(product.price, 249)
    }

    func test_fetchProduct_whenNotFound_throwsNotFoundError() async {
        // Arrange
        mockClient.setResponse(statusCode: 404)

        // Act & Assert
        do {
            _ = try await sut.fetchProduct(id: 999)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .notFound)
        }
    }

    func test_fetchProduct_whenServerError_throwsServerError() async {
        // Arrange
        mockClient.setResponse(statusCode: 503)

        // Act & Assert
        do {
            _ = try await sut.fetchProduct(id: 1)
            XCTFail("Expected error to be thrown")
        } catch {
            if case NetworkError.serverError(let code) = error {
                XCTAssertEqual(code, 503)
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        }
    }

    // MARK: - Custom Base URL Tests

    func test_customBaseURL_isUsedInRequests() async throws {
        // Arrange
        let customSUT = ProductServiceAfter(
            baseURL: "https://staging.api.example.com",
            httpClient: mockClient
        )
        let product = ProductDTO(id: 1, name: "Test", price: 10)
        mockClient.dataToReturn = try JSONEncoder().encode(product)

        // Act
        _ = try await customSUT.fetchProduct(id: 1)

        // Assert
        XCTAssertTrue(mockClient.requestedURLs[0].absoluteString.contains("staging.api.example.com"))
    }
}
