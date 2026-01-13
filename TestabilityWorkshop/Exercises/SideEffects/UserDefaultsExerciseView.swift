import SwiftUI
import Foundation

// MARK: - Exercise: Make UserDefaults access testable
// Direct UserDefaults access makes tests pollute shared state and affect other tests

struct UserDefaultsExerciseView: View {
    var body: some View {
        List {
            Section {
                Text("Direct UserDefaults.standard access makes tests affect each other and pollute the real app's data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Problems with Direct Access") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Tests modify real user preferences")
                    Text("• Tests affect each other (shared state)")
                    Text("• Can't test 'first launch' scenarios")
                    Text("• Hard to reset state between tests")
                }
                .font(.caption)
            }

            Section("Key Refactoring Steps") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Create KeyValueStore protocol")
                    Text("2. Make UserDefaults conform to protocol")
                    Text("3. Create InMemoryKeyValueStore for tests")
                    Text("4. Inject store via initializer")
                }
                .font(.caption)
            }
        }
        .navigationTitle("UserDefaults Access")
    }
}

// MARK: - BEFORE: Untestable Code

// ❌ UNTESTABLE: Direct UserDefaults access
class OnboardingManagerBefore {
    private let hasSeenOnboardingKey = "hasSeenOnboarding"
    private let lastVersionKey = "lastAppVersion"
    private let launchCountKey = "launchCount"

    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenOnboardingKey) }
    }

    var lastAppVersion: String? {
        get { UserDefaults.standard.string(forKey: lastVersionKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastVersionKey) }
    }

    var launchCount: Int {
        get { UserDefaults.standard.integer(forKey: launchCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: launchCountKey) }
    }

    func incrementLaunchCount() {
        launchCount += 1
    }

    func shouldShowOnboarding() -> Bool {
        return !hasSeenOnboarding
    }

    func shouldShowWhatsNew(currentVersion: String) -> Bool {
        guard let lastVersion = lastAppVersion else {
            return false // First install, show onboarding instead
        }
        return lastVersion != currentVersion
    }

    func shouldShowRatePrompt() -> Bool {
        return launchCount >= 5 && launchCount % 10 == 0
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
    }

    func updateVersion(to version: String) {
        lastAppVersion = version
    }
}

// MARK: - AFTER: Testable Code

// Step 1: Define storage protocol
protocol KeyValueStore {
    func bool(forKey key: String) -> Bool
    func string(forKey key: String) -> String?
    func integer(forKey key: String) -> Int
    func setBool(_ value: Bool, forKey key: String)
    func setString(_ value: String?, forKey key: String)
    func setInt(_ value: Int, forKey key: String)
    func removeObject(forKey key: String)
}

// Step 2: Make UserDefaults conform to protocol
extension UserDefaults: KeyValueStore {
    func setBool(_ value: Bool, forKey key: String) {
        set(value, forKey: key)
    }

    func setString(_ value: String?, forKey key: String) {
        set(value, forKey: key)
    }

    func setInt(_ value: Int, forKey key: String) {
        set(value, forKey: key)
    }
}

// ✅ TESTABLE: Storage is injected
class OnboardingManagerAfter {
    private let store: KeyValueStore

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let lastVersion = "lastAppVersion"
        static let launchCount = "launchCount"
    }

    init(store: KeyValueStore = UserDefaults.standard) {
        self.store = store
    }

    var hasSeenOnboarding: Bool {
        get { store.bool(forKey: Keys.hasSeenOnboarding) }
        set { store.setBool(newValue, forKey: Keys.hasSeenOnboarding) }
    }

    var lastAppVersion: String? {
        get { store.string(forKey: Keys.lastVersion) }
        set { store.setString(newValue, forKey: Keys.lastVersion) }
    }

    var launchCount: Int {
        get { store.integer(forKey: Keys.launchCount) }
        set { store.setInt(newValue, forKey: Keys.launchCount) }
    }

    func incrementLaunchCount() {
        launchCount += 1
    }

    func shouldShowOnboarding() -> Bool {
        return !hasSeenOnboarding
    }

    func shouldShowWhatsNew(currentVersion: String) -> Bool {
        guard let lastVersion = lastAppVersion else {
            return false
        }
        return lastVersion != currentVersion
    }

    func shouldShowRatePrompt() -> Bool {
        return launchCount >= 5 && launchCount % 10 == 0
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
    }

    func updateVersion(to version: String) {
        lastAppVersion = version
    }
}

