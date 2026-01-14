import SwiftUI
import Foundation

// MARK: - Exercise: Decouple network layer for testability
// The "Before" code makes real URLSession calls, making tests slow and flaky
//
// Try it yourself: Delete from line 91 (// MARK: - AFTER) onwards and refactor
// ProductServiceBefore to be testable. Goal: make NetworkCouplingExerciseTests.swift pass.

struct NetworkCouplingExerciseView: View {
    var body: some View {
        List {
            Section {
                Text("The Before code directly uses URLSession. The After version abstracts networking behind a protocol.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Problems with Direct URLSession") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Tests require network connectivity")
                    Text("• Tests are slow (real HTTP calls)")
                    Text("• Can't test error scenarios reliably")
                    Text("• Flaky tests due to network issues")
                }
                .font(.caption)
            }

            Section("Key Refactoring Steps") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Create HTTPClient protocol")
                    Text("2. Extract URLSession usage behind protocol")
                    Text("3. Create MockHTTPClient for tests")
                    Text("4. Inject client via initializer")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Network Coupling")
    }
}

// MARK: - BEFORE: Untestable Code

struct ProductDTO: Codable {
    let id: Int
    let name: String
    let price: Double
}

// ❌ UNTESTABLE: Direct URLSession usage
class ProductServiceBefore {
    private let baseURL = "https://api.example.com"

    func fetchProducts() async throws -> [ProductDTO] {
        // ❌ Direct URLSession - can't mock responses
        let url = URL(string: "\(baseURL)/products")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode([ProductDTO].self, from: data)
    }

    func fetchProduct(id: Int) async throws -> ProductDTO {
        let url = URL(string: "\(baseURL)/products/\(id)")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(ProductDTO.self, from: data)
        case 404:
            throw NetworkError.notFound
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
}

enum NetworkError: Error, Equatable {
    case invalidResponse
    case notFound
    case serverError(Int)
    case decodingError
}

// MARK: - AFTER: Testable Code

// Step 1: Define HTTP client protocol
protocol HTTPClient {
    func data(from url: URL) async throws -> (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// Step 2: Make URLSession conform to protocol
extension URLSession: HTTPClient {}

// Step 3: Refactored service with injected client
// ✅ TESTABLE: HTTPClient is injected
class ProductServiceAfter {
    private let baseURL: String
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder

    init(
        baseURL: String = "https://api.example.com",
        httpClient: HTTPClient = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.decoder = decoder
    }

    func fetchProducts() async throws -> [ProductDTO] {
        let url = URL(string: "\(baseURL)/products")!
        let (data, response) = try await httpClient.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        do {
            return try decoder.decode([ProductDTO].self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    func fetchProduct(id: Int) async throws -> ProductDTO {
        let url = URL(string: "\(baseURL)/products/\(id)")!
        let (data, response) = try await httpClient.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                return try decoder.decode(ProductDTO.self, from: data)
            } catch {
                throw NetworkError.decodingError
            }
        case 404:
            throw NetworkError.notFound
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - Example Tests
/*

 // Mock HTTP Client
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

     // Helper to set up mock response
     func setResponse(statusCode: Int) {
         responseToReturn = HTTPURLResponse(
             url: URL(string: "https://test.com")!,
             statusCode: statusCode,
             httpVersion: nil,
             headerFields: nil
         )!
     }
 }

 // Test class
 class ProductServiceTests: XCTestCase {

     var mockClient: MockHTTPClient!
     var sut: ProductServiceAfter!

     override func setUp() {
         mockClient = MockHTTPClient()
         sut = ProductServiceAfter(httpClient: mockClient)
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
     }

     func test_fetchProducts_whenServerReturns500_throwsServerError() async {
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

     func test_fetchProduct_usesCorrectURL() async throws {
         // Arrange
         let product = ProductDTO(id: 42, name: "Test", price: 10)
         mockClient.dataToReturn = try JSONEncoder().encode(product)

         // Act
         _ = try await sut.fetchProduct(id: 42)

         // Assert
         XCTAssertEqual(mockClient.requestedURLs.first?.absoluteString, "https://api.example.com/products/42")
     }
 }

 */

#Preview {
    NavigationStack {
        NetworkCouplingExerciseView()
    }
}
