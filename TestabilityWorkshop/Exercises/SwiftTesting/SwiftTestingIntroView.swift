import SwiftUI

struct SwiftTestingIntroView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Intro
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Swift Testing is Apple's modern testing framework introduced at WWDC 2024. It's cleaner, more expressive, and built for Swift from the ground up.")
                            .font(.body)

                        Text("You can use both XCTest and Swift Testing in the same project - migrate gradually!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } label: {
                    Label("What is Swift Testing?", systemImage: "testtube.2")
                }

                // MARK: - Basic Structure
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("XCTest")
                            .font(.headline)
                            .foregroundColor(.red)

                        CodeBlock("""
                        import XCTest

                        class WeatherTests: XCTestCase {
                            func testFetchReturnsData() async {
                                // test code
                            }
                        }
                        """)

                        Divider()

                        Text("Swift Testing")
                            .font(.headline)
                            .foregroundColor(.green)

                        CodeBlock("""
                        import Testing

                        struct WeatherTests {
                            @Test func fetchReturnsData() async {
                                // test code
                            }
                        }
                        """)

                        CalloutBox(
                            "No inheritance required! Use struct instead of class, and @Test instead of the test prefix.",
                            type: .tip
                        )
                    }
                } label: {
                    Label("Basic Structure", systemImage: "square.on.square")
                }

                // MARK: - Assertions
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("XCTest")
                            .font(.headline)
                            .foregroundColor(.red)

                        CodeBlock("""
                        XCTAssertEqual(weather.temp, 72)
                        XCTAssertTrue(isLoaded)
                        XCTAssertNil(error)
                        XCTAssertNotNil(result)
                        XCTAssertGreaterThan(count, 0)
                        """)

                        Divider()

                        Text("Swift Testing")
                            .font(.headline)
                            .foregroundColor(.green)

                        CodeBlock("""
                        #expect(weather.temp == 72)
                        #expect(isLoaded)
                        #expect(error == nil)
                        #expect(result != nil)
                        #expect(count > 0)
                        """)

                        CalloutBox(
                            "#expect uses natural Swift expressions. No more remembering XCTAssertGreaterThanOrEqual!",
                            type: .tip
                        )
                    }
                } label: {
                    Label("Assertions", systemImage: "checkmark.circle")
                }

                // MARK: - Error Testing
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("XCTest")
                            .font(.headline)
                            .foregroundColor(.red)

                        CodeBlock("""
                        func testThrowsError() async {
                            do {
                                _ = try await service.fetch("bad")
                                XCTFail("Expected error")
                            } catch {
                                XCTAssertEqual(
                                    error as? MyError,
                                    .notFound
                                )
                            }
                        }
                        """)

                        Divider()

                        Text("Swift Testing")
                            .font(.headline)
                            .foregroundColor(.green)

                        CodeBlock("""
                        @Test func throwsError() async {
                            #expect(throws: MyError.notFound) {
                                try await service.fetch("bad")
                            }
                        }
                        """)

                        CalloutBox(
                            "One line instead of do/catch/XCTFail boilerplate!",
                            type: .tip
                        )
                    }
                } label: {
                    Label("Error Testing", systemImage: "exclamationmark.triangle")
                }

                // MARK: - Setup and Teardown
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("XCTest")
                            .font(.headline)
                            .foregroundColor(.red)

                        CodeBlock("""
                        class WeatherTests: XCTestCase {
                            var mock: MockService!
                            var sut: WeatherManager!

                            override func setUp() {
                                super.setUp()
                                mock = MockService()
                                sut = WeatherManager(service: mock)
                            }

                            override func tearDown() {
                                sut = nil
                                mock = nil
                                super.tearDown()
                            }
                        }
                        """)

                        Divider()

                        Text("Swift Testing")
                            .font(.headline)
                            .foregroundColor(.green)

                        CodeBlock("""
                        struct WeatherTests {
                            let mock: MockService
                            let sut: WeatherManager

                            init() {
                                mock = MockService()
                                sut = WeatherManager(service: mock)
                            }

                            // deinit for cleanup (if needed)
                        }
                        """)

                        CalloutBox(
                            "Just use Swift's native init! Each test gets a fresh instance automatically.",
                            type: .tip
                        )
                    }
                } label: {
                    Label("Setup & Teardown", systemImage: "arrow.triangle.2.circlepath")
                }

                // MARK: - Quick Reference
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        ComparisonRow(xctest: "import XCTest", swift: "import Testing")
                        ComparisonRow(xctest: "class Foo: XCTestCase", swift: "struct Foo")
                        ComparisonRow(xctest: "func testBar()", swift: "@Test func bar()")
                        ComparisonRow(xctest: "XCTAssertEqual(a, b)", swift: "#expect(a == b)")
                        ComparisonRow(xctest: "XCTAssertTrue(x)", swift: "#expect(x)")
                        ComparisonRow(xctest: "XCTFail(\"msg\")", swift: "Issue.record(\"msg\")")
                        ComparisonRow(xctest: "throw XCTSkip()", swift: "throw Skip(\"reason\")")
                        ComparisonRow(xctest: "setUp()", swift: "init()")
                    }
                } label: {
                    Label("Quick Reference", systemImage: "list.bullet.rectangle")
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("XCTest vs Swift Testing")
    }
}

#Preview {
    NavigationStack {
        SwiftTestingIntroView()
    }
}
