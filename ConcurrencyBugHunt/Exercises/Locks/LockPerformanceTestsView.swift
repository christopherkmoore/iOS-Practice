import SwiftUI
import os

// MARK: - Concurrency Performance Comparison
//
// Compares synchronization primitives under two modes:
// - SERIAL: Measures raw lock/unlock overhead. Locks win.
// - CONCURRENT: GCD spawns many threads vs Actor's cooperative scheduling. Actors often win.
//
// Methodology: All mechanisms warmed up, each test runs 3× with median reported.

// MARK: - Test Scenarios

enum WorkloadScenario: String, CaseIterable, Identifiable {
    case balanced = "Balanced (50/50)"
    case readHeavy = "Read Heavy (90% reads)"
    case writeHeavy = "Write Heavy (90% writes)"
    case heavyWork = "Heavy Work Inside Lock"
    case lowVolume = "Low Volume (100 ops)"
    case serial = "Serial (No Concurrency)"
    case scaling = "Scaling Test"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .balanced: return "Equal mix of reads and writes with full concurrency."
        case .readHeavy: return "90% reads, 10% writes. Simulates caches and config lookups."
        case .writeHeavy: return "90% writes, 10% reads. Simulates logging and metrics."
        case .heavyWork: return "CPU-bound work inside critical section. Tests lock hold time impact."
        case .lowVolume: return "Only 100 operations. Shows overhead with minimal work."
        case .serial: return "Sequential execution. Shows raw synchronization overhead."
        case .scaling: return "Tests at 100, 1K, 10K, 50K ops to show scaling behavior."
        }
    }

    var fixedOperationCount: Int? {
        switch self {
        case .lowVolume: return 100
        case .serial: return 1000
        default: return nil
        }
    }

    var isSerial: Bool { self == .serial }
    var usesHeavyWork: Bool { self == .heavyWork }
    var isScaling: Bool { self == .scaling }

    var writeRatio: Double {
        switch self {
        case .readHeavy: return 0.1
        case .writeHeavy: return 0.9
        default: return 0.5
        }
    }
}

// MARK: - Thread-Safe Containers

@inline(never)
private func simulateWork() -> Int {
    var result = 0
    for i in 0..<100 { result += i * i }
    return result
}

protocol LockableContainer: Sendable {
    func write(_ value: Int)
    func read() -> Int
    func reset()
    func writeWithWork(_ value: Int)
    func readWithWork() -> Int
}

// MARK: - NSLock Container

final class ContainerWithNSLock: LockableContainer, @unchecked Sendable {
    private var values: [Int] = []
    private let lock = NSLock()

    func write(_ value: Int) {
        lock.lock()
        defer { lock.unlock() }
        values.append(value)
    }

    func read() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return values.last ?? 0
    }

    func writeWithWork(_ value: Int) {
        lock.lock()
        defer { lock.unlock() }
        _ = simulateWork()
        values.append(value)
    }

    func readWithWork() -> Int {
        lock.lock()
        defer { lock.unlock() }
        _ = simulateWork()
        return values.last ?? 0
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        values.removeAll()
    }
}

// MARK: - os_unfair_lock Container

final class ContainerWithUnfairLock: LockableContainer, @unchecked Sendable {
    private var values: [Int] = []
    private let lockPtr: UnsafeMutablePointer<os_unfair_lock>

    init() {
        lockPtr = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lockPtr.initialize(to: os_unfair_lock())
    }

    deinit {
        lockPtr.deinitialize(count: 1)
        lockPtr.deallocate()
    }

    func write(_ value: Int) {
        os_unfair_lock_lock(lockPtr)
        defer { os_unfair_lock_unlock(lockPtr) }
        values.append(value)
    }

    func read() -> Int {
        os_unfair_lock_lock(lockPtr)
        defer { os_unfair_lock_unlock(lockPtr) }
        return values.last ?? 0
    }

    func writeWithWork(_ value: Int) {
        os_unfair_lock_lock(lockPtr)
        defer { os_unfair_lock_unlock(lockPtr) }
        _ = simulateWork()
        values.append(value)
    }

    func readWithWork() -> Int {
        os_unfair_lock_lock(lockPtr)
        defer { os_unfair_lock_unlock(lockPtr) }
        _ = simulateWork()
        return values.last ?? 0
    }

    func reset() {
        os_unfair_lock_lock(lockPtr)
        defer { os_unfair_lock_unlock(lockPtr) }
        values.removeAll()
    }
}

