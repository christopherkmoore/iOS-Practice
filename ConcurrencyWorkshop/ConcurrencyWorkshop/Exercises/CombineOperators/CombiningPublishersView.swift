import SwiftUI
import Combine

// MARK: - Exercise: Combining Publishers
// Learn combineLatest, merge, zip, and other combining operators

struct CombiningPublishersView: View {
    @StateObject private var viewModel = CombiningPublishersViewModel()

    var body: some View {
        List {
            Section {
                Text("Combine provides operators to merge multiple publishers into one stream. Each has different semantics for timing and output.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("combineLatest") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emits when ANY input emits, using latest values from all")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        VStack {
                            Text("A: \(viewModel.valueA)")
                            Stepper("", value: $viewModel.valueA, in: 0...10)
                                .labelsHidden()
                        }

                        VStack {
                            Text("B: \(viewModel.valueB)")
                            Stepper("", value: $viewModel.valueB, in: 0...10)
                                .labelsHidden()
                        }
                    }

                    Text("Combined: A + B = \(viewModel.combinedLatestResult)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }

            Section("merge") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Combines multiple publishers of the SAME type into one stream")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Button("Stream A") {
                            viewModel.emitFromA()
                        }
                        .buttonStyle(.bordered)

                        Button("Stream B") {
                            viewModel.emitFromB()
                        }
                        .buttonStyle(.bordered)

                        Button("Clear") {
                            viewModel.mergedEvents = []
                        }
                        .buttonStyle(.bordered)
                    }

                    ForEach(viewModel.mergedEvents, id: \.self) { event in
                        Text(event)
                            .font(.caption)
                    }
                }
            }

            Section("zip") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Waits for BOTH to emit, pairs them in order (1-1, 2-2, etc.)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Button("Add X") {
                            viewModel.addToZipX()
                        }
                        .buttonStyle(.bordered)

                        Button("Add Y") {
                            viewModel.addToZipY()
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("X queue: \(viewModel.zipXCount) | Y queue: \(viewModel.zipYCount)")
                        .font(.caption)

                    Text("Zipped pairs: \(viewModel.zippedResult)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }

            Section("Code Examples") {
                Text("""
                // combineLatest - form validation
                Publishers.CombineLatest3($email, $password, $terms)
                    .map { email, password, terms in
                        isValidEmail(email) && password.count >= 8 && terms
                    }
                    .assign(to: &$isFormValid)

                // merge - multiple event sources
                let allTaps = Publishers.Merge3(
                    button1.publisher,
                    button2.publisher,
                    button3.publisher
                )

                // zip - parallel requests, need all results
                Publishers.Zip(userPublisher, postsPublisher)
                    .sink { user, posts in
                        // Both completed
                    }
                """)
                .font(.system(.caption2, design: .monospaced))
            }

            Section("When to Use Each") {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        Text("combineLatest").fontWeight(.bold) + Text(" - Form validation, derived state")
                        Text("merge").fontWeight(.bold) + Text(" - Multiple event sources of same type")
                        Text("zip").fontWeight(.bold) + Text(" - Pair values 1:1, parallel requests")
                    }
                    .font(.caption)
                }
            }
        }
        .navigationTitle("Combining Publishers")
    }
}

// MARK: - ViewModel

class CombiningPublishersViewModel: ObservableObject {
    // combineLatest demo
    @Published var valueA = 5
    @Published var valueB = 3
    @Published var combinedLatestResult = 8

    // merge demo
    @Published var mergedEvents: [String] = []
    private let streamA = PassthroughSubject<String, Never>()
    private let streamB = PassthroughSubject<String, Never>()

    // zip demo
    @Published var zippedResult = ""
    @Published var zipXCount = 0
    @Published var zipYCount = 0
    private let zipX = PassthroughSubject<String, Never>()
    private let zipY = PassthroughSubject<Int, Never>()
    private var xValues: [String] = []
    private var yValues: [Int] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupCombineLatest()
        setupMerge()
        setupZip()
    }

    private func setupCombineLatest() {
        Publishers.CombineLatest($valueA, $valueB)
            .map { $0 + $1 }
            .assign(to: &$combinedLatestResult)
    }

    private func setupMerge() {
        Publishers.Merge(streamA, streamB)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.mergedEvents.append(event)
            }
            .store(in: &cancellables)
    }

    private func setupZip() {
        Publishers.Zip(zipX, zipY)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (x, y) in
                self?.zippedResult += "(\(x),\(y)) "
            }
            .store(in: &cancellables)
    }

    func emitFromA() {
        let event = "A-\(Date().formatted(date: .omitted, time: .standard))"
        streamA.send(event)
    }

    func emitFromB() {
        let event = "B-\(Date().formatted(date: .omitted, time: .standard))"
        streamB.send(event)
    }

    func addToZipX() {
        xValues.append("X\(xValues.count + 1)")
        zipXCount = xValues.count
        zipX.send(xValues.last!)
    }

    func addToZipY() {
        yValues.append(yValues.count + 1)
        zipYCount = yValues.count
        zipY.send(yValues.last!)
    }
}

// MARK: - Additional Combining Operators

/*
 // CombineLatest variants
 Publishers.CombineLatest(pub1, pub2)           // 2 publishers
 Publishers.CombineLatest3(pub1, pub2, pub3)    // 3 publishers
 Publishers.CombineLatest4(pub1, pub2, pub3, pub4)  // 4 publishers

 // Merge variants
 Publishers.Merge(pub1, pub2)        // 2 publishers
 Publishers.Merge3(pub1, pub2, pub3) // 3 publishers
 // ... up to Merge8, or use MergeMany for arrays

 // Zip variants
 Publishers.Zip(pub1, pub2)          // 2 publishers
 Publishers.Zip3(pub1, pub2, pub3)   // 3 publishers
 Publishers.Zip4(pub1, pub2, pub3, pub4)  // 4 publishers

 // Other useful combiners:
 publisher.append(otherPublisher)    // Emit from first, then second when first completes
 publisher.prepend(values)           // Emit values first, then publisher
 publisher.switchToLatest()          // For Publisher<Publisher<T>> - cancel old, use new
 */

#Preview {
    NavigationStack {
        CombiningPublishersView()
    }
}
