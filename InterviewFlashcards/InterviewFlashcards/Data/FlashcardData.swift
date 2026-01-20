import Foundation

struct FlashcardData {
    static let allCards: [Flashcard] = swiftCards + concurrencyCards + testingCards + swiftuiCards

    // MARK: - Swift Language Fundamentals
    static let swiftCards: [Flashcard] = [
        // Optionals
        Flashcard(
            question: "What is optional unwrapping?",
            answer: "Safely extracting the value from an Optional. Methods: if let (optional binding), guard let (early exit), nil coalescing (??), force unwrap (!), optional chaining (?.).",
            category: .swift
        ),
        Flashcard(
            question: "What's the difference between if let and guard let?",
            answer: "if let: unwrapped value scoped inside the if block. guard let: unwrapped value available after the guard, requires early exit (return/throw) in else. Use guard for preconditions.",
            category: .swift
        ),
        Flashcard(
            question: "What is nil coalescing (??)?",
            answer: "Provides a default value when optional is nil. let name = optionalName ?? \"Unknown\". Short-circuits: right side only evaluated if left is nil.",
            category: .swift
        ),
        Flashcard(
            question: "What is optional chaining?",
            answer: "Safely access properties/methods on optionals: user?.address?.street. Returns nil if any link is nil. Avoids nested if-lets for deep access.",
            category: .swift
        ),
        Flashcard(
            question: "When is force unwrapping (!) acceptable?",
            answer: "When you're 100% certain the value exists (e.g., IBOutlets after viewDidLoad, hardcoded valid data). Crashes on nil. Prefer safe unwrapping in most cases.",
            category: .swift
        ),
        Flashcard(
            question: "What is an implicitly unwrapped optional (IUO)?",
            answer: "Declared with ! (e.g., var name: String!). Auto-unwraps when accessed. Use for values nil at init but set before use (IBOutlets). Crashes if accessed while nil.",
            category: .swift
        ),

        // Value vs Reference Types
        Flashcard(
            question: "What's the difference between value types and reference types?",
            answer: "Value types (struct, enum): copied on assignment, each copy independent. Reference types (class): shared reference, changes affect all references. Value types are thread-safer.",
            category: .swift
        ),
        Flashcard(
            question: "What is copy-on-write (COW)?",
            answer: "Optimization for value types (Array, String, Dictionary). Copies share storage until mutation. On write, Swift copies only if multiple references exist. Efficient for large collections.",
            category: .swift
        ),
        Flashcard(
            question: "When should you use a class vs struct?",
            answer: "Struct (default): value semantics, no inheritance needed, thread-safe. Class: need reference semantics, inheritance, identity (===), or interop with Obj-C. Apple recommends struct by default.",
            category: .swift
        ),

        // Closures
        Flashcard(
            question: "What is a closure?",
            answer: "Self-contained block of code that captures values from context. Can be stored, passed, returned. Syntax: { (params) -> Return in code }. Functions are named closures.",
            category: .swift
        ),
        Flashcard(
            question: "What is @escaping?",
            answer: "Marks closures that outlive the function call (stored, async callbacks). Required when closure is saved to property or called after function returns. Non-escaping is default.",
            category: .swift
        ),
        Flashcard(
            question: "What is trailing closure syntax?",
            answer: "When last parameter is closure, write it after parentheses: array.map { $0 * 2 }. Multiple trailing closures (Swift 5.3+): Button { label } action: { }",
            category: .swift
        ),
        Flashcard(
            question: "What does [weak self] do in closures?",
            answer: "Captures self as weak reference to prevent retain cycles. self becomes optional inside closure. Use when closure is stored by object it references.",
            category: .swift
        ),
        Flashcard(
            question: "What's the difference between [weak self] and [unowned self]?",
            answer: "[weak self]: self is optional, safely nil. [unowned self]: assumes self always exists, crashes if deallocated. Use weak unless you're certain of lifetime.",
            category: .swift
        ),

        // Protocols
        Flashcard(
            question: "What is a protocol?",
            answer: "Blueprint of methods, properties, requirements. Types conform to protocols. Enables polymorphism without inheritance. Foundation of Swift's protocol-oriented programming.",
            category: .swift
        ),
        Flashcard(
            question: "What is protocol-oriented programming?",
            answer: "Design pattern favoring protocols over class inheritance. Use protocol extensions for default implementations. Enables composition, avoids fragile base class problem.",
            category: .swift
        ),
        Flashcard(
            question: "What is a protocol extension?",
            answer: "Adds default implementations to protocol methods. All conforming types get the implementation for free. Can be overridden. Enables code sharing without inheritance.",
            category: .swift
        ),
        Flashcard(
            question: "What is an associated type?",
            answer: "Placeholder type in protocol: associatedtype Element. Conforming types specify concrete type. Enables generic protocols. Makes protocol non-existential (can't use as type directly).",
            category: .swift
        ),
        Flashcard(
            question: "What does 'any' keyword do with protocols?",
            answer: "Creates existential type (box) for protocol with associated types or Self requirements. any Equatable can hold any Equatable. Has runtime overhead vs generics.",
            category: .swift
        ),
        Flashcard(
            question: "What does 'some' keyword do?",
            answer: "Opaque return type. Hides concrete type but compiler knows it. some View means one specific View type. Enables type inference while hiding implementation details.",
            category: .swift
        ),

        // Generics
        Flashcard(
            question: "What are generics?",
            answer: "Type parameters that work with any type. func swap<T>(_ a: inout T, _ b: inout T). Enables type-safe, reusable code. Array<Element> is generic over Element.",
            category: .swift
        ),
        Flashcard(
            question: "What is a generic constraint?",
            answer: "Limits what types can be used: func sort<T: Comparable>(_ array: [T]). T must conform to Comparable. Multiple constraints: where T: Hashable, T: Codable.",
            category: .swift
        ),
        Flashcard(
            question: "What is type erasure?",
            answer: "Wrapping generic/associated type in non-generic type. AnyPublisher<Output, Failure> erases publisher type. Needed when you can't expose concrete generic type.",
            category: .swift
        ),

        // Memory Management
        Flashcard(
            question: "What is ARC (Automatic Reference Counting)?",
            answer: "Swift's memory management. Tracks strong references to class instances. Deallocates when count reaches zero. Compile-time insertion of retain/release. Not garbage collection.",
            category: .swift
        ),
        Flashcard(
            question: "What is a retain cycle (strong reference cycle)?",
            answer: "Two objects hold strong references to each other, neither can deallocate. Common: closure captures self, delegates. Break with weak or unowned references.",
            category: .swift
        ),
        Flashcard(
            question: "What's the difference between weak and unowned?",
            answer: "weak: optional, auto-nils when target deallocates, safe. unowned: non-optional, crashes if accessed after dealloc. Use weak unless you guarantee lifetime.",
            category: .swift
        ),
        Flashcard(
            question: "Why are delegates typically weak?",
            answer: "Prevents retain cycle. Object A holds delegate (B), B often holds A. If delegate is strong, neither deallocates. Weak delegate lets A dealloc, breaking cycle.",
            category: .swift
        ),

        // Error Handling
        Flashcard(
            question: "What's the difference between throws and rethrows?",
            answer: "throws: function can throw errors. rethrows: only throws if closure parameter throws. map uses rethrows—only throws if your closure throws.",
            category: .swift
        ),
        Flashcard(
            question: "What is Result type?",
            answer: "Result<Success, Failure> represents success or failure. .success(value) or .failure(error). Alternative to throws for async callbacks. Use switch or get() to extract.",
            category: .swift
        ),
        Flashcard(
            question: "What does try? do?",
            answer: "Converts throwing call to optional. Returns nil on error, value on success. let data = try? loadFile(). Discards error info—use when you don't need error details.",
            category: .swift
        ),
        Flashcard(
            question: "What does try! do?",
            answer: "Force-tries throwing call. Crashes if error thrown. Use only when failure is impossible (hardcoded valid data). Prefer try? or do-catch in production code.",
            category: .swift
        ),

        // Access Control
        Flashcard(
            question: "What are Swift's access levels?",
            answer: "open: subclass/override anywhere. public: access anywhere, no override outside module. internal (default): within module. fileprivate: within file. private: within enclosing declaration.",
            category: .swift
        ),
        Flashcard(
            question: "What's the difference between open and public?",
            answer: "Both accessible outside module. open allows subclassing and overriding outside module. public does not. Use public by default, open only when inheritance is intended API.",
            category: .swift
        ),

        // Property Wrappers
        Flashcard(
            question: "What is a property wrapper?",
            answer: "@propertyWrapper struct that adds behavior to properties. wrappedValue is the main value, projectedValue ($) for additional access. Examples: @State, @Published, @AppStorage.",
            category: .swift
        ),
        Flashcard(
            question: "What is projectedValue ($)?",
            answer: "Secondary value exposed by property wrapper via $ prefix. @State's projectedValue is Binding. @Published's is Publisher. Access: $myProperty.",
            category: .swift
        ),

        // Enums
        Flashcard(
            question: "What are associated values in enums?",
            answer: "Data attached to enum cases: case success(Data), case failure(Error). Each case can have different types. Extract with switch case let or if case let.",
            category: .swift
        ),
        Flashcard(
            question: "What are raw values in enums?",
            answer: "Compile-time constant for each case: enum Status: Int { case active = 1 }. All cases same type. Access: status.rawValue. Init: Status(rawValue: 1).",
            category: .swift
        ),
        Flashcard(
            question: "When use associated values vs raw values?",
            answer: "Associated: runtime data, different per case (Result, Optional). Raw: compile-time constants, same type (JSON keys, API codes). Can't mix both in same enum.",
            category: .swift
        ),

        // Collections
        Flashcard(
            question: "What's the difference between Array, Set, and Dictionary?",
            answer: "Array: ordered, duplicates allowed, O(n) search. Set: unordered, unique values, O(1) lookup. Dictionary: key-value pairs, unique keys, O(1) lookup by key.",
            category: .swift
        ),
        Flashcard(
            question: "What is a Sequence vs Collection?",
            answer: "Sequence: can iterate once (may be single-pass). Collection: multi-pass, indexed access, has count. Array/Set/Dictionary are Collections. Generators are Sequences.",
            category: .swift
        ),

        // Other Important Concepts
        Flashcard(
            question: "What is @autoclosure?",
            answer: "Wraps expression in closure automatically. assert uses it to defer evaluation. func log(_ msg: @autoclosure () -> String). Called: log(expensiveCompute())—only evaluated if needed.",
            category: .swift
        ),
        Flashcard(
            question: "What is @inlinable?",
            answer: "Allows function body to be inlined across module boundaries. Improves performance by avoiding function call overhead. Exposes implementation as part of ABI.",
            category: .swift
        ),
        Flashcard(
            question: "What is the difference between Self and self?",
            answer: "self: instance of current type (lowercase). Self: the type itself (uppercase). In protocols, Self is conforming type. Return Self for fluent interfaces.",
            category: .swift
        ),
        Flashcard(
            question: "What is metatype (.Type and .self)?",
            answer: "Type.self gets the metatype value. Used for: generics, decoding (JSONDecoder.decode(User.self)), dependency injection. .Type is the metatype type.",
            category: .swift
        ),
        Flashcard(
            question: "What is KeyPath?",
            answer: "Reference to property: \\User.name. Type-safe, can be stored/passed. Use with subscript: user[keyPath: path]. Enables generic property access without strings.",
            category: .swift
        ),
    ]

