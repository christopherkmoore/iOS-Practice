import SwiftUI

/// A reusable tab container for exercise views with Try It, Learn, and Code tabs
struct ExerciseTabView<TryIt: View, Learn: View, Code: View>: View {
    @State private var selectedTab = 0

    let tryItView: TryIt
    let learnView: Learn
    let codeView: Code

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Try It").tag(0)
                Text("Learn").tag(1)
                Text("Code").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            TabView(selection: $selectedTab) {
                tryItView.tag(0)
                learnView.tag(1)
                codeView.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseTabView(
            tryItView: Text("Try It Content"),
            learnView: Text("Learn Content"),
            codeView: Text("Code Content")
        )
        .navigationTitle("Sample Exercise")
    }
}