// MARK: - Serial DispatchQueue Container

final class ContainerWithQueue: LockableContainer, @unchecked Sendable {
    private var values: [Int] = []
    private let queue = DispatchQueue(label: "container.queue")

    func write(_ value: Int) {
        queue.sync { values.append(value) }
    }

    func read() -> Int {
        queue.sync { values.last ?? 0 }
    }

    func writeWithWork(_ value: Int) {
        queue.sync {
            _ = simulateWork()
            values.append(value)
        }
    }

    func readWithWork() -> Int {
        queue.sync {
            _ = simulateWork()
            return values.last ?? 0
        }
    }

    func reset() {
        queue.sync { values.removeAll() }
    }
}

// MARK: - OSAllocatedUnfairLock Container (iOS 16+)

@available(iOS 16.0, *)
final class ContainerWithAllocatedUnfairLock: LockableContainer, @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: [Int]())

    func write(_ value: Int) {
        lock.withLock { $0.append(value) }
    }

    func read() -> Int {
        lock.withLock { $0.last ?? 0 }
    }

    func writeWithWork(_ value: Int) {
        lock.withLock { state in
            _ = simulateWork()
            state.append(value)
        }
    }

    func readWithWork() -> Int {
        lock.withLock { state in
            _ = simulateWork()
            return state.last ?? 0
        }
    }

    func reset() {
        lock.withLock { $0.removeAll() }
    }
}

// MARK: - Reader-Writer Queue Container

final class ContainerWithRWQueue: LockableContainer, @unchecked Sendable {
    private var values: [Int] = []
    private let queue = DispatchQueue(label: "container.rwqueue", attributes: .concurrent)

    func write(_ value: Int) {
        queue.sync(flags: .barrier) { values.append(value) }
    }

    func read() -> Int {
        queue.sync { values.last ?? 0 }
    }

    func writeWithWork(_ value: Int) {
        queue.sync(flags: .barrier) {
            _ = simulateWork()
            values.append(value)
        }
    }

    func readWithWork() -> Int {
        queue.sync {
            _ = simulateWork()
            return values.last ?? 0
        }
    }

    func reset() {
        queue.sync(flags: .barrier) { values.removeAll() }
    }
}

// MARK: - Actor Container

actor ContainerActor {
    private var values: [Int] = []

    func write(_ value: Int) {
        values.append(value)
    }

    func read() -> Int {
        values.last ?? 0
    }

    func writeWithWork(_ value: Int) {
        _ = simulateWork()
        values.append(value)
    }

    func readWithWork() -> Int {
        _ = simulateWork()
        return values.last ?? 0
    }

    func reset() {
        values.removeAll()
    }
}

// MARK: - Performance Result

struct PerformanceResult: Identifiable {
    let id = UUID()
    let name: String
    let time: Double
    let operationCount: Int
    let category: Category

    enum Category: String, CaseIterable {
        case lock = "Locks"
        case gcd = "GCD"
        case modern = "Swift Concurrency"
    }

    var timeString: String {
        String(format: "%.2f ms", time * 1000)
    }

    var opsPerSecond: String {
        guard time > 0 else { return "—" }
        let ops = Double(operationCount) / time
        if ops > 1_000_000 {
            return String(format: "%.1fM ops/s", ops / 1_000_000)
        } else if ops > 1_000 {
            return String(format: "%.1fK ops/s", ops / 1_000)
        }
        return String(format: "%.0f ops/s", ops)
    }
}

// MARK: - View

struct LockPerformanceTestsView: View {
    @State private var selectedScenario: WorkloadScenario = .balanced
    @State private var operationCount: Double = 10000
    @State private var isRunning = false
    @State private var results: [PerformanceResult] = []
    @State private var allTestResults: [WorkloadScenario: [PerformanceResult]] = [:]
    @State private var progressStatus = ""
    @State private var progressValue: Double = 0
    @State private var progressTotal: Double = 1
    @State private var isRunningAllTests = false

    private var count: Int { Int(operationCount) }

