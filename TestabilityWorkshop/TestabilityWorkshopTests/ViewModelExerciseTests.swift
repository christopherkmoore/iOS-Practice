import XCTest
import Combine
@testable import TestabilityWorkshop

@MainActor
final class ArticleListViewModelTests: XCTestCase {

    var mockRepository: MockArticleRepository!
    var sut: ArticleListViewModelAfter!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        mockRepository = MockArticleRepository()
        sut = ArticleListViewModelAfter(repository: mockRepository)
        cancellables = []
    }

    override func tearDown() async throws {
        mockRepository.reset()
        sut = nil
        cancellables = nil
    }

    // MARK: - Initial State Tests

    func test_initialState_isIdle() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.articles.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.selectedArticle)
    }

    // MARK: - loadArticles Success Tests

    func test_loadArticles_callsRepository() async {
        // Act
        await sut.loadArticles()

        // Assert
        XCTAssertEqual(mockRepository.fetchArticlesCallCount, 1)
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

    func test_loadArticles_success_articlesAreAccessible() async {
        // Arrange
        mockRepository.articlesToReturn = [
            MockArticleRepository.makeArticle(id: "1", title: "First"),
            MockArticleRepository.makeArticle(id: "2", title: "Second"),
            MockArticleRepository.makeArticle(id: "3", title: "Third")
        ]

        // Act
        await sut.loadArticles()

        // Assert
        XCTAssertEqual(sut.articles[0].title, "First")
        XCTAssertEqual(sut.articles[1].title, "Second")
        XCTAssertEqual(sut.articles[2].title, "Third")
    }

    func test_loadArticles_withEmptyResult_hasEmptyArticles() async {
        // Arrange
        mockRepository.articlesToReturn = []

        // Act
        await sut.loadArticles()

        // Assert
        if case .loaded(let articles) = sut.state {
            XCTAssertTrue(articles.isEmpty)
        } else {
            XCTFail("Expected loaded state")
        }
        XCTAssertTrue(sut.articles.isEmpty)
    }

    // MARK: - loadArticles Error Tests

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
            XCTFail("Expected error state, got \(sut.state)")
        }
    }

    func test_loadArticles_failure_errorMessageIsAccessible() async {
        // Arrange
        mockRepository.errorToThrow = NSError(
            domain: "TestError",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Not found"]
        )

        // Act
        await sut.loadArticles()

        // Assert
        XCTAssertEqual(sut.errorMessage, "Not found")
    }

    func test_loadArticles_failure_articlesArrayIsEmpty() async {
        // Arrange
        mockRepository.errorToThrow = NSError(domain: "Test", code: 0, userInfo: nil)

        // Act
        await sut.loadArticles()

        // Assert
        XCTAssertTrue(sut.articles.isEmpty)
    }

    // MARK: - Loading State Tests

    func test_loadArticles_setsLoadingStateDuringFetch() async {
        // Arrange
        mockRepository.fetchDelay = 0.1
        mockRepository.articlesToReturn = []

        var observedStates: [LoadingState<[Article]>] = []
        sut.$state
            .sink { observedStates.append($0) }
            .store(in: &cancellables)

        // Act
        await sut.loadArticles()

        // Assert - Should have seen .loading state
        XCTAssertTrue(observedStates.contains(.loading))
    }

    func test_loadArticles_isLoadingTrueOnlyDuringFetch() async {
        // After completion, isLoading should be false
        mockRepository.articlesToReturn = [MockArticleRepository.makeArticle()]

        await sut.loadArticles()

        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Selection Tests

    func test_selectArticle_setsSelectedArticle() {
        // Arrange
        let article = MockArticleRepository.makeArticle(id: "123", title: "Selected")

        // Act
        sut.selectArticle(article)

        // Assert
        XCTAssertEqual(sut.selectedArticle, article)
    }

    func test_selectArticle_canChangeSelection() {
        // Arrange
        let article1 = MockArticleRepository.makeArticle(id: "1")
        let article2 = MockArticleRepository.makeArticle(id: "2")

        // Act
        sut.selectArticle(article1)
        sut.selectArticle(article2)

        // Assert
        XCTAssertEqual(sut.selectedArticle?.id, "2")
    }

    func test_clearSelection_removesSelectedArticle() {
        // Arrange
        sut.selectArticle(MockArticleRepository.makeArticle())
        XCTAssertNotNil(sut.selectedArticle)

        // Act
        sut.clearSelection()

        // Assert
        XCTAssertNil(sut.selectedArticle)
    }

    func test_clearSelection_whenNoSelection_doesNothing() {
        // Arrange - No article selected
        XCTAssertNil(sut.selectedArticle)

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

        // Assert
        XCTAssertEqual(mockRepository.fetchArticlesCallCount, 1)
    }

    func test_refresh_calledMultipleTimes_callsRepositoryEachTime() async {
        // Arrange
        mockRepository.articlesToReturn = [MockArticleRepository.makeArticle()]

        // Act
        await sut.refresh()
        await sut.refresh()
        await sut.refresh()

        // Assert
        XCTAssertEqual(mockRepository.fetchArticlesCallCount, 3)
    }

    func test_refresh_updatesArticles() async {
        // Arrange - First load
        mockRepository.articlesToReturn = [MockArticleRepository.makeArticle(title: "Old")]
        await sut.loadArticles()
        XCTAssertEqual(sut.articles.first?.title, "Old")

        // Act - Refresh with new data
        mockRepository.articlesToReturn = [MockArticleRepository.makeArticle(title: "New")]
        await sut.refresh()

        // Assert
        XCTAssertEqual(sut.articles.first?.title, "New")
    }

    // MARK: - State Transitions Tests

    func test_loadArticles_fromIdleToLoaded() async {
        // Arrange
        mockRepository.articlesToReturn = [MockArticleRepository.makeArticle()]
        XCTAssertEqual(sut.state, .idle)

        // Act
        await sut.loadArticles()

        // Assert
        if case .loaded = sut.state {
            // Success
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func test_loadArticles_fromErrorToLoaded_onRetry() async {
        // Arrange - First call fails
        mockRepository.errorToThrow = NSError(domain: "Test", code: 0, userInfo: nil)
        await sut.loadArticles()
        XCTAssertNotNil(sut.errorMessage)

        // Act - Retry succeeds
        mockRepository.errorToThrow = nil
        mockRepository.articlesToReturn = [MockArticleRepository.makeArticle()]
        await sut.loadArticles()

        // Assert
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.articles.count, 1)
    }
}
