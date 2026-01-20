import SwiftUI

struct SwiftTestingFeaturesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Intro
                GroupBox {
                    Text("Swift Testing isn't just cleaner syntax - it has powerful features that XCTest doesn't have at all.")
                        .font(.body)
                } label: {
                    Label("Beyond Syntax", systemImage: "sparkles")
                }

                // MARK: - Parameterized Tests
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Run the same test with different inputs - no copy/paste!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        CodeBlock("""
                        // Runs 3 times - once for each city
                        @Test(arguments: ["NYC", "LA", "Tokyo"])
                        func fetchWeather(city: String) async throws {
                            let result = try await service.fetch(city)
                            #expect(result.city == city)
                        }
                        """)

                        Divider()

                        Text("Multiple Parameters")
                            .font(.headline)

                        CodeBlock("""
                        @Test(arguments: [
                            (city: "NYC", temp: 72),
                            (city: "LA", temp: 85),
                            (city: "Tokyo", temp: 68)
                        ])
                        func weatherMatchesExpected(
                            city: String,
                            temp: Int
                        ) async throws {
                            let result = try await service.fetch(city)
                            #expect(result.temperature == temp)
                        }
                        """)

                        CalloutBox(
                            "In XCTest you'd need 3 separate test methods, or a loop that hides which case failed.",
                            type: .info
                        )
                    }
                } label: {
                    Label("Parameterized Tests", systemImage: "repeat")
                }

                // MARK: - Tags
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Organize and filter tests with tags.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        CodeBlock("""
                        // Define custom tags
                        extension Tag {
                            @Tag static var networking: Self
                            @Tag static var slow: Self
                            @Tag static var critical: Self
                        }

                        // Apply to tests
                        @Test(.tags(.networking))
                        func fetchFromAPI() async { }

                        @Test(.tags(.networking, .slow))
                        func downloadLargeFile() async { }

                        @Test(.tags(.critical))
                        func userAuthentication() { }
                        """)

                        CalloutBox(
                            "Run only tagged tests: xcodebuild test -only-testing:MyTests/.tags(.critical)",
                            type: .tip
                        )
                    }
                } label: {
                    Label("Tags", systemImage: "tag")
                }

                // MARK: - Traits
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Control test behavior with traits.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Disabled Tests")
                            .font(.headline)

                        CodeBlock("""
                        @Test(.disabled("API not deployed yet"))
                        func newFeature() async { }

                        @Test(.disabled(if: isCI, "Flaky on CI"))
                        func flakyTest() { }
                        """)

                        Divider()

                        Text("Time Limits")
                            .font(.headline)

                        CodeBlock("""
                        @Test(.timeLimit(.seconds(5)))
                        func mustBeFast() async { }

                        @Test(.timeLimit(.minutes(1)))
                        func canBeSlow() async { }
                        """)

                        Divider()

                        Text("Bug References")
                            .font(.headline)

                        CodeBlock("""
                        @Test(.bug("https://github.com/org/repo/issues/123"))
                        func regressionTest() { }

                        @Test(.bug(id: "JIRA-456"))
                        func trackedIssue() { }
                        """)
                    }
                } label: {
                    Label("Traits", systemImage: "slider.horizontal.3")
                }

                // MARK: - Suites
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Organize tests with nested structs.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        CodeBlock("""
                        @Suite("Weather Manager")
                        struct WeatherManagerTests {

                            @Suite("Caching")
                            struct CachingTests {
                                @Test func cachesFreshData() { }
                                @Test func expiresOldData() { }
                            }

                            @Suite("Error Handling")
                            struct ErrorTests {
                                @Test func handlesNetworkError() { }
                                @Test func handlesCityNotFound() { }
                            }

                            @Suite("Concurrent Fetching")
                            struct ConcurrentTests {
                                @Test func fetchesInParallel() { }
                            }
                        }
                        """)

                        CalloutBox(
                            "Suites can share setup via init, and nested suites inherit parent setup.",
                            type: .tip
                        )
                    }
                } label: {
                    Label("Test Suites", systemImage: "folder")
                }

                // MARK: - Required Failures
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Expect specific errors cleanly.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        CodeBlock("""
                        // Expect any error
                        @Test func throwsSomething() {
                            #expect(throws: (any Error).self) {
                                try dangerousOperation()
                            }
                        }

                        // Expect specific error
                        @Test func throwsNotFound() {
                            #expect(throws: WeatherError.notFound) {
                                try service.fetch("FakeCity")
                            }
                        }

                        // Expect no error (explicit)
                        @Test func succeeds() {
                            #expect(throws: Never.self) {
                                try safeOperation()
                            }
                        }
                        """)
                    }
                } label: {
                    Label("Error Expectations", systemImage: "xmark.octagon")
                }

                // MARK: - Confirmation (Async Expectations)
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Like XCTest expectations, but cleaner.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("XCTest")
                            .font(.headline)
                            .foregroundColor(.red)

                        CodeBlock("""
                        func testCallback() {
                            let exp = expectation(description: "called")

                            service.fetch { _ in
                                exp.fulfill()
                            }

                            wait(for: [exp], timeout: 5)
                        }
                        """)

                        Divider()

                        Text("Swift Testing")
                            .font(.headline)
                            .foregroundColor(.green)

                        CodeBlock("""
                        @Test func callback() async {
                            await confirmation { confirm in
                                service.fetch { _ in
                                    confirm()
                                }
                            }
                        }

                        // Expect multiple confirmations
                        @Test func multipleCallbacks() async {
                            await confirmation(expectedCount: 3) { confirm in
                                service.fetchAll { _ in
                                    confirm()
                                }
                            }
                        }
                        """)
                    }
                } label: {
                    Label("Confirmations", systemImage: "checkmark.seal")
                }

                // MARK: - When to Use Which
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(feature: "New test files", recommendation: "Swift Testing", color: .green)
                        FeatureRow(feature: "Parameterized tests", recommendation: "Swift Testing", color: .green)
                        FeatureRow(feature: "UI tests (XCUITest)", recommendation: "XCTest only", color: .red)
                        FeatureRow(feature: "Performance tests", recommendation: "XCTest (measure)", color: .red)
                        FeatureRow(feature: "Existing test suite", recommendation: "Migrate gradually", color: .orange)
                        FeatureRow(feature: "Pre-Xcode 16 support", recommendation: "XCTest only", color: .red)
                    }
                } label: {
                    Label("When to Use Which?", systemImage: "questionmark.circle")
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Swift Testing Features")
    }
}

struct FeatureRow: View {
    let feature: String
    let recommendation: String
    let color: Color

    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
            Spacer()
            Text(recommendation)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

#Preview {
    NavigationStack {
        SwiftTestingFeaturesView()
    }
}
