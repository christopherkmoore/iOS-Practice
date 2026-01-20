import Foundation

struct Flashcard: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let category: Category

    enum Category: String, CaseIterable {
        case swift = "Swift"
        case concurrency = "Concurrency"
        case testing = "Testing"
        case swiftui = "SwiftUI"
    }
}
