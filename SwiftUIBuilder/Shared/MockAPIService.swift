import Foundation

// MARK: - Models

struct User: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let email: String
    let company: String
    let avatarURL: String

    static let samples: [User] = [
        User(id: 1, name: "Alice Johnson", email: "alice@example.com", company: "TechCorp", avatarURL: "person.circle.fill"),
        User(id: 2, name: "Bob Smith", email: "bob@example.com", company: "DataInc", avatarURL: "person.circle.fill"),
        User(id: 3, name: "Carol Williams", email: "carol@example.com", company: "CloudBase", avatarURL: "person.circle.fill"),
        User(id: 4, name: "David Brown", email: "david@example.com", company: "TechCorp", avatarURL: "person.circle.fill"),
        User(id: 5, name: "Eva Martinez", email: "eva@example.com", company: "StartupXYZ", avatarURL: "person.circle.fill"),
        User(id: 6, name: "Frank Wilson", email: "frank@example.com", company: "DataInc", avatarURL: "person.circle.fill"),
        User(id: 7, name: "Grace Lee", email: "grace@example.com", company: "CloudBase", avatarURL: "person.circle.fill"),
        User(id: 8, name: "Henry Taylor", email: "henry@example.com", company: "TechCorp", avatarURL: "person.circle.fill"),
        User(id: 9, name: "Ivy Chen", email: "ivy@example.com", company: "StartupXYZ", avatarURL: "person.circle.fill"),
        User(id: 10, name: "Jack Anderson", email: "jack@example.com", company: "DataInc", avatarURL: "person.circle.fill")
    ]
}

struct Post: Identifiable, Codable, Hashable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
    let likes: Int
    let createdAt: Date

    static let samples: [Post] = [
        Post(id: 1, userId: 1, title: "Getting Started with SwiftUI", body: "SwiftUI is Apple's modern framework for building user interfaces...", likes: 42, createdAt: Date().addingTimeInterval(-86400)),
        Post(id: 2, userId: 2, title: "Understanding Combine", body: "Combine is a powerful framework for handling asynchronous events...", likes: 38, createdAt: Date().addingTimeInterval(-172800)),
        Post(id: 3, userId: 1, title: "iOS Concurrency Deep Dive", body: "Modern iOS apps need to handle multiple tasks concurrently...", likes: 56, createdAt: Date().addingTimeInterval(-259200)),
        Post(id: 4, userId: 3, title: "Building Custom Views", body: "Learn how to create reusable custom views in SwiftUI...", likes: 29, createdAt: Date().addingTimeInterval(-345600)),
        Post(id: 5, userId: 4, title: "Testing Best Practices", body: "Writing testable code is essential for maintaining quality...", likes: 63, createdAt: Date().addingTimeInterval(-432000)),
        Post(id: 6, userId: 2, title: "Core Data Fundamentals", body: "Core Data provides a powerful persistence layer...", likes: 45, createdAt: Date().addingTimeInterval(-518400)),
        Post(id: 7, userId: 5, title: "Networking in Swift", body: "Modern networking using URLSession and async/await...", likes: 51, createdAt: Date().addingTimeInterval(-604800)),
        Post(id: 8, userId: 3, title: "Animation Techniques", body: "Creating beautiful animations with SwiftUI...", likes: 67, createdAt: Date().addingTimeInterval(-691200))
    ]
}

struct Photo: Identifiable, Hashable {
    let id: Int
    let title: String
    let thumbnailColor: String // Using SF Symbol colors for demo
    let category: String

    static let samples: [Photo] = [
        Photo(id: 1, title: "Mountain Sunrise", thumbnailColor: "orange", category: "Nature"),
        Photo(id: 2, title: "City Skyline", thumbnailColor: "blue", category: "Urban"),
        Photo(id: 3, title: "Forest Path", thumbnailColor: "green", category: "Nature"),
        Photo(id: 4, title: "Ocean Waves", thumbnailColor: "cyan", category: "Nature"),
        Photo(id: 5, title: "Street Art", thumbnailColor: "purple", category: "Urban"),
        Photo(id: 6, title: "Desert Dunes", thumbnailColor: "yellow", category: "Nature"),
        Photo(id: 7, title: "Night Market", thumbnailColor: "red", category: "Urban"),
        Photo(id: 8, title: "Autumn Leaves", thumbnailColor: "orange", category: "Nature"),
        Photo(id: 9, title: "Modern Architecture", thumbnailColor: "gray", category: "Urban"),
        Photo(id: 10, title: "Waterfall", thumbnailColor: "teal", category: "Nature"),
        Photo(id: 11, title: "Coffee Shop", thumbnailColor: "brown", category: "Urban"),
        Photo(id: 12, title: "Starry Night", thumbnailColor: "indigo", category: "Nature")
    ]
}

