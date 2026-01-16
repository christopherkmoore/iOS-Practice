import SwiftUI
import CoreLocation
import Combine

// MARK: - Exercise: Bridging Delegates to AsyncStream
// Convert delegate-based APIs to modern async sequences

struct BridgingDelegatesView: View {
    @StateObject private var locationManager = AsyncLocationManager()
    @State private var isTracking = false

    var body: some View {
        List {
            Section {
                Text("Many Apple frameworks use delegates. AsyncStream lets you convert them to modern async sequences for cleaner code.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Key Concepts") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Store continuation in delegate class")
                    Text("• Yield values from delegate callbacks")
                    Text("• Handle cleanup in onTermination")
                    Text("• Consider using actor for thread safety")
                }
                .font(.caption)
            }

            Section("The Problem: Delegate Pattern") {
                Text("""
                // Old way - scattered callbacks
                class LocationDelegate: CLLocationManagerDelegate {
                    func locationManager(_ manager: CLLocationManager,
                        didUpdateLocations locations: [CLLocation]) {
                        // Handle here...
                    }

                    func locationManager(_ manager: CLLocationManager,
                        didFailWithError error: Error) {
                        // Handle here...
                    }
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("The Solution: AsyncStream") {
                Text("""
                // New way - clean async sequence
                for await location in locationManager.locations {
                    print("Location: \\(location)")
                }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("Try It: Location Stream") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button(isTracking ? "Stop" : "Start Tracking") {
                            if isTracking {
                                locationManager.stopTracking()
                            } else {
                                locationManager.startTracking()
                            }
                            isTracking.toggle()
                        }
                        .buttonStyle(.borderedProminent)

                        Spacer()

                        if isTracking {
                            ProgressView()
                        }
                    }

                    if let location = locationManager.currentLocation {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latitude: \(location.latitude, specifier: "%.4f")")
                            Text("Longitude: \(location.longitude, specifier: "%.4f")")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }

                    if let error = locationManager.error {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Text("(Simulated locations for demo)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Section("Common Delegate APIs to Bridge") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• CLLocationManager → location stream")
                    Text("• URLSessionDelegate → download progress")
                    Text("• AVCaptureSession → video frames")
                    Text("• CBCentralManager → Bluetooth events")
                    Text("• WCSession → Watch connectivity")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Bridging Delegates")
        .onDisappear {
            locationManager.stopTracking()
        }
    }
}

// MARK: - AsyncLocationManager

@MainActor
class AsyncLocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var error: String?

    private var continuation: AsyncStream<CLLocationCoordinate2D>.Continuation?
    private var task: Task<Void, Never>?

    // Simulated for demo - in real app, use CLLocationManager
    private var simulationTimer: Timer?

    var locations: AsyncStream<CLLocationCoordinate2D> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation

            continuation.onTermination = { @Sendable _ in
                Task { @MainActor [weak self] in
                    self?.simulationTimer?.invalidate()
                }
            }
        }
    }

    func startTracking() {
        error = nil

        // Start consuming the stream
        task = Task {
            for await location in locations {
                self.currentLocation = location
            }
        }

        // Simulate location updates (in real app, this would be CLLocationManager delegate)
        startSimulation()
    }

    func stopTracking() {
        simulationTimer?.invalidate()
        continuation?.finish()
        task?.cancel()
        continuation = nil
    }

    private func startSimulation() {
        var lat = 37.7749  // San Francisco
        var lon = -122.4194

        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Simulate movement
            lat += Double.random(in: -0.001...0.001)
            lon += Double.random(in: -0.001...0.001)

            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self?.continuation?.yield(location)
        }
    }
}

// MARK: - Real CLLocationManager Bridge Example

/*
 class RealLocationBridge: NSObject, CLLocationManagerDelegate {
     private let manager = CLLocationManager()
     private var continuation: AsyncStream<CLLocation>.Continuation?

     var locations: AsyncStream<CLLocation> {
         AsyncStream { continuation in
             self.continuation = continuation
             manager.delegate = self
             manager.requestWhenInUseAuthorization()
             manager.startUpdatingLocation()

             continuation.onTermination = { @Sendable [weak self] _ in
                 self?.manager.stopUpdatingLocation()
             }
         }
     }

     func locationManager(_ manager: CLLocationManager,
                          didUpdateLocations locations: [CLLocation]) {
         for location in locations {
             continuation?.yield(location)
         }
     }

     func locationManager(_ manager: CLLocationManager,
                          didFailWithError error: Error) {
         // Could use AsyncThrowingStream to propagate errors
         continuation?.finish()
     }
 }

 // Usage:
 let bridge = RealLocationBridge()
 for await location in bridge.locations {
     print("Location: \(location.coordinate)")
 }
 */

// MARK: - URLSession Download Progress Bridge

/*
 class DownloadProgressBridge: NSObject, URLSessionDownloadDelegate {
     private var continuation: AsyncStream<Double>.Continuation?

     func downloadProgress(for url: URL) -> AsyncStream<Double> {
         AsyncStream { continuation in
             self.continuation = continuation

             let config = URLSessionConfiguration.default
             let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
             let task = session.downloadTask(with: url)
             task.resume()

             continuation.onTermination = { @Sendable _ in
                 task.cancel()
             }
         }
     }

     func urlSession(_ session: URLSession,
                     downloadTask: URLSessionDownloadTask,
                     didWriteData bytesWritten: Int64,
                     totalBytesWritten: Int64,
                     totalBytesExpectedToWrite: Int64) {
         let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
         continuation?.yield(progress)
     }

     func urlSession(_ session: URLSession,
                     downloadTask: URLSessionDownloadTask,
                     didFinishDownloadingTo location: URL) {
         continuation?.yield(1.0)
         continuation?.finish()
     }
 }
 */

#Preview {
    NavigationStack {
        BridgingDelegatesView()
    }
}