    static let concurrencyCards: [Flashcard] = [
        // Race Conditions & Data Races
        Flashcard(
            question: "What's the difference between a data race and a race condition?",
            answer: "A data race is when two threads access the same memory simultaneously and at least one is writing. A race condition is when the outcome depends on timing. Data races are undefined behavior; race conditions are logic bugs.",
            category: .concurrency
        ),
        Flashcard(
            question: "Why must UI updates happen on the main thread?",
            answer: "UIKit/AppKit aren't thread-safe. Updating UI from background threads causes crashes, visual glitches, or undefined behavior. Use @MainActor or DispatchQueue.main to ensure main thread execution.",
            category: .concurrency
        ),
        Flashcard(
            question: "How do you detect data races in Xcode?",
            answer: "Enable Thread Sanitizer (TSan) in your scheme's diagnostics. It detects data races at runtime with ~2-5x slowdown. Also use Swift 6's strict concurrency checking.",
            category: .concurrency
        ),

        // Deadlocks
        Flashcard(
            question: "What causes a deadlock?",
            answer: "A deadlock occurs when two or more threads wait for each other to release resources, creating a circular dependency. Common cause: calling DispatchQueue.main.sync from the main thread.",
            category: .concurrency
        ),
        Flashcard(
            question: "Why does DispatchQueue.main.sync crash from the main thread?",
            answer: "The main thread blocks waiting for the sync block to run, but the block can't run until the main thread is free. Classic deadlock. Use async instead, or check if already on main thread.",
            category: .concurrency
        ),

        // Task Cancellation
        Flashcard(
            question: "How does Task cancellation work in Swift?",
            answer: "Cancellation is cooperative. Calling task.cancel() sets a flag but doesn't stop execution. Your code must check Task.isCancelled or call try Task.checkCancellation() to respond.",
            category: .concurrency
        ),
        Flashcard(
            question: "What happens if you don't check for cancellation?",
            answer: "The task runs to completion, wasting resources. Check cancellation at suspension points and before expensive operations. Use try Task.checkCancellation() to throw CancellationError.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is structured concurrency?",
            answer: "Child tasks are scoped to their parent. When a parent task is cancelled or completes, all children are automatically cancelled. Prevents orphaned tasks and resource leaks.",
            category: .concurrency
        ),

        // Actors
        Flashcard(
            question: "What is actor reentrancy?",
            answer: "When an actor awaits, other calls can run before it resumes. State may change between suspension points. Always re-validate state after await, never assume it's unchanged.",
            category: .concurrency
        ),
        Flashcard(
            question: "What does @MainActor do?",
            answer: "@MainActor isolates code to the main thread. Apply to classes, functions, or properties that must run on main thread. The compiler enforces this at compile time.",
            category: .concurrency
        ),
        Flashcard(
            question: "When should you use nonisolated?",
            answer: "Use nonisolated for actor methods that don't access mutable state, allowing them to be called synchronously. Example: computed properties based on let constants.",
            category: .concurrency
        ),
        Flashcard(
            question: "What's the actor hop overhead?",
            answer: "Every cross-actor call involves a context switch (~microseconds). For hot paths with many calls, this overhead adds up. Batch operations or use locks for ultra-low-latency needs.",
            category: .concurrency
        ),

        // Locks
        Flashcard(
            question: "What's the difference between NSLock and os_unfair_lock?",
            answer: "NSLock is fair (FIFO ordering, predictable latency). os_unfair_lock is faster but can starve threads under contention. Use NSLock for predictability, os_unfair_lock for raw speed.",
            category: .concurrency
        ),
        Flashcard(
            question: "Why must os_unfair_lock be heap-allocated?",
            answer: "os_unfair_lock uses memory address for identity. If the struct moves (stack/value copy), the lock breaks. Allocate on heap with UnsafeMutablePointer to ensure stable address.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is OSAllocatedUnfairLock?",
            answer: "iOS 16+ Swift wrapper for os_unfair_lock that handles heap allocation automatically. Safer API than raw os_unfair_lock. Use withLock { } closure pattern.",
            category: .concurrency
        ),
        Flashcard(
            question: "When do actors outperform locks?",
            answer: "Under concurrent workloads. Actors use cooperative scheduling (limited threads). GCD with locks spawns many threads causing contention. But locks win for serial hot paths due to no async overhead.",
            category: .concurrency
        ),

        // Priority & Scheduling
        Flashcard(
            question: "What is priority inversion?",
            answer: "A high-priority task waits for a low-priority task holding a resource. The system may boost the low-priority task temporarily. Avoid by minimizing lock hold times.",
            category: .concurrency
        ),
        Flashcard(
            question: "What are the Task priority levels?",
            answer: ".userInitiated (highest), .medium (default), .utility, .background (lowest). Higher priority tasks get more CPU time. Child tasks inherit parent priority by default.",
            category: .concurrency
        ),

        // Combine
        Flashcard(
            question: "How do you prevent retain cycles with Combine?",
            answer: "Use [weak self] in sink closures. Store cancellables properly—Set<AnyCancellable> keeps subscriptions alive. Cancellables auto-cancel on dealloc, breaking the cycle.",
            category: .concurrency
        ),
        Flashcard(
            question: "What does receive(on:) do?",
            answer: "Switches downstream operators to a specific scheduler (e.g., DispatchQueue.main). Use for UI updates. Place after network calls: publisher.receive(on: DispatchQueue.main).sink { }",
            category: .concurrency
        ),

        // Sendable
        Flashcard(
            question: "What does Sendable mean?",
            answer: "A type safe to pass across concurrency boundaries. Value types are usually Sendable. Reference types need @unchecked Sendable or internal synchronization. Compiler enforces in Swift 6.",
            category: .concurrency
        ),
        Flashcard(
            question: "When do you use @unchecked Sendable?",
            answer: "When you've manually ensured thread safety (locks, atomics) but can't express it to the compiler. Use sparingly—you're taking responsibility for correctness.",
            category: .concurrency
        ),

        // Structured vs Unstructured Tasks
        Flashcard(
            question: "What's the difference between structured and unstructured tasks?",
            answer: "Structured: async let, TaskGroup—child tasks scoped to parent, auto-cancelled. Unstructured: Task { }—independent lifetime, must manage cancellation manually. Prefer structured when possible.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is async let?",
            answer: "Structured concurrency for parallel work: async let a = fetch1(); async let b = fetch2(); let results = await (a, b). Tasks auto-cancel if scope exits early.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is a TaskGroup?",
            answer: "Dynamic structured concurrency. withTaskGroup { group in group.addTask { } }. Tasks run in parallel, results collected. Group waits for all tasks. Cancelled if parent cancelled.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is ThrowingTaskGroup?",
            answer: "TaskGroup that propagates errors. withThrowingTaskGroup { }. If any child throws, group cancels other children and rethrows. Use for parallel operations that can fail.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is Task.detached?",
            answer: "Creates unstructured task that doesn't inherit actor context or priority. Task.detached { }. Runs independently. Use when you explicitly don't want inherited context.",
            category: .concurrency
        ),
        Flashcard(
            question: "What's the difference between Task { } and Task.detached { }?",
            answer: "Task { } inherits actor isolation and priority from context. Task.detached { } starts fresh, no inheritance. Use Task { } for MainActor work from MainActor context.",
            category: .concurrency
        ),

        // Continuations
        Flashcard(
            question: "What is a continuation?",
            answer: "Bridges callback-based code to async/await. withCheckedContinuation { continuation in callback { result in continuation.resume(returning: result) } }.",
            category: .concurrency
        ),
        Flashcard(
            question: "What's the difference between checked and unsafe continuation?",
            answer: "CheckedContinuation crashes if resumed twice or never (debug safety). UnsafeContinuation has no checks (faster). Use checked during development, unsafe for performance-critical code.",
            category: .concurrency
        ),
        Flashcard(
            question: "Why must continuations be resumed exactly once?",
            answer: "Resuming twice causes crash (checked) or undefined behavior (unsafe). Never resuming leaks the suspended task forever. Ensure all code paths resume continuation.",
            category: .concurrency
        ),

        // AsyncSequence & AsyncStream
        Flashcard(
            question: "What is AsyncSequence?",
            answer: "Protocol for async iteration. for await item in sequence { }. Like Sequence but each element may arrive asynchronously. Foundation types: URLSession.bytes, NotificationCenter.notifications.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is AsyncStream?",
            answer: "Creates AsyncSequence from callbacks/events. AsyncStream { continuation in source.onEvent { continuation.yield($0) } }. Bridges push-based APIs to async iteration.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is AsyncThrowingStream?",
            answer: "AsyncStream that can throw. continuation.finish(throwing: error). Use when the underlying source can produce errors.",
            category: .concurrency
        ),

        // Suspension Points
        Flashcard(
            question: "What is a suspension point?",
            answer: "Where async function may pause execution (await). Thread can do other work while waiting. After suspension, may resume on different thread. State may have changed.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is actor isolation?",
            answer: "Actor's mutable state only accessible from within the actor. External access requires await. Compiler enforces isolation. Prevents data races by serializing access.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is a global actor?",
            answer: "Actor that can be applied as attribute. @MainActor is built-in global actor. Define custom: @globalActor actor MyActor { static let shared = MyActor() }.",
            category: .concurrency
        ),

        // GCD Terms
        Flashcard(
            question: "What is GCD (Grand Central Dispatch)?",
            answer: "Apple's C-based concurrency API. DispatchQueue for serial/concurrent queues. Predates async/await. Still useful for specific patterns but prefer Swift concurrency for new code.",
            category: .concurrency
        ),
        Flashcard(
            question: "What's the difference between serial and concurrent queues?",
            answer: "Serial: one task at a time, FIFO order. Concurrent: multiple tasks simultaneously. Main queue is serial. Use serial for protecting shared state, concurrent for parallel work.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is DispatchGroup?",
            answer: "Groups multiple async operations, notifies when all complete. group.enter()/leave() to track. group.notify { } or group.wait(). Useful for coordinating GCD tasks.",
            category: .concurrency
        ),
        Flashcard(
            question: "What is a barrier in GCD?",
            answer: "queue.async(flags: .barrier) { }. Waits for pending tasks, executes alone, then resumes concurrent execution. Used for write operations in reader-writer pattern.",
            category: .concurrency
        ),
    ]

