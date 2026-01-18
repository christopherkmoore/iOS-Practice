import SwiftUI
import Combine

// MARK: - Exercise: Combining Publishers
// Learn combineLatest, merge, zip, and other combining operators

struct CombiningPublishersView: View {
    var body: some View {
        ExerciseTabView(
            tryItView: CombiningPublishersTryItView(),
            learnView: QAListView(items: CombiningPublishersContent.qaItems),
            codeView: CodeViewer(
                title: "CombiningPublishersView.swift",
                code: CombiningPublishersContent.sourceCode,
                exercises: CombiningPublishersContent.exercises
            )
        )
        .navigationTitle("Combining Publishers")
    }
}

// MARK: - Try It Tab

private struct CombiningPublishersTryItView: View {
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
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
    }
}

// MARK: - ViewModel

class CombiningPublishersViewModel: ObservableObject {
    @Published var valueA = 5
    @Published var valueB = 3
    @Published var combinedLatestResult = 8

    @Published var mergedEvents: [String] = []
    private let streamA = PassthroughSubject<String, Never>()
    private let streamB = PassthroughSubject<String, Never>()

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

#Preview {
    NavigationStack {
        CombiningPublishersView()
    }
}
