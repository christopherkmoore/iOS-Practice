import SwiftUI

// MARK: - Exercise: Find the concurrency bug(s) in this code
// This demonstrates a cache system with thread safety issues

class DataCache {
    private let queue = DispatchQueue(label: "com.app.cache")
    private var cache: [String: Any] = [:]
    private var metadata: [String: Date] = [:]

    func getValue(forKey key: String) -> Any? {
        queue.sync {
            return cache[key]
        }
    }

    func setValue(_ value: Any, forKey key: String) {
        queue.sync {
            cache[key] = value
            updateMetadata(forKey: key)
        }
    }

    private func updateMetadata(forKey key: String) {
        queue.sync {
            metadata[key] = Date()
        }
    }

    func getAllKeys() -> [String] {
        queue.sync {
            return Array(cache.keys)
        }
    }

    func clearOldEntries(olderThan interval: TimeInterval) {
        queue.sync {
            let cutoff = Date().addingTimeInterval(-interval)
            for (key, date) in metadata {
                if date < cutoff {
                    removeValue(forKey: key)
                }
            }
        }
    }

    func removeValue(forKey key: String) {
        queue.sync {
            cache.removeValue(forKey: key)
            metadata.removeValue(forKey: key)
        }
    }
}

// Another example with multiple locks
class BankAccount {
    private let balanceLock = NSLock()
    private let transactionLock = NSLock()

    private var balance: Double = 1000.0
    private var transactionHistory: [String] = []

    func transfer(amount: Double, to other: BankAccount) {
        balanceLock.lock()
        defer { balanceLock.unlock() }

        if balance >= amount {
            // Log this transaction first
            logTransaction("Sending $\(amount)")

            balance -= amount
            other.receive(amount: amount, from: self)
        }
    }

    func receive(amount: Double, from sender: BankAccount) {
        balanceLock.lock()
        defer { balanceLock.unlock() }

        balance += amount
        logTransaction("Received $\(amount)")
    }

    private func logTransaction(_ message: String) {
        transactionLock.lock()
        defer { transactionLock.unlock() }

        // Need to read balance for the log
        balanceLock.lock()
        transactionHistory.append("\(message) - Balance: \(balance)")
        balanceLock.unlock()
    }

    func getBalance() -> Double {
        balanceLock.lock()
        defer { balanceLock.unlock() }
        return balance
    }
}

struct DeadlockView: View {
    @State private var resultMessage = "This exercise demonstrates deadlock scenarios.\n\nWARNING: Running these will freeze the app!"
    @State private var showAlert = false
    @State private var selectedExample = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Deadlock Examples")
                .font(.headline)

            Text(resultMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)

            Picker("Example", selection: $selectedExample) {
                Text("Cache (Queue Reentry)").tag(0)
                Text("Bank (Lock Ordering)").tag(1)
            }
            .pickerStyle(.segmented)

            Button("Run (Will Deadlock!)") {
                showAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Study the code to find:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("• Where does the deadlock occur?")
                Text("• Why does it happen?")
                Text("• How would you fix it?")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Deadlock")
        .alert("Are you sure?", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Run Anyway", role: .destructive) {
                runDeadlockExample()
            }
        } message: {
            Text("This will freeze the app and require a restart.")
        }
    }

    func runDeadlockExample() {
        if selectedExample == 0 {
            // Cache example - sync on same queue
            let cache = DataCache()
            cache.setValue("test", forKey: "key1")
        } else {
            // Bank example - would need concurrent transfers to demonstrate
            let account1 = BankAccount()
            let account2 = BankAccount()

            DispatchQueue.global().async {
                account1.transfer(amount: 100, to: account2)
            }
            DispatchQueue.global().async {
                account2.transfer(amount: 50, to: account1)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DeadlockView()
    }
}
