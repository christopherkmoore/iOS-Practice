import SwiftUI

struct ContentView: View {
    var body: some View {
        List {
            Section("List Exercises") {
                NavigationLink("Basic API List") {
                    BasicListExerciseView()
                }
                NavigationLink("Pull to Refresh") {
                    PullToRefreshExerciseView()
                }
                NavigationLink("Search & Filter") {
                    SearchFilterExerciseView()
                }
            }

            Section("Grid Exercises") {
                NavigationLink("Photo Grid") {
                    PhotoGridExerciseView()
                }
                NavigationLink("Adaptive Grid") {
                    AdaptiveGridExerciseView()
                }
            }

            Section("Detail & Navigation") {
                NavigationLink("Master-Detail") {
                    MasterDetailExerciseView()
                }
                NavigationLink("Modal Presentation") {
                    ModalExerciseView()
                }
            }

            Section("State Management") {
                NavigationLink("Form with Validation") {
                    FormValidationExerciseView()
                }
                NavigationLink("Shared State") {
                    SharedStateExerciseView()
                }
            }
        }
        .navigationTitle("SwiftUI Builder")
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
