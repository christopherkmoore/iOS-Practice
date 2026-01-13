# iOS Interview Practice Projects

Three Xcode projects designed for senior iOS interview preparation, covering concurrency bugs, SwiftUI development, and unit testing.

**Requirements:** Xcode 15+, iOS 17+

---

## Quick Start

```bash
git clone https://github.com/christopherkmoore/iOS-Practice.git
cd iOS-Practice
```

Each project includes a pre-generated `.xcodeproj`. Open any project directly:

```bash
open ConcurrencyBugHunt/ConcurrencyBugHunt.xcodeproj
open SwiftUIBuilder/SwiftUIBuilder.xcodeproj
open TestabilityWorkshop/TestabilityWorkshop.xcodeproj
```

**Using xcodegen?** Each project also includes a `project.yml` for regeneration:
```bash
cd ConcurrencyBugHunt && xcodegen generate
```

---

## Projects Overview

### 1. ConcurrencyBugHunt

**Purpose:** Code review practice — identify and fix concurrency bugs

**How to use:**
- Run the app and navigate to each exercise
- Each view contains intentionally buggy code
- Read the code, identify the bug(s), then verify by running
- Try to fix each bug before looking at solutions

| Section | Exercises | Key Bugs |
|---------|-----------|----------|
| **GCD Issues** | Race Condition | Unsynchronized shared mutable state |
| | Main Thread Violation | UI updates from background thread |
| | Deadlock | Sync dispatch to current queue, lock ordering |
| **Async/Await** | Task Cancellation | Missing cancellation checks, stale results |
| | Actor Reentrancy | State changes during await suspension |
| | Unstructured Task Leak | Tasks outliving views, missing cleanup |
| **Combine** | Publisher Retain Cycle | Strong self in sink closures |
| | Missing Cancellable | Subscriptions not stored |

---

### 2. SwiftUIBuilder

**Purpose:** Build UI iteratively with mock API data

**How to use:**
- Each exercise is a complete, working implementation
- Study the patterns, then try recreating from scratch
- Modify and extend to practice variations

| Section | Exercises | Patterns Covered |
|---------|-----------|------------------|
| **Lists** | Basic API List | async/await data loading, error states |
| | Pull to Refresh | `.refreshable`, last-updated timestamp |
| | Search & Filter | `.searchable`, debounced search, combined filters |
| **Grids** | Photo Grid | `LazyVGrid`, category filtering, sheet presentation |
| | Adaptive Grid | `GridItem(.adaptive)`, list/grid toggle with animation |
| **Navigation** | Master-Detail | `NavigationLink(value:)`, `navigationDestination` |
| | Modal Presentation | `.sheet`, `.fullScreenCover`, `.confirmationDialog`, `.alert` |
| **State** | Form Validation | Real-time validation, password strength, submit gating |
| | Shared State | `@StateObject`, `@EnvironmentObject`, cart pattern |

**Shared Resources:**
- `MockAPIService.swift` — Actor-based mock API with simulated delays and random failures
- Models: `User`, `Post`, `Photo`, `Product`

---

### 3. TestabilityWorkshop

**Purpose:** Refactor untestable code and write comprehensive tests

**How to use:**
1. Read the "Before" (untestable) code in each exercise
2. Study the "After" (testable) refactored version
3. Examine the corresponding test file
4. Practice writing tests yourself before looking at solutions
5. Run tests with `Cmd+U`

| Section | Exercise | Refactoring Pattern |
|---------|----------|---------------------|
| **Dependency Injection** | Singleton Dependencies | Extract protocols, inject via initializer |
| | Network Coupling | `HTTPClient` protocol, mock responses |
| | Date/Time | `DateProviding` protocol, controllable time |
| **Side Effects** | UserDefaults | `KeyValueStore` protocol, in-memory store |
| | File System | `FileSystemProtocol`, in-memory fake |
| **Architecture** | ViewModel Testing | `@MainActor`, state transitions, `@Published` |
| | Protocol Mocking | Spy/Stub/Fake patterns, call verification |
| **Async** | Async/Await Testing | Async test methods, Task cancellation |

**Test Target Structure:**
```
TestabilityWorkshopTests/
├── Mocks/TestMocks.swift    # Reusable mock implementations
├── SingletonExerciseTests.swift
├── NetworkCouplingExerciseTests.swift
├── DateTimeExerciseTests.swift
├── UserDefaultsExerciseTests.swift
├── FileSystemExerciseTests.swift
├── ViewModelExerciseTests.swift
├── ProtocolMockingExerciseTests.swift
└── AsyncTestingExerciseTests.swift
```