// MARK: - Example Tests
/*

 // In-memory store for testing
 class InMemoryKeyValueStore: KeyValueStore {
     private var storage: [String: Any] = [:]

     func bool(forKey key: String) -> Bool {
         storage[key] as? Bool ?? false
     }

     func string(forKey key: String) -> String? {
         storage[key] as? String
     }

     func integer(forKey key: String) -> Int {
         storage[key] as? Int ?? 0
     }

     func set(_ value: Bool, forKey key: String) {
         storage[key] = value
     }

     func set(_ value: String?, forKey key: String) {
         if let value = value {
             storage[key] = value
         } else {
             storage.removeValue(forKey: key)
         }
     }

     func set(_ value: Int, forKey key: String) {
         storage[key] = value
     }

     func removeObject(forKey key: String) {
         storage.removeValue(forKey: key)
     }

     // Helper for tests
     func reset() {
         storage.removeAll()
     }
 }

 class OnboardingManagerTests: XCTestCase {

     var store: InMemoryKeyValueStore!
     var sut: OnboardingManagerAfter!

     override func setUp() {
         store = InMemoryKeyValueStore()
         sut = OnboardingManagerAfter(store: store)
     }

     override func tearDown() {
         store.reset()
     }

     // MARK: - shouldShowOnboarding Tests

     func test_shouldShowOnboarding_onFirstLaunch_returnsTrue() {
         XCTAssertTrue(sut.shouldShowOnboarding())
     }

     func test_shouldShowOnboarding_afterCompletion_returnsFalse() {
         sut.completeOnboarding()
         XCTAssertFalse(sut.shouldShowOnboarding())
     }

     // MARK: - shouldShowWhatsNew Tests

     func test_shouldShowWhatsNew_onFirstInstall_returnsFalse() {
         XCTAssertFalse(sut.shouldShowWhatsNew(currentVersion: "1.0.0"))
     }

     func test_shouldShowWhatsNew_whenVersionChanged_returnsTrue() {
         sut.updateVersion(to: "1.0.0")
         XCTAssertTrue(sut.shouldShowWhatsNew(currentVersion: "2.0.0"))
     }

     func test_shouldShowWhatsNew_whenVersionSame_returnsFalse() {
         sut.updateVersion(to: "1.0.0")
         XCTAssertFalse(sut.shouldShowWhatsNew(currentVersion: "1.0.0"))
     }

     // MARK: - shouldShowRatePrompt Tests

     func test_shouldShowRatePrompt_atLaunchCount5_returnsFalse() {
         // 5 % 10 != 0
         store.set(5, forKey: "launchCount")
         XCTAssertFalse(sut.shouldShowRatePrompt())
     }

     func test_shouldShowRatePrompt_atLaunchCount10_returnsTrue() {
         store.set(10, forKey: "launchCount")
         XCTAssertTrue(sut.shouldShowRatePrompt())
     }

     func test_shouldShowRatePrompt_atLaunchCount20_returnsTrue() {
         store.set(20, forKey: "launchCount")
         XCTAssertTrue(sut.shouldShowRatePrompt())
     }

     func test_shouldShowRatePrompt_atLaunchCount3_returnsFalse() {
         store.set(3, forKey: "launchCount")
         XCTAssertFalse(sut.shouldShowRatePrompt()) // Less than 5
     }

     // MARK: - incrementLaunchCount Tests

     func test_incrementLaunchCount_incrementsFromZero() {
         sut.incrementLaunchCount()
         XCTAssertEqual(sut.launchCount, 1)
     }

     func test_incrementLaunchCount_incrementsExistingValue() {
         store.set(10, forKey: "launchCount")
         sut.incrementLaunchCount()
         XCTAssertEqual(sut.launchCount, 11)
     }
 }

 */

#Preview {
    NavigationStack {
        UserDefaultsExerciseView()
    }
}
