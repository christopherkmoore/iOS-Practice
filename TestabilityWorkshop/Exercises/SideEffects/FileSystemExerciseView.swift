import SwiftUI
import Foundation

// MARK: - Exercise: Make file system access testable
// Direct FileManager access makes tests slow and requires cleanup

struct FileSystemExerciseView: View {
    var body: some View {
        List {
            Section {
                Text("Direct FileManager access creates real files, making tests slow and requiring careful cleanup.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Problems with Direct Access") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Tests create real files on disk")
                    Text("• Forgotten cleanup leaves artifacts")
                    Text("• Tests can interfere with each other")
                    Text("• I/O makes tests slow")
                }
                .font(.caption)
            }

            Section("Key Refactoring Steps") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Create FileSystem protocol")
                    Text("2. Wrap FileManager in protocol")
                    Text("3. Create InMemoryFileSystem for tests")
                    Text("4. Inject file system dependency")
                }
                .font(.caption)
            }
        }
        .navigationTitle("File System Access")
    }
}

// MARK: - BEFORE: Untestable Code

struct CachedImage: Codable {
    let id: String
    let data: Data
    let cachedAt: Date
}

// ❌ UNTESTABLE: Direct FileManager access
class ImageCacheManagerBefore {
    private let cacheDirectory: URL

    init() {
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func cacheImage(id: String, data: Data) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).cache")
        let cached = CachedImage(id: id, data: data, cachedAt: Date())
        let encodedData = try JSONEncoder().encode(cached)
        try encodedData.write(to: fileURL)
    }

    func getCachedImage(id: String) -> CachedImage? {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).cache")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL),
              let cached = try? JSONDecoder().decode(CachedImage.self, from: data) else {
            return nil
        }

        return cached
    }

    func deleteCachedImage(id: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).cache")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    func clearCache() throws {
        let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    func cacheSize() -> Int64 {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
}

// MARK: - AFTER: Testable Code

// Step 1: Define file system protocol
protocol FileSystemProtocol {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func write(_ data: Data, to url: URL) throws
    func read(from url: URL) throws -> Data
    func removeItem(at url: URL) throws
    func contentsOfDirectory(at url: URL) throws -> [URL]
}

// Step 2: FileManager wrapper
class SystemFileSystem: FileSystemProtocol {
    private let fileManager = FileManager.default

    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }

    func write(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }

    func read(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }
}

// ✅ TESTABLE: File system is injected
class ImageCacheManagerAfter {
    private let fileSystem: FileSystemProtocol
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        fileSystem: FileSystemProtocol = SystemFileSystem(),
        cacheDirectory: URL? = nil
    ) {
        self.fileSystem = fileSystem

        if let dir = cacheDirectory {
            self.cacheDirectory = dir
        } else {
            let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            self.cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        }

        try? fileSystem.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
    }

    func cacheImage(id: String, data: Data) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).cache")
        let cached = CachedImage(id: id, data: data, cachedAt: Date())
        let encodedData = try encoder.encode(cached)
        try fileSystem.write(encodedData, to: fileURL)
    }

    func getCachedImage(id: String) -> CachedImage? {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).cache")

        guard fileSystem.fileExists(atPath: fileURL.path) else {
            return nil
        }

        guard let data = try? fileSystem.read(from: fileURL),
              let cached = try? decoder.decode(CachedImage.self, from: data) else {
            return nil
        }

        return cached
    }

    func deleteCachedImage(id: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(id).cache")
        if fileSystem.fileExists(atPath: fileURL.path) {
            try fileSystem.removeItem(at: fileURL)
        }
    }

    func clearCache() throws {
        let contents = try fileSystem.contentsOfDirectory(at: cacheDirectory)
        for fileURL in contents {
            try fileSystem.removeItem(at: fileURL)
        }
    }
}

// MARK: - Example Tests
/*

 // In-memory file system for testing
 class InMemoryFileSystem: FileSystemProtocol {
     private var files: [String: Data] = [:]
     private var directories: Set<String> = []
     var writeError: Error?
     var readError: Error?

     func fileExists(atPath path: String) -> Bool {
         files[path] != nil
     }

     func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
         directories.insert(url.path)
     }

     func write(_ data: Data, to url: URL) throws {
         if let error = writeError { throw error }
         files[url.path] = data
     }

     func read(from url: URL) throws -> Data {
         if let error = readError { throw error }
         guard let data = files[url.path] else {
             throw NSError(domain: "FileNotFound", code: 404)
         }
         return data
     }

     func removeItem(at url: URL) throws {
         files.removeValue(forKey: url.path)
     }

     func contentsOfDirectory(at url: URL) throws -> [URL] {
         files.keys
             .filter { $0.hasPrefix(url.path) }
             .map { URL(fileURLWithPath: $0) }
     }

     func reset() {
         files.removeAll()
         directories.removeAll()
         writeError = nil
         readError = nil
     }
 }

 class ImageCacheManagerTests: XCTestCase {

     var fileSystem: InMemoryFileSystem!
     var sut: ImageCacheManagerAfter!
     let testDirectory = URL(fileURLWithPath: "/test/cache")

     override func setUp() {
         fileSystem = InMemoryFileSystem()
         sut = ImageCacheManagerAfter(fileSystem: fileSystem, cacheDirectory: testDirectory)
     }

     override func tearDown() {
         fileSystem.reset()
     }

     func test_cacheImage_storesDataInFileSystem() throws {
         // Arrange
         let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header

         // Act
         try sut.cacheImage(id: "test_image", data: imageData)

         // Assert
         let expectedPath = testDirectory.appendingPathComponent("test_image.cache").path
         XCTAssertTrue(fileSystem.fileExists(atPath: expectedPath))
     }

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
         let cached = sut.getCachedImage(id: "nonexistent")
         XCTAssertNil(cached)
     }

     func test_deleteCachedImage_removesFromFileSystem() throws {
         // Arrange
         try sut.cacheImage(id: "test_image", data: Data())

         // Act
         try sut.deleteCachedImage(id: "test_image")

         // Assert
         XCTAssertNil(sut.getCachedImage(id: "test_image"))
     }

     func test_cacheImage_whenWriteFails_throwsError() {
         // Arrange
         fileSystem.writeError = NSError(domain: "DiskFull", code: 507)

         // Act & Assert
         XCTAssertThrowsError(try sut.cacheImage(id: "test", data: Data()))
     }
 }

 */

#Preview {
    NavigationStack {
        FileSystemExerciseView()
    }
}
