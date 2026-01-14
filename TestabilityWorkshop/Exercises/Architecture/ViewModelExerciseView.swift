import SwiftUI
import Combine

// MARK: - Exercise: Test ViewModels properly
// Shows how to structure ViewModels for testability and how to test @Published properties
//
// Try it yourself: Delete from line 83 (// MARK: - AFTER) onwards and refactor
// ArticleListViewModelBefore to be testable. Goal: make ViewModelExerciseTests.swift pass.

struct ViewModelExerciseView: View {
    var body: some View {
        List {
            Section {
                Text("ViewModels with @Published properties require special testing techniques to verify state changes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Testing Challenges") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Testing async state changes")
                    Text("• Verifying @Published updates")
                    Text("• Testing error states")
                    Text("• Testing loading states")
                }
                .font(.caption)
            }

            Section("Key Patterns") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Inject all dependencies")
                    Text("2. Use XCTestExpectation for async")
                    Text("3. Collect @Published values")
                    Text("4. Test state transitions")
                }
                .font(.caption)
            }
        }
        .navigationTitle("ViewModel Testing")
    }
}

// MARK: - Domain Models

struct Article: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let content: String
    let author: String
    let publishedAt: Date
}

enum LoadingState<T: Equatable>: Equatable {
    case idle
    case loading
    case loaded(T)
    case error(String)
}

// MARK: - BEFORE: Hard to Test ViewModel

// ❌ HARD TO TEST: Direct dependencies, no way to inject mocks
class ArticleListViewModelBefore: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadArticles() async {
        isLoading = true
        errorMessage = nil

        // ❌ Direct URLSession call
        guard let url = URL(string: "https://api.example.com/articles") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            articles = try JSONDecoder().decode([Article].self, from: data)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - AFTER: Testable ViewModel

// Step 1: Define repository protocol
protocol ArticleRepository {
    func fetchArticles() async throws -> [Article]
    func fetchArticle(id: String) async throws -> Article
}

// Step 2: Create testable ViewModel
// ✅ TESTABLE: Dependencies injected, clear state management
@MainActor
class ArticleListViewModelAfter: ObservableObject {
    @Published private(set) var state: LoadingState<[Article]> = .idle
    @Published private(set) var selectedArticle: Article?

    private let repository: ArticleRepository

    // Computed properties for convenience
    var articles: [Article] {
        if case .loaded(let articles) = state {
            return articles
        }
        return []
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = state { return message }
        return nil
    }

    init(repository: ArticleRepository) {
        self.repository = repository
    }

    func loadArticles() async {
        state = .loading

        do {
            let articles = try await repository.fetchArticles()
            state = .loaded(articles)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func selectArticle(_ article: Article) {
        selectedArticle = article
    }

    func clearSelection() {
        selectedArticle = nil
    }

    func refresh() async {
        await loadArticles()
    }
}

// MARK: - Example Tests
/*

 import XCTest
 import Combine

 // Mock repository for testing
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

         if let error = errorToThrow {
             throw error
         }
         return articlesToReturn
     }

     func fetchArticle(id: String) async throws -> Article {
         fetchArticleCallCount += 1

         if let error = errorToThrow {
             throw error
         }
         return articleToReturn!
     }

     // Test data factory
     static func makeArticle(
         id: String = "1",
         title: String = "Test Article",
         content: String = "Test content"
     ) -> Article {
         Article(
             id: id,
             title: title,
             content: content,
             author: "Test Author",
             publishedAt: Date()
         )
     }
 }

 @MainActor
 class ArticleListViewModelTests: XCTestCase {

     var mockRepository: MockArticleRepository!
     var sut: ArticleListViewModelAfter!
     var cancellables: Set<AnyCancellable>!

     override func setUp() async throws {
         mockRepository = MockArticleRepository()
         sut = ArticleListViewModelAfter(repository: mockRepository)
         cancellables = []
     }

     // MARK: - Initial State Tests

     func test_initialState_isIdle() {
         XCTAssertEqual(sut.state, .idle)
         XCTAssertTrue(sut.articles.isEmpty)
         XCTAssertFalse(sut.isLoading)
         XCTAssertNil(sut.errorMessage)
     }

     // MARK: - loadArticles Tests

     func test_loadArticles_setsLoadingState() async {
         // Arrange
         mockRepository.fetchDelay = 0.1 // Small delay to capture loading state
         mockRepository.articlesToReturn = []

         // We need to observe state changes
         var states: [LoadingState<[Article]>] = []
         sut.$state
             .sink { states.append($0) }
             .store(in: &cancellables)

         // Act
         let task = Task {
             await sut.loadArticles()
         }

         // Give time for loading state to be set
         try? await Task.sleep(nanoseconds: 50_000_000)

         // Assert loading state was reached
         XCTAssertTrue(states.contains(.loading))

         await task.value
     }

     func test_loadArticles_success_setsLoadedState() async {
         // Arrange
         let expectedArticles = [
             MockArticleRepository.makeArticle(id: "1", title: "Article 1"),
             MockArticleRepository.makeArticle(id: "2", title: "Article 2")
         ]
         mockRepository.articlesToReturn = expectedArticles

         // Act
         await sut.loadArticles()

         // Assert
         XCTAssertEqual(sut.state, .loaded(expectedArticles))
         XCTAssertEqual(sut.articles.count, 2)
         XCTAssertFalse(sut.isLoading)
         XCTAssertNil(sut.errorMessage)
     }

     func test_loadArticles_failure_setsErrorState() async {
         // Arrange
         mockRepository.errorToThrow = NSError(
             domain: "TestError",
             code: 500,
             userInfo: [NSLocalizedDescriptionKey: "Server error"]
         )

         // Act
         await sut.loadArticles()

         // Assert
         if case .error(let message) = sut.state {
             XCTAssertEqual(message, "Server error")
         } else {
             XCTFail("Expected error state")
         }
         XCTAssertTrue(sut.articles.isEmpty)
         XCTAssertNotNil(sut.errorMessage)
     }

     func test_loadArticles_callsRepository() async {
         // Act
         await sut.loadArticles()

         // Assert
         XCTAssertEqual(mockRepository.fetchArticlesCallCount, 1)
     }

     // MARK: - Selection Tests

     func test_selectArticle_setsSelectedArticle() {
         // Arrange
         let article = MockArticleRepository.makeArticle()

         // Act
         sut.selectArticle(article)

         // Assert
         XCTAssertEqual(sut.selectedArticle, article)
     }

     func test_clearSelection_removesSelectedArticle() {
         // Arrange
         sut.selectArticle(MockArticleRepository.makeArticle())

         // Act
         sut.clearSelection()

         // Assert
         XCTAssertNil(sut.selectedArticle)
     }

     // MARK: - Refresh Tests

     func test_refresh_reloadsArticles() async {
         // Arrange
         mockRepository.articlesToReturn = [MockArticleRepository.makeArticle()]

         // Act
         await sut.refresh()
         await sut.refresh()

         // Assert - repository called twice
         XCTAssertEqual(mockRepository.fetchArticlesCallCount, 2)
     }
 }

 */

#Preview {
    NavigationStack {
        ViewModelExerciseView()
    }
}
