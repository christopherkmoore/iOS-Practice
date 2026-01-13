import SwiftUI

struct ContentView: View {
    var body: some View {
        List {
            Section("GCD Issues") {
                NavigationLink("Race Condition") {
                    RaceConditionView()
                }
                NavigationLink("Main Thread Violation") {
                    MainThreadViolationView()
                }
                NavigationLink("Deadlock") {
                    DeadlockView()
                }
            }

            Section("Async/Await Issues") {
                NavigationLink("Task Cancellation Bug") {
                    TaskCancellationView()
                }
                NavigationLink("Actor Reentrancy") {
                    ActorReentrancyView()
                }
                NavigationLink("Unstructured Task Leak") {
                    UnstructuredTaskLeakView()
                }
            }

            Section("Combine Issues") {
                NavigationLink("Publisher Retain Cycle") {
                    PublisherRetainCycleView()
                }
                NavigationLink("Missing Cancellable Storage") {
                    MissingCancellableView()
                }
            }
        }
        .navigationTitle("Concurrency Bug Hunt")
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
