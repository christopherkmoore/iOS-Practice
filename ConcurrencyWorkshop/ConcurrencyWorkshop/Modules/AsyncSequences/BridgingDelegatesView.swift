import SwiftUI
import CoreLocation
import Combine

// MARK: - Exercise: Bridging Delegates to AsyncStream
// Convert delegate-based APIs to modern async sequences

struct BridgingDelegatesView: View {
    var body: some View {
        ExerciseTabView(
            tryItView: BridgingDelegatesTryItView(),
            learnView: QAListView(items: BridgingDelegatesContent.qaItems),
            codeView: CodeViewer(
                title: "BridgingDelegatesView.swift",
                code: BridgingDelegatesContent.sourceCode,
                exercises: BridgingDelegatesContent.exercises
            )
        )
        .navigationTitle("Bridging Delegates")
    }
}

// MARK: - Try It Tab

private struct BridgingDelegatesTryItView: View {
    @StateObject private var locationManager = AsyncLocationManager()
    @State private var isTracking = false

    var body: some View {
        List {
            Section {
                Text("Many Apple frameworks use delegates. AsyncStream lets you convert them to modern async sequences for cleaner code.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
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

        task = Task {
            for await location in locations {
                self.currentLocation = location
            }
        }

        startSimulation()
    }

    func stopTracking() {
        simulationTimer?.invalidate()
        continuation?.finish()
        task?.cancel()
        continuation = nil
    }

    private func startSimulation() {
        var lat = 37.7749
        var lon = -122.4194

        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            lat += Double.random(in: -0.001...0.001)
            lon += Double.random(in: -0.001...0.001)

            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self?.continuation?.yield(location)
        }
    }
}

#Preview {
    NavigationStack {
        BridgingDelegatesView()
    }
}