struct Product: Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String
    let price: Double
    let category: String
    let inStock: Bool

    static let samples: [Product] = [
        Product(id: 1, name: "iPhone 15 Pro", description: "Latest iPhone with titanium design", price: 999, category: "Electronics", inStock: true),
        Product(id: 2, name: "MacBook Air", description: "Lightweight laptop with M3 chip", price: 1099, category: "Electronics", inStock: true),
        Product(id: 3, name: "AirPods Pro", description: "Wireless earbuds with noise cancellation", price: 249, category: "Electronics", inStock: false),
        Product(id: 4, name: "iPad Pro", description: "Professional tablet with M4 chip", price: 799, category: "Electronics", inStock: true),
        Product(id: 5, name: "Apple Watch", description: "Smartwatch with health features", price: 399, category: "Wearables", inStock: true),
        Product(id: 6, name: "Magic Keyboard", description: "Wireless keyboard for Mac", price: 99, category: "Accessories", inStock: true),
        Product(id: 7, name: "Studio Display", description: "27-inch 5K display", price: 1599, category: "Electronics", inStock: false),
        Product(id: 8, name: "HomePod mini", description: "Smart speaker with Siri", price: 99, category: "Accessories", inStock: true)
    ]
}

// MARK: - Mock API Service

actor MockAPIService {
    static let shared = MockAPIService()

    private init() {}

    enum APIError: Error, LocalizedError {
        case networkError
        case notFound
        case serverError

        var errorDescription: String? {
            switch self {
            case .networkError: return "Network connection failed"
            case .notFound: return "Resource not found"
            case .serverError: return "Server error occurred"
            }
        }
    }

    // Simulate network delay
    private func simulateDelay() async throws {
        let delay = Double.random(in: 0.5...1.5)
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        // Randomly fail ~5% of requests to simulate real network conditions
        if Int.random(in: 1...20) == 1 {
            throw APIError.networkError
        }
    }

    // MARK: - User Endpoints

    func fetchUsers() async throws -> [User] {
        try await simulateDelay()
        return User.samples
    }

    func fetchUser(id: Int) async throws -> User {
        try await simulateDelay()
        guard let user = User.samples.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return user
    }

    func searchUsers(query: String) async throws -> [User] {
        try await simulateDelay()
        let lowercased = query.lowercased()
        return User.samples.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.email.lowercased().contains(lowercased) ||
            $0.company.lowercased().contains(lowercased)
        }
    }

    // MARK: - Post Endpoints

    func fetchPosts() async throws -> [Post] {
        try await simulateDelay()
        return Post.samples
    }

    func fetchPosts(forUserId userId: Int) async throws -> [Post] {
        try await simulateDelay()
        return Post.samples.filter { $0.userId == userId }
    }

    func fetchPost(id: Int) async throws -> Post {
        try await simulateDelay()
        guard let post = Post.samples.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return post
    }

    // MARK: - Photo Endpoints

    func fetchPhotos() async throws -> [Photo] {
        try await simulateDelay()
        return Photo.samples
    }

    func fetchPhotos(category: String) async throws -> [Photo] {
        try await simulateDelay()
        return Photo.samples.filter { $0.category == category }
    }

    // MARK: - Product Endpoints

    func fetchProducts() async throws -> [Product] {
        try await simulateDelay()
        return Product.samples
    }

    func fetchProducts(category: String) async throws -> [Product] {
        try await simulateDelay()
        return Product.samples.filter { $0.category == category }
    }

    func searchProducts(query: String) async throws -> [Product] {
        try await simulateDelay()
        let lowercased = query.lowercased()
        return Product.samples.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased)
        }
    }
}

// MARK: - Convenience Extensions

extension Color {
    init(named: String) {
        switch named {
        case "orange": self = .orange
        case "blue": self = .blue
        case "green": self = .green
        case "cyan": self = .cyan
        case "purple": self = .purple
        case "yellow": self = .yellow
        case "red": self = .red
        case "gray": self = .gray
        case "teal": self = .teal
        case "brown": self = .brown
        case "indigo": self = .indigo
        default: self = .gray
        }
    }
}

import SwiftUI
