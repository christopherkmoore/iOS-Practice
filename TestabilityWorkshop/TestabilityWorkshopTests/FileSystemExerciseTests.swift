import XCTest
@testable import TestabilityWorkshop

final class ImageCacheManagerTests: XCTestCase {

    var fileSystem: InMemoryFileSystem!
    var sut: ImageCacheManagerAfter!
    let testDirectory = URL(fileURLWithPath: "/test/cache")

    override func setUp() {
        super.setUp()
        fileSystem = InMemoryFileSystem()
        sut = ImageCacheManagerAfter(fileSystem: fileSystem, cacheDirectory: testDirectory)
    }

    override func tearDown() {
        fileSystem.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - cacheImage Tests

    func test_cacheImage_storesDataInFileSystem() throws {
        // Arrange
        let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header

        // Act
        try sut.cacheImage(id: "test_image", data: imageData)

        // Assert
        let expectedPath = testDirectory.appendingPathComponent("test_image.cache").path
        XCTAssertTrue(fileSystem.fileExists(atPath: expectedPath))
    }

    func test_cacheImage_storesMultipleImages() throws {
        // Arrange & Act
        try sut.cacheImage(id: "image1", data: Data([0x01]))
        try sut.cacheImage(id: "image2", data: Data([0x02]))
        try sut.cacheImage(id: "image3", data: Data([0x03]))

        // Assert
        XCTAssertTrue(fileSystem.fileExists(atPath: testDirectory.appendingPathComponent("image1.cache").path))
        XCTAssertTrue(fileSystem.fileExists(atPath: testDirectory.appendingPathComponent("image2.cache").path))
        XCTAssertTrue(fileSystem.fileExists(atPath: testDirectory.appendingPathComponent("image3.cache").path))
    }

    func test_cacheImage_whenWriteFails_throwsError() {
        // Arrange
        fileSystem.writeError = NSError(domain: "DiskFull", code: 507, userInfo: nil)

        // Act & Assert
        XCTAssertThrowsError(try sut.cacheImage(id: "test", data: Data())) { error in
            XCTAssertEqual((error as NSError).code, 507)
        }
    }

    func test_cacheImage_overwritesExistingImage() throws {
        // Arrange
        let originalData = Data([0x01, 0x02, 0x03])
        let newData = Data([0x04, 0x05, 0x06])

        // Act
        try sut.cacheImage(id: "test_image", data: originalData)
        try sut.cacheImage(id: "test_image", data: newData)

        // Assert - Get the cached image and verify it has new data
        let cached = sut.getCachedImage(id: "test_image")
        XCTAssertEqual(cached?.data, newData)
    }

    // MARK: - getCachedImage Tests

    func test_getCachedImage_returnsStoredImage() throws {
        // Arrange
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        try sut.cacheImage(id: "test_image", data: imageData)

        // Act
        let cached = sut.getCachedImage(id: "test_image")

        // Assert
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.id, "test_image")
        XCTAssertEqual(cached?.data, imageData)
    }

    func test_getCachedImage_whenNotCached_returnsNil() {
        // Act
        let cached = sut.getCachedImage(id: "nonexistent")

        // Assert
        XCTAssertNil(cached)
    }

    func test_getCachedImage_includesCacheTimestamp() throws {
        // Arrange
        try sut.cacheImage(id: "test_image", data: Data())

        // Act
        let cached = sut.getCachedImage(id: "test_image")

        // Assert - Timestamp should be recent
        XCTAssertNotNil(cached?.cachedAt)
        let age = Date().timeIntervalSince(cached!.cachedAt)
        XCTAssertLessThan(age, 5.0) // Should be cached within last 5 seconds
    }

    // MARK: - deleteCachedImage Tests

    func test_deleteCachedImage_removesFromFileSystem() throws {
        // Arrange
        try sut.cacheImage(id: "test_image", data: Data())
        XCTAssertNotNil(sut.getCachedImage(id: "test_image")) // Verify it exists

        // Act
        try sut.deleteCachedImage(id: "test_image")

        // Assert
        XCTAssertNil(sut.getCachedImage(id: "test_image"))
    }

    func test_deleteCachedImage_whenNotExists_doesNotThrow() {
        // Act & Assert - Should not throw
        XCTAssertNoThrow(try sut.deleteCachedImage(id: "nonexistent"))
    }

    func test_deleteCachedImage_onlyDeletesSpecifiedImage() throws {
        // Arrange
        try sut.cacheImage(id: "image1", data: Data([0x01]))
        try sut.cacheImage(id: "image2", data: Data([0x02]))

        // Act
        try sut.deleteCachedImage(id: "image1")

        // Assert
        XCTAssertNil(sut.getCachedImage(id: "image1"))
        XCTAssertNotNil(sut.getCachedImage(id: "image2"))
    }

    // MARK: - clearCache Tests

    func test_clearCache_removesAllCachedImages() throws {
        // Arrange
        try sut.cacheImage(id: "image1", data: Data([0x01]))
        try sut.cacheImage(id: "image2", data: Data([0x02]))
        try sut.cacheImage(id: "image3", data: Data([0x03]))

        // Act
        try sut.clearCache()

        // Assert
        XCTAssertNil(sut.getCachedImage(id: "image1"))
        XCTAssertNil(sut.getCachedImage(id: "image2"))
        XCTAssertNil(sut.getCachedImage(id: "image3"))
    }

    func test_clearCache_whenEmpty_doesNotThrow() {
        // Act & Assert
        XCTAssertNoThrow(try sut.clearCache())
    }

    // MARK: - Edge Cases

    func test_cacheImage_withEmptyData() throws {
        // Arrange
        let emptyData = Data()

        // Act
        try sut.cacheImage(id: "empty_image", data: emptyData)

        // Assert
        let cached = sut.getCachedImage(id: "empty_image")
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.data, emptyData)
    }

    func test_cacheImage_withLargeData() throws {
        // Arrange
        let largeData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB

        // Act
        try sut.cacheImage(id: "large_image", data: largeData)

        // Assert
        let cached = sut.getCachedImage(id: "large_image")
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.data.count, 1024 * 1024)
    }

    func test_cacheImage_withSpecialCharactersInId() throws {
        // Arrange
        let imageData = Data([0x01])

        // Act & Assert - IDs with special characters should work
        try sut.cacheImage(id: "image-with-dashes", data: imageData)
        try sut.cacheImage(id: "image_with_underscores", data: imageData)

        XCTAssertNotNil(sut.getCachedImage(id: "image-with-dashes"))
        XCTAssertNotNil(sut.getCachedImage(id: "image_with_underscores"))
    }

    // MARK: - Read Error Tests

    func test_getCachedImage_whenReadFails_returnsNil() throws {
        // Arrange
        try sut.cacheImage(id: "test_image", data: Data([0x01]))
        fileSystem.readError = NSError(domain: "ReadError", code: 500, userInfo: nil)

        // Act
        let cached = sut.getCachedImage(id: "test_image")

        // Assert - Should return nil gracefully on read error
        XCTAssertNil(cached)
    }
}
