import SwiftUI

struct ContentView: View {
    var body: some View {
        List {
            Section {
                Text("Each exercise has 'Before' (untestable) and 'After' (testable) versions. Study the refactoring patterns!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Dependency Injection") {
                NavigationLink("Singleton Dependencies") {
                    SingletonExerciseView()
                }
                NavigationLink("Network Layer Coupling") {
                    NetworkCouplingExerciseView()
                }
                NavigationLink("Date/Time Dependencies") {
                    DateTimeExerciseView()
                }
            }

            Section("Side Effects") {
                NavigationLink("UserDefaults Access") {
                    UserDefaultsExerciseView()
                }
                NavigationLink("File System Access") {
                    FileSystemExerciseView()
                }
            }

            Section("Architecture Patterns") {
                NavigationLink("ViewModel Testing") {
                    ViewModelExerciseView()
                }
                NavigationLink("Protocol-Based Mocking") {
                    ProtocolMockingExerciseView()
                }
            }

            Section("Async Testing") {
                NavigationLink("Async/Await Testing") {
                    AsyncTestingExerciseView()
                }
            }

            Section("Swift Testing Framework") {
                NavigationLink("XCTest vs Swift Testing") {
                    SwiftTestingIntroView()
                }
                NavigationLink("Advanced Features") {
                    SwiftTestingFeaturesView()
                }
            }
        }
        .navigationTitle("Testability Workshop")
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
