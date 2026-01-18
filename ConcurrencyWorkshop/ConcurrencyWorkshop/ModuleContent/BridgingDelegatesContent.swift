import Foundation

/// Q&A content extracted from blog posts 79-80
struct BridgingDelegatesContent {

    static let qaItems: [QAItem] = [
        QAItem(
            question: "How do you wrap delegate-based APIs with AsyncStream?",
            answer: """
            Store the continuation as an instance property, then yield from delegate callbacks:

            class AsyncLocationManager: NSObject, CLLocationManagerDelegate {
                private var continuation: AsyncStream<CLLocation>.Continuation?

                var locations: AsyncStream<CLLocation> {
                    AsyncStream { continuation in
                        self.continuation = continuation
                        manager.delegate = self
                        manager.startUpdatingLocation()

                        continuation.onTermination = { @Sendable _ in
                            self.manager.stopUpdatingLocation()
                        }
                    }
                }

                func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                    locations.forEach { continuation?.yield($0) }
                }
            }
            """
        ),
        QAItem(
            question: "What's the key pattern for bridging delegates?",
            answer: """
            All delegate bridges follow the same structure:

            1. Create the AsyncStream
            2. Store the continuation as a property
            3. Setup the underlying system (delegate, observer, etc.)
            4. Yield values when delegate callbacks occur
            5. Cleanup in onTermination
            """
        ),
        QAItem(
            question: "Why do you need to store the continuation?",
            answer: """
            Delegate methods need access to the continuation to yield values:

            class DelegateBridge {
                // Store as instance property
                private var continuation: AsyncStream<Event>.Continuation?

                var events: AsyncStream<Event> {
                    AsyncStream { continuation in
                        self.continuation = continuation
                        // Setup...
                    }
                }

                // Delegate methods use stored continuation
                func delegateCallback(event: Event) {
                    continuation?.yield(event)
                }
            }
            """
        ),
        QAItem(
            question: "How do you handle download progress with AsyncStream?",
            answer: """
            Use URLSessionDownloadDelegate to track progress:

            class DownloadManager: NSObject, URLSessionDownloadDelegate {
                private var continuation: AsyncStream<Double>.Continuation?

                func downloadProgress(from url: URL) -> AsyncStream<Double> {
                    AsyncStream { continuation in
                        self.continuation = continuation
                        let task = session.downloadTask(with: url)
                        task.resume()

                        continuation.onTermination = { @Sendable _ in
                            task.cancel()
                        }
                    }
                }

                func urlSession(..., didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
                    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                    continuation?.yield(progress)
                }
            }
            """
        ),
        QAItem(
            question: "What are thread safety considerations when bridging delegates?",
            answer: """
            Delegate callbacks might come on any thread. AsyncStream's continuation is thread-safe, but be careful with other state:

            // If you need thread-safe state alongside the stream:
            actor SafeLocationManager {
                private var lastLocation: CLLocation?

                func updateLocation(_ location: CLLocation) {
                    lastLocation = location
                }
            }
            """
        ),
        QAItem(
            question: "Interview Tip: How would you modernize delegate-based code?",
            answer: """
            This pattern shows up constantly in iOS interviews. Walk through the steps:

            1. Store the continuation as a property
            2. Yield in delegate callbacks
            3. Cleanup in onTermination

            Mention that most delegate-based frameworks (CoreLocation, CoreBluetooth, URLSession delegates) can be wrapped in AsyncStream. Show you understand the trade-offs: cleaner consumption code, but you're managing the bridge layer.
            """
        )
    ]

    static let exercises: [ExerciseItem] = [
        ExerciseItem(
            title: "Spot the Bug: Memory Leak",
            prompt: "In the AsyncLocationManager, what happens if you remove [weak self] from the AsyncStream closure? What retains what?",
            hint: "Strong reference cycles: AsyncStream holds closure → closure holds self → self holds continuation property. Use [weak self] and guard let."
        ),
        ExerciseItem(
            title: "Add Error Handling",
            prompt: "The locationManager(_:didFailWithError:) method just calls finish(). How would you propagate the error to consumers?",
            hint: "Switch from AsyncStream to AsyncThrowingStream and use continuation.finish(throwing: error)"
        )
    ]

    static let sourceCode: String = """
    import SwiftUI
    import CoreLocation
    import Combine

    struct BridgingDelegatesView: View {
        @StateObject private var locationManager = AsyncLocationManager()
        @State private var locations: [CLLocation] = []
        @State private var isTracking = false
        @State private var task: Task<Void, Never>?

        var body: some View {
            List {
                Section("Try It: Location Stream") {
                    Button(isTracking ? "Stop Tracking" : "Start Tracking") {
                        if isTracking {
                            task?.cancel()
                            isTracking = false
                        } else {
                            startTracking()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    ForEach(locations.suffix(5), id: \\.timestamp) { location in
                        Text("Lat: \\(location.coordinate.latitude, specifier: "%.4f"), Lon: \\(location.coordinate.longitude, specifier: "%.4f")")
                            .font(.caption)
                    }
                }
            }
        }

        func startTracking() {
            isTracking = true
            locations = []

            task = Task {
                for await location in locationManager.locations {
                    await MainActor.run {
                        locations.append(location)
                    }
                }
                await MainActor.run {
                    isTracking = false
                }
            }
        }
    }

    // MARK: - CLLocationManager AsyncStream Wrapper

    class AsyncLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
        private let manager = CLLocationManager()
        private var continuation: AsyncStream<CLLocation>.Continuation?

        var locations: AsyncStream<CLLocation> {
            AsyncStream { [weak self] continuation in
                guard let self else {
                    continuation.finish()
                    return
                }

                self.continuation = continuation
                self.manager.delegate = self
                self.manager.requestWhenInUseAuthorization()
                self.manager.startUpdatingLocation()

                continuation.onTermination = { @Sendable _ in
                    Task { @MainActor [weak self] in
                        self?.manager.stopUpdatingLocation()
                    }
                }
            }
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            locations.forEach { continuation?.yield($0) }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            continuation?.finish()
        }
    }
    """
}