    static let testingCards: [Flashcard] = [
        // XCTest vs Swift Testing
        Flashcard(
            question: "What's the key difference between XCTest and Swift Testing?",
            answer: "Swift Testing uses @Test functions with #expect macros. XCTest uses classes inheriting XCTestCase with XCTAssert functions. Swift Testing has better diagnostics and modern Swift syntax.",
            category: .testing
        ),
        Flashcard(
            question: "How do you mark a function as a test in Swift Testing?",
            answer: "@Test func myTest() { }. Can be async throws. No test prefix required. Add display name: @Test(\"Human readable name\")",
            category: .testing
        ),
        Flashcard(
            question: "What does #expect do?",
            answer: "Asserts a condition is true. #expect(value == expected). On failure, shows both values with rich diagnostics. Continues test execution unlike #require.",
            category: .testing
        ),
        Flashcard(
            question: "What's the difference between #expect and #require?",
            answer: "#expect records failure but continues. #require stops the test immediately on failure—use for preconditions where continuing makes no sense.",
            category: .testing
        ),

        // Parameterized Tests
        Flashcard(
            question: "How do parameterized tests work?",
            answer: "@Test(arguments: [\"a\", \"b\", \"c\"]) func test(input: String) { }. Runs once per argument. Each run is independent and reported separately.",
            category: .testing
        ),
        Flashcard(
            question: "How do you test multiple parameter combinations?",
            answer: "Use zip for paired arguments: @Test(arguments: zip([1,2], [\"a\",\"b\"])). Or use two arguments arrays for cartesian product (every combination).",
            category: .testing
        ),

        // Organization
        Flashcard(
            question: "What does @Suite do?",
            answer: "Groups related tests. @Suite(\"Feature Tests\") struct FeatureTests { }. Can be nested. Traits applied to suite affect all tests inside.",
            category: .testing
        ),
        Flashcard(
            question: "How do you tag tests for filtering?",
            answer: "Define: extension Tag { @Tag static var slow: Self }. Apply: @Test(.tags(.slow)). Filter in Xcode or command line to run specific tags.",
            category: .testing
        ),

        // Traits
        Flashcard(
            question: "What test traits are available?",
            answer: ".disabled(\"reason\"), .enabled(if: condition), .timeLimit(.seconds(5)), .bug(\"url\"), .tags(), .serialized. Chain multiple: @Test(.tags(.slow), .timeLimit(.minutes(1)))",
            category: .testing
        ),
        Flashcard(
            question: "How do you skip a test conditionally?",
            answer: "@Test(.disabled(if: isCI, \"Flaky on CI\")) or @Test(.enabled(if: hasNetwork)). The condition is evaluated at runtime.",
            category: .testing
        ),
        Flashcard(
            question: "What does .serialized do?",
            answer: "Forces tests in a suite to run one at a time instead of parallel. Use when tests share state or resources. @Suite(.serialized) struct DatabaseTests { }",
            category: .testing
        ),

        // Error Testing
        Flashcard(
            question: "How do you test that code throws a specific error?",
            answer: "#expect(throws: MyError.notFound) { try service.fetch() }. For any error: #expect(throws: (any Error).self) { }",
            category: .testing
        ),
        Flashcard(
            question: "How do you verify code doesn't throw?",
            answer: "#expect(throws: Never.self) { try safeOperation() }. Fails if any error is thrown.",
            category: .testing
        ),

        // Dependency Injection
        Flashcard(
            question: "What is dependency injection for testing?",
            answer: "Pass dependencies (services, APIs) as parameters instead of creating them internally. Allows injecting mocks/fakes during tests for isolation and control.",
            category: .testing
        ),
        Flashcard(
            question: "What's the protocol-based mocking pattern?",
            answer: "Define protocol for dependency. Production type conforms to protocol. Test mock also conforms. Inject via initializer: init(service: ServiceProtocol = RealService())",
            category: .testing
        ),
        Flashcard(
            question: "When should you use a spy vs a stub?",
            answer: "Stub: returns canned responses. Spy: records calls for verification. Use stubs to control inputs, spies to verify interactions happened.",
            category: .testing
        ),

        // Async Testing
        Flashcard(
            question: "How do you test async code in Swift Testing?",
            answer: "@Test func asyncTest() async throws { let result = await service.fetch(); #expect(result.count > 0) }. No completion handlers needed.",
            category: .testing
        ),
        Flashcard(
            question: "How did XCTest handle async before async/await?",
            answer: "XCTestExpectation with wait(for:timeout:). Create expectation, fulfill() in callback, wait blocks until fulfilled or timeout. More boilerplate than async/await.",
            category: .testing
        ),
    ]

