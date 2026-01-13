import SwiftUI

// MARK: - Exercise: Find the concurrency bug(s) in this code
// This demonstrates issues with unstructured tasks and memory leaks

class ImageLoader: ObservableObject {
    @Published var images: [String: Data] = [:]
    @Published var loadingStatus: [String: String] = [:]

    private var loadTasks: [String: Task<Void, Never>] = [:]

    func loadImage(named name: String) {
        loadingStatus[name] = "Loading..."

        // Create unstructured task to load image
        Task {
            // Simulate network fetch
            try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))

            // Simulate image data
            let imageData = Data(repeating: UInt8.random(in: 0...255), count: 1000)

            await MainActor.run {
                self.images[name] = imageData
                self.loadingStatus[name] = "Loaded (\(imageData.count) bytes)"
            }
        }
    }

    func loadAllImages(_ names: [String]) {
        for name in names {
            loadImage(named: name)
        }
    }

    func cancelLoad(named name: String) {
        loadTasks[name]?.cancel()
        loadTasks.removeValue(forKey: name)
        loadingStatus[name] = "Cancelled"
    }

    func cancelAll() {
        for (name, task) in loadTasks {
            task.cancel()
            loadingStatus[name] = "Cancelled"
        }
        loadTasks.removeAll()
    }
}

// View that creates tasks that outlive it
class PollingService: ObservableObject {
    @Published var lastUpdate: Date?
    @Published var updateCount = 0
    @Published var isPolling = false

    func startPolling() {
        isPolling = true

        Task {
            while true {
                // Fetch updates
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                await MainActor.run {
                    self.lastUpdate = Date()
                    self.updateCount += 1
                }

                print("Polling update #\(updateCount)")
            }
        }
    }

    func stopPolling() {
        isPolling = false
        // Hmm, how do we actually stop the task?
    }
}

struct UnstructuredTaskLeakView: View {
    @StateObject private var imageLoader = ImageLoader()
    @StateObject private var pollingService = PollingService()

    let imageNames = ["photo1", "photo2", "photo3", "photo4", "photo5"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Unstructured Task Issues")
                    .font(.headline)

                GroupBox("Image Loader") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Issues to find:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("• Tasks aren't tracked properly")
                        Text("• Cancel doesn't work as expected")
                        Text("• Memory leak potential")

                        Divider()

                        ForEach(imageNames, id: \.self) { name in
                            HStack {
                                Text(name)
                                Spacer()
                                Text(imageLoader.loadingStatus[name] ?? "Not loaded")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Button("Load All") {
                                imageLoader.loadAllImages(imageNames)
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Cancel All") {
                                imageLoader.cancelAll()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                GroupBox("Polling Service") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Issues to find:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("• Infinite loop without cancellation check")
                        Text("• Task outlives the view")
                        Text("• Stop button doesn't work")

                        Divider()

                        HStack {
                            Text("Updates: \(pollingService.updateCount)")
                            Spacer()
                            if let lastUpdate = pollingService.lastUpdate {
                                Text(lastUpdate.formatted(.dateTime.hour().minute().second()))
                                    .font(.caption)
                            }
                        }

                        HStack {
                            Button("Start Polling") {
                                pollingService.startPolling()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(pollingService.isPolling)

                            Button("Stop Polling") {
                                pollingService.stopPolling()
                            }
                            .buttonStyle(.bordered)
                        }

                        Text("Try: Start polling, navigate away, come back")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Task Leaks")
    }
}

#Preview {
    NavigationStack {
        UnstructuredTaskLeakView()
    }
}
