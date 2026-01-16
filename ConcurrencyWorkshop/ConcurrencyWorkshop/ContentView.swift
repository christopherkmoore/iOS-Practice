import SwiftUI

struct ContentView: View {
    var body: some View {
        List {
            Section {
                Text("Advanced concurrency patterns for modern Swift. Each exercise includes interactive demos and code examples.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("AsyncSequence") {
                NavigationLink("Consuming AsyncSequence") {
                    ConsumingAsyncSequenceView()
                }
                NavigationLink("Building AsyncStreams") {
                    AsyncStreamView()
                }
                NavigationLink("Bridging Delegates") {
                    BridgingDelegatesView()
                }
            }

            Section("Continuations") {
                NavigationLink("Callback to Async") {
                    ContinuationsView()
                }
            }

            Section("Combine Operators") {
                NavigationLink("Combining Publishers") {
                    CombiningPublishersView()
                }
                NavigationLink("Transforming Streams") {
                    TransformingStreamsView()
                }
            }

            Section("Thread Safety") {
                NavigationLink("Sendable Protocol") {
                    SendableView()
                }
            }

            Section("Actor Isolation") {
                NavigationLink("MainActor Patterns") {
                    MainActorPatternsView()
                }
            }
        }
        .navigationTitle("Concurrency Workshop")
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