    static let swiftuiCards: [Flashcard] = [
        // State Management
        Flashcard(
            question: "What's the difference between @State and @Binding?",
            answer: "@State owns the data (source of truth). @Binding references data owned elsewhere. Parent uses @State, passes $state as Binding to child. Child can read/write but doesn't own.",
            category: .swiftui
        ),
        Flashcard(
            question: "What is @Observable (iOS 17+)?",
            answer: "Macro that makes class properties automatically trigger view updates. Replaces ObservableObject/@Published. Simpler: just mark class @Observable, no @Published needed.",
            category: .swiftui
        ),
        Flashcard(
            question: "When should you use @StateObject vs @ObservedObject?",
            answer: "@StateObject: view owns/creates the object (use in parent). @ObservedObject: view receives object from outside (use in child). Wrong choice causes object recreation bugs.",
            category: .swiftui
        ),
        Flashcard(
            question: "What does @Environment do?",
            answer: "Reads values from the environment (system or custom). @Environment(\\.colorScheme) var colorScheme. Inject custom values with .environment(\\.myKey, value).",
            category: .swiftui
        ),

        // View Lifecycle
        Flashcard(
            question: "What determines SwiftUI view identity?",
            answer: "Position in view hierarchy + explicit id(). Same identity = state preserved. Different identity = state reset. ForEach needs stable IDs for correct updates.",
            category: .swiftui
        ),
        Flashcard(
            question: "When is a view's body called?",
            answer: "When dependencies change (@State, @Binding, @Observable properties accessed in body). SwiftUI tracks dependencies automatically. Body may be called more than you expect.",
            category: .swiftui
        ),
        Flashcard(
            question: "What's the difference between onAppear and task?",
            answer: "onAppear: called when view appears, synchronous. task: async context, auto-cancelled when view disappears. Use task for async work, onAppear for sync setup.",
            category: .swiftui
        ),

        // Navigation
        Flashcard(
            question: "NavigationStack vs NavigationView?",
            answer: "NavigationStack (iOS 16+): value-based navigation, programmatic control via path. NavigationView: deprecated, link-based. Use NavigationStack for new code.",
            category: .swiftui
        ),
        Flashcard(
            question: "How does NavigationPath work?",
            answer: "@State private var path = NavigationPath(). Append values to navigate: path.append(item). Use .navigationDestination(for:) to define destination views.",
            category: .swiftui
        ),

        // Performance
        Flashcard(
            question: "How do you optimize List performance?",
            answer: "Use stable IDs in ForEach. Avoid complex computations in body. Extract subviews. Use LazyVStack for custom scrolling. Profile with Instruments.",
            category: .swiftui
        ),
        Flashcard(
            question: "What does equatable() modifier do?",
            answer: "Lets you control when view updates by comparing previous/current values. Reduces unnecessary body calls. Use when automatic dependency tracking is too broad.",
            category: .swiftui
        ),
        Flashcard(
            question: "When should you extract a subview?",
            answer: "When a section has independent state or complex logic. Extracted views only recompute their own body. Also improves readability and reusability.",
            category: .swiftui
        ),

        // Common Patterns
        Flashcard(
            question: "How do you pass actions to child views?",
            answer: "Pass closures: ChildView(onTap: { doSomething() }). Child stores as let onTap: () -> Void and calls it. Keeps child decoupled from parent logic.",
            category: .swiftui
        ),
        Flashcard(
            question: "What's a ViewModifier?",
            answer: "Reusable view transformation. struct MyModifier: ViewModifier { func body(content: Content) -> some View }. Apply with .modifier(MyModifier()) or custom extension.",
            category: .swiftui
        ),
        Flashcard(
            question: "How do you handle errors in SwiftUI?",
            answer: "Store error in @State. Show with .alert(isPresented:). For async: catch in task { }, set error state. Present user-friendly message, log details.",
            category: .swiftui
        ),
    ]
}