    var body: some View {
        List {
            Section {
                Text("Compare synchronization primitives under different workloads.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Section("Scenario") {
                Picker("Workload", selection: $selectedScenario) {
                    ForEach(WorkloadScenario.allCases) { scenario in
                        Text(scenario.rawValue).tag(scenario)
                    }
                }
                .pickerStyle(.menu)

                Text(selectedScenario.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Operations") {
                if let fixed = selectedScenario.fixedOperationCount {
                    Text("Operations: \(fixed) (fixed)")
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total operations: \(count)")
                        Slider(value: $operationCount, in: 1000...50000, step: 1000)
                    }
                }
            }

            Section {
                Button(isRunning ? "Running..." : "Run Test") {
                    runTest()
                }
                .disabled(isRunning || isRunningAllTests)

                Button(isRunningAllTests ? "Running All..." : "Run All @ 50K") {
                    runAllTests()
                }
                .disabled(isRunning || isRunningAllTests)
            }

            if isRunning || isRunningAllTests {
                Section("Progress") {
                    ProgressView(value: progressValue, total: progressTotal)
                    Text(progressStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !results.isEmpty {
                ForEach(PerformanceResult.Category.allCases, id: \.rawValue) { category in
                    let categoryResults = results
                        .filter { $0.category == category }
                        .sorted { $0.time < $1.time }

                    if !categoryResults.isEmpty {
                        Section(category.rawValue) {
                            ForEach(categoryResults) { result in
                                resultRow(result)
                            }
                        }
                    }
                }

                Section("Analysis") {
                    analysisView
                }
            }

            if !allTestResults.isEmpty {
                ForEach(WorkloadScenario.allCases.filter { allTestResults[$0] != nil }, id: \.id) { scenario in
                    if let scenarioResults = allTestResults[scenario] {
                        Section(scenario.rawValue) {
                            let sorted = scenarioResults.sorted { $0.time < $1.time }
                            ForEach(sorted) { result in
                                resultRow(result)
                            }
                            if let fastest = sorted.first,
                               let slowest = sorted.last,
                               fastest.name != slowest.name {
                                Text("\(fastest.name) is \(String(format: "%.1fx", slowest.time / fastest.time)) faster")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            // Educational Content
            Section("Recommended") {
                guidanceRow(
                    name: "Actor",
                    advice: "Default for new code. Safe, no data races possible, great under concurrency.",
                    recommended: true
                )
                guidanceRow(
                    name: "NSLock",
                    advice: "Obj-C interop, recursive locking (NSRecursiveLock), familiar API. Fair ordering.",
                    recommended: true
                )
                guidanceRow(
                    name: "OSAllocatedUnfairLock",
                    advice: "Modern Swift wrapper for os_unfair_lock (iOS 16+). Safer API.",
                    recommended: true
                )
            }

            Section("Specialized / Legacy") {
                guidanceRow(
                    name: "os_unfair_lock",
                    advice: "Low-level. Prefer OSAllocatedUnfairLock unless you need C interop.",
                    recommended: false
                )
                guidanceRow(
                    name: "DispatchQueue.sync",
                    advice: "Simple but slow under concurrency. Better alternatives exist.",
                    recommended: false
                )
            }

            Section("os_unfair_lock Pitfalls") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Must allocate on heap (pointer, not value)")
                    Text("• Cannot hold across await points")
                    Text("• No FIFO guarantee (threads can starve)")
                    Text("• Can have tail latency spikes under heavy contention")
                    Text("• Requires manual memory management")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Section("Key Insights") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Actors win under concurrency (cooperative scheduling)")
                    Text("• Locks win in serial code (no async/await overhead)")
                    Text("• Heavy work inside locks amplifies Actor advantage")
                    Text("• NSLock is fair (FIFO), unfair locks can starve threads")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Performance Tests")
    }

    private func guidanceRow(name: String, advice: String, recommended: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(recommended ? .primary : .secondary)
            Text(advice)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .opacity(recommended ? 1.0 : 0.8)
    }

    private func resultRow(_ result: PerformanceResult) -> some View {
        HStack {
            Text(result.name)
            Spacer()
            VStack(alignment: .trailing) {
                Text(result.timeString)
                    .monospacedDigit()
                Text(result.opsPerSecond)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var analysisView: some View {
        let sorted = results.sorted { $0.time < $1.time }
        if let fastest = sorted.first,
           let slowest = sorted.last,
           fastest.name != slowest.name {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fastest: \(fastest.name)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(String(format: "%.1fx", slowest.time / fastest.time)) faster than \(slowest.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Test Helpers

    private func buildContainers(for scenario: WorkloadScenario) -> [(String, LockableContainer, PerformanceResult.Category)] {
        var containers: [(String, LockableContainer, PerformanceResult.Category)] = [
            ("NSLock", ContainerWithNSLock(), .lock),
            ("os_unfair_lock", ContainerWithUnfairLock(), .lock)
        ]

        if #available(iOS 16.0, *) {
            containers.append(("OSAllocatedUnfairLock", ContainerWithAllocatedUnfairLock(), .lock))
        }

        if scenario.isSerial {
            containers.append(("Serial Queue", ContainerWithQueue(), .gcd))
            containers.append(("RW Queue", ContainerWithRWQueue(), .gcd))
        }

        return containers
    }

    private func warmup(containers: [(String, LockableContainer, PerformanceResult.Category)]) async {
        for (_, container, _) in containers {
            for i in 0..<50 {
                container.write(i)
                _ = container.read()
            }
        }
        let actor = ContainerActor()
        for i in 0..<50 {
            await actor.write(i)
            _ = await actor.read()
        }
    }

    private func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        if sorted.count % 2 == 0 {
            return (sorted[sorted.count/2 - 1] + sorted[sorted.count/2]) / 2
        }
        return sorted[sorted.count/2]
    }

    private func updateProgress(_ status: String, step: Int, total: Int) async {
        await MainActor.run {
            progressStatus = status
            progressValue = Double(step)
            progressTotal = Double(total)
        }
    }

    // MARK: - Run Single Test

    private func runTest() {
        isRunning = true
        results = []
        allTestResults = [:]  // Clear "Run All" results
        let scenario = selectedScenario
        let totalOps = scenario.fixedOperationCount ?? count

        Task {
            let containers = buildContainers(for: scenario)
            let mechanismCount = containers.count + 1
            let scaleLevels = [100, 1_000, 10_000, 50_000]
            let totalSteps = scenario.isScaling
                ? mechanismCount * scaleLevels.count + 1
                : mechanismCount * 3 + 1

            await updateProgress("Warming up...", step: 0, total: totalSteps)
            await warmup(containers: containers)

            var testResults: [PerformanceResult] = []
            var step = 1

            if scenario.isScaling {
                for ops in scaleLevels {
                    let label = ops >= 1000 ? "\(ops/1000)K" : "\(ops)"

                    for (name, container, category) in containers {
                        await updateProgress("\(name) @ \(label)", step: step, total: totalSteps)
                        container.reset()
                        let time = await measureConcurrent(container: container, scenario: scenario, totalOps: ops)
                        testResults.append(PerformanceResult(name: "\(name) (\(label))", time: time, operationCount: ops, category: category))
                        step += 1
                    }

                    let actor = ContainerActor()
                    await updateProgress("Actor @ \(label)", step: step, total: totalSteps)
                    let actorTime = await measureConcurrentActor(container: actor, scenario: scenario, totalOps: ops)
                    testResults.append(PerformanceResult(name: "Actor (\(label))", time: actorTime, operationCount: ops, category: .modern))
                    step += 1
                }
            } else {
                for (name, container, category) in containers {
                    var times: [Double] = []
                    for i in 1...3 {
                        await updateProgress("\(name) (\(i)/3)", step: step, total: totalSteps)
                        container.reset()
                        let time = scenario.isSerial
                            ? measureSerial(container: container, scenario: scenario, totalOps: totalOps)
                            : await measureConcurrent(container: container, scenario: scenario, totalOps: totalOps)
                        times.append(time)
                        step += 1
                    }
                    testResults.append(PerformanceResult(name: name, time: median(times), operationCount: totalOps, category: category))
                }

                let actor = ContainerActor()
                var actorTimes: [Double] = []
                for i in 1...3 {
                    await updateProgress("Actor (\(i)/3)", step: step, total: totalSteps)
                    await actor.reset()
                    let time = scenario.isSerial
                        ? await measureSerialActor(container: actor, scenario: scenario, totalOps: totalOps)
                        : await measureConcurrentActor(container: actor, scenario: scenario, totalOps: totalOps)
                    actorTimes.append(time)
                    step += 1
                }
                testResults.append(PerformanceResult(name: "Actor", time: median(actorTimes), operationCount: totalOps, category: .modern))
            }

            await MainActor.run {
                results = testResults
                isRunning = false
            }
        }
    }

    // MARK: - Run All Tests

    private func runAllTests() {
        isRunningAllTests = true
        allTestResults = [:]
        results = []

        let scenarios: [WorkloadScenario] = [.balanced, .readHeavy, .writeHeavy, .heavyWork, .serial]
        let totalOps = 50_000

        Task {
            let totalSteps = scenarios.reduce(1) { $0 + ($1.isSerial ? 6 : 4) * 3 }

            await updateProgress("Warming up...", step: 0, total: totalSteps)
            await warmup(containers: buildContainers(for: .serial))

            var step = 1

            for scenario in scenarios {
                let containers = buildContainers(for: scenario)
                var scenarioResults: [PerformanceResult] = []

                for (name, container, category) in containers {
                    var times: [Double] = []
                    for i in 1...3 {
                        await updateProgress("[\(scenario.rawValue)] \(name) (\(i)/3)", step: step, total: totalSteps)
                        container.reset()
                        let time = scenario.isSerial
                            ? measureSerial(container: container, scenario: scenario, totalOps: totalOps)
                            : await measureConcurrent(container: container, scenario: scenario, totalOps: totalOps)
                        times.append(time)
                        step += 1
                    }
                    scenarioResults.append(PerformanceResult(name: name, time: median(times), operationCount: totalOps, category: category))
                }

                let actor = ContainerActor()
                var actorTimes: [Double] = []
                for i in 1...3 {
                    await updateProgress("[\(scenario.rawValue)] Actor (\(i)/3)", step: step, total: totalSteps)
                    await actor.reset()
                    let time = scenario.isSerial
                        ? await measureSerialActor(container: actor, scenario: scenario, totalOps: totalOps)
                        : await measureConcurrentActor(container: actor, scenario: scenario, totalOps: totalOps)
                    actorTimes.append(time)
                    step += 1
                }
                scenarioResults.append(PerformanceResult(name: "Actor", time: median(actorTimes), operationCount: totalOps, category: .modern))

                await MainActor.run {
                    allTestResults[scenario] = scenarioResults
                }
            }

            await MainActor.run {
                isRunningAllTests = false
            }
        }
    }

    // MARK: - Measurement

    private func measureSerial(container: LockableContainer, scenario: WorkloadScenario, totalOps: Int) -> Double {
        let start = CFAbsoluteTimeGetCurrent()
        for i in 0..<totalOps {
            performOperation(on: container, scenario: scenario, index: i)
        }
        return CFAbsoluteTimeGetCurrent() - start
    }

    private func measureSerialActor(container: ContainerActor, scenario: WorkloadScenario, totalOps: Int) async -> Double {
        let start = CFAbsoluteTimeGetCurrent()
        for i in 0..<totalOps {
            await performOperation(on: container, scenario: scenario, index: i)
        }
        return CFAbsoluteTimeGetCurrent() - start
    }

    private func measureConcurrent(container: LockableContainer, scenario: WorkloadScenario, totalOps: Int) async -> Double {
        await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
            let group = DispatchGroup()
            let start = CFAbsoluteTimeGetCurrent()

            for i in 0..<totalOps {
                group.enter()
                queue.async {
                    self.performOperation(on: container, scenario: scenario, index: i)
                    group.leave()
                }
            }

            group.notify(queue: .global()) {
                continuation.resume(returning: CFAbsoluteTimeGetCurrent() - start)
            }
        }
    }

    private func measureConcurrentActor(container: ContainerActor, scenario: WorkloadScenario, totalOps: Int) async -> Double {
        let start = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<totalOps {
                group.addTask {
                    await self.performOperation(on: container, scenario: scenario, index: i)
                }
            }
        }
        return CFAbsoluteTimeGetCurrent() - start
    }

    // MARK: - Operations

    nonisolated private func performOperation(on container: LockableContainer, scenario: WorkloadScenario, index: Int) {
        let isWrite = (index % 10) < Int(scenario.writeRatio * 10)
        if scenario.usesHeavyWork {
            if isWrite {
                container.writeWithWork(index)
            } else {
                _ = container.readWithWork()
            }
        } else {
            if isWrite {
                container.write(index)
            } else {
                _ = container.read()
            }
        }
    }

    nonisolated private func performOperation(on container: ContainerActor, scenario: WorkloadScenario, index: Int) async {
        let isWrite = (index % 10) < Int(scenario.writeRatio * 10)
        if scenario.usesHeavyWork {
            if isWrite {
                await container.writeWithWork(index)
            } else {
                _ = await container.readWithWork()
            }
        } else {
            if isWrite {
                await container.write(index)
            } else {
                _ = await container.read()
            }
        }
    }
}

#Preview {
    NavigationStack {
        LockPerformanceTestsView()
    }
}
