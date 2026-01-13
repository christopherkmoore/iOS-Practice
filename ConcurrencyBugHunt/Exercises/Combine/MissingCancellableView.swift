import SwiftUI
import Combine
import UIKit

// MARK: - Exercise: Find the concurrency bug(s) in this code
// This demonstrates issues with not storing cancellables properly

class NotificationListener: ObservableObject {
    @Published var notifications: [String] = []
    @Published var isListening = false

    func startListening() {
        isListening = true
        notifications.append("Started listening...")

        // Subscribe to notifications
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.notifications.append("App became active")
            }

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.notifications.append("App will resign active")
            }

        // Set up a timer to simulate incoming notifications
        Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.notifications.append("Timer tick: \(date.formatted(.dateTime.hour().minute().second()))")
            }
    }

    func stopListening() {
        isListening = false
        notifications.append("Stopped listening (but did it really stop?)")
    }
}

// Another example with network request
class DataFetcher: ObservableObject {
    @Published var data: String = ""
    @Published var error: String?
    @Published var isLoading = false

    private var cancellable: AnyCancellable?

    func fetchData(from urlString: String) {
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            return
        }

        isLoading = true
        error = nil

        // Problem: Each call overwrites the previous cancellable
        // Previous request is implicitly cancelled but no way to explicitly manage multiple requests
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .map { String(data: $0, encoding: .utf8) ?? "Unable to decode" }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] value in
                    self?.data = value
                }
            )
    }

    func fetchMultipleEndpoints(_ urls: [String]) {
        for url in urls {
            // Each iteration overwrites the cancellable!
            fetchData(from: url)
        }
    }
}

// Example with PassthroughSubject
class EventBus: ObservableObject {
    static let shared = EventBus()

    let events = PassthroughSubject<String, Never>()
    @Published var eventLog: [String] = []

    private init() {
        // This subscription is never cleaned up
        events
            .sink { [weak self] event in
                self?.eventLog.append(event)
            }
    }

    func emit(_ event: String) {
        events.send(event)
    }
}

class EventSubscriber: ObservableObject {
    @Published var receivedEvents: [String] = []

    init() {
        subscribeToEvents()
    }

    func subscribeToEvents() {
        // No cancellable stored - subscription immediately deallocated
        EventBus.shared.events
            .sink { [weak self] event in
                self?.receivedEvents.append("Received: \(event)")
                print("EventSubscriber received: \(event)")
            }
    }

    deinit {
        print("EventSubscriber deallocated")
    }
}

struct MissingCancellableView: View {
    @StateObject private var notificationListener = NotificationListener()
    @StateObject private var dataFetcher = DataFetcher()
    @State private var eventSubscriber: EventSubscriber?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Missing Cancellable Storage")
                    .font(.headline)

                GroupBox("Notification Listener") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Issues to find:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("• Cancellables not stored")
                        Text("• Subscriptions may be immediately released")
                        Text("• Stop doesn't actually stop anything")

                        HStack {
                            Button(notificationListener.isListening ? "Listening..." : "Start") {
                                notificationListener.startListening()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Stop") {
                                notificationListener.stopListening()
                            }
                            .buttonStyle(.bordered)
                        }

                        ForEach(notificationListener.notifications.suffix(5), id: \.self) { notification in
                            Text("• \(notification)")
                                .font(.caption)
                        }
                    }
                }

                GroupBox("Data Fetcher") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Issues to find:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("• Single cancellable for multiple requests")
                        Text("• fetchMultipleEndpoints breaks")

                        if dataFetcher.isLoading {
                            ProgressView()
                        }

                        if let error = dataFetcher.error {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }

                        Button("Fetch Multiple") {
                            dataFetcher.fetchMultipleEndpoints([
                                "https://httpbin.org/delay/1",
                                "https://httpbin.org/delay/2",
                                "https://httpbin.org/delay/3"
                            ])
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                GroupBox("Event Bus Subscriber") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Issues to find:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("• Subscription lost immediately")
                        Text("• Events never received by subscriber")

                        HStack {
                            Button("Create Subscriber") {
                                eventSubscriber = EventSubscriber()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Emit Event") {
                                EventBus.shared.emit("Event at \(Date().formatted(.dateTime.second()))")
                            }
                            .buttonStyle(.bordered)
                        }

                        Text("EventBus log: \(EventBus.shared.eventLog.count) events")
                            .font(.caption)
                        Text("Subscriber received: \(eventSubscriber?.receivedEvents.count ?? 0) events")
                            .font(.caption)
                            .foregroundColor(eventSubscriber?.receivedEvents.isEmpty ?? true ? .red : .green)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Missing Cancellable")
    }
}

#Preview {
    NavigationStack {
        MissingCancellableView()
    }
}