---

## Topics Covered

### Concurrency
- [x] GCD: `DispatchQueue`, serial vs concurrent, `sync` vs `async`
- [x] Race conditions and data races
- [x] Main thread safety for UI updates
- [x] Deadlocks (queue reentry, lock ordering)
- [x] Swift Concurrency: `async`/`await`, `Task`, `TaskGroup`
- [x] Task cancellation and cooperative cancellation
- [x] Actor isolation and reentrancy
- [x] Structured vs unstructured concurrency
- [x] Combine: Publishers, Subscribers, `AnyCancellable`, retain cycles

### SwiftUI
- [x] State management: `@State`, `@Binding`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`
- [x] Lists and `ForEach`
- [x] `LazyVGrid`/`LazyHGrid` with `GridItem`
- [x] Navigation: `NavigationStack`, `NavigationLink`, `navigationDestination`
- [x] Sheets, full-screen covers, alerts, confirmation dialogs
- [x] `.searchable` and `.refreshable` modifiers
- [x] `.task` for async data loading
- [x] Form validation patterns
- [x] Animations and transitions

### Testing (XCTest)
- [x] Test structure: Arrange-Act-Assert
- [x] `setUp()` and `tearDown()`
- [x] Dependency injection for testability
- [x] Protocol-based mocking (Stub, Spy, Fake)
- [x] Testing `@Published` properties
- [x] `@MainActor` test classes for ViewModels
- [x] Async test methods (`func test_x() async`)
- [x] Testing error cases with `XCTAssertThrowsError`
- [x] Verifying mock interactions (call counts, arguments)

### Swift Fundamentals (embedded throughout)
- [x] Protocols and protocol extensions
- [x] Generics
- [x] Value types vs reference types
- [x] Access control
- [x] Error handling
- [x] Closures and capture lists (`[weak self]`)
- [x] `Codable`
- [x] `Result` type

---

## Interview Practice Tips

### For Code Review (ConcurrencyBugHunt)
1. **Read systematically** — Don't jump to conclusions
2. **Look for shared mutable state** — Who reads? Who writes? When?
3. **Trace the thread** — Which queue/actor is this running on?
4. **Check completion handlers** — Are they always called? Only once?
5. **Verify cancellation** — Is `Task.isCancelled` checked after awaits?

### For Building UI (SwiftUIBuilder)
1. **Start with the data model** — What state do you need?
2. **Choose the right property wrapper** — Who owns this state?
3. **Handle loading/error/empty states** — Always show something
4. **Test on device** — Simulators hide performance issues

### For Testing (TestabilityWorkshop)
1. **Test behavior, not implementation** — What should happen, not how
2. **One assertion focus per test** — Tests should fail for one reason
3. **Use descriptive test names** — `test_methodName_condition_expectedResult`
4. **Inject everything** — If you can't inject it, you can't test it
5. **Reset mocks in tearDown** — Tests must be independent

---

## Running the Projects

```bash
# Open in Xcode
open ConcurrencyBugHunt/ConcurrencyBugHunt.xcodeproj
open SwiftUIBuilder/SwiftUIBuilder.xcodeproj
open TestabilityWorkshop/TestabilityWorkshop.xcodeproj

# Run tests (TestabilityWorkshop)
# Cmd+U in Xcode, or:
xcodebuild test -project TestabilityWorkshop/TestabilityWorkshop.xcodeproj \
  -scheme TestabilityWorkshop \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## File Structure

```
iOS-Practice/
├── README.md                          # This file
├── ConcurrencyBugHunt/
│   ├── ConcurrencyBugHuntApp.swift
│   ├── ContentView.swift
│   └── Exercises/
│       ├── GCD/
│       ├── AsyncAwait/
│       └── Combine/
├── SwiftUIBuilder/
│   ├── SwiftUIBuilderApp.swift
│   ├── ContentView.swift
│   ├── Shared/MockAPIService.swift
│   └── Exercises/
│       ├── List/
│       ├── Grid/
│       ├── Navigation/
│       └── State/
└── TestabilityWorkshop/
    ├── TestabilityWorkshopApp.swift
    ├── ContentView.swift
    ├── Exercises/
    │   ├── DependencyInjection/
    │   ├── SideEffects/
    │   ├── Architecture/
    │   └── Async/
    └── TestabilityWorkshopTests/
        ├── Mocks/TestMocks.swift
        └── *Tests.swift
```
