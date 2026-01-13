import SwiftUI

// MARK: - Exercise: Find the concurrency bug(s) in this code
// This demonstrates actor reentrancy issues

actor BankAccountActor {
    private var balance: Double
    private var transactionLog: [String] = []

    init(initialBalance: Double) {
        self.balance = initialBalance
    }

    func withdraw(amount: Double) async -> Bool {
        // Check if we have sufficient funds
        guard balance >= amount else {
            log("Withdrawal of $\(amount) failed - insufficient funds")
            return false
        }

        // Simulate some async validation (e.g., fraud check)
        await performFraudCheck(amount: amount)

        // Now perform the withdrawal
        balance -= amount
        log("Withdrew $\(amount), new balance: $\(balance)")

        return true
    }

    func deposit(amount: Double) async {
        // Simulate async processing
        await processDeposit(amount: amount)

        balance += amount
        log("Deposited $\(amount), new balance: $\(balance)")
    }

    func getBalance() -> Double {
        return balance
    }

    func getTransactionLog() -> [String] {
        return transactionLog
    }

    private func log(_ message: String) {
        transactionLog.append("[\(Date().formatted(.dateTime.hour().minute().second()))]: \(message)")
    }

    private func performFraudCheck(amount: Double) async {
        // Simulate async fraud check
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    private func processDeposit(amount: Double) async {
        // Simulate async deposit processing
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

// Another actor with reentrancy issues
actor InventoryManager {
    private var stock: [String: Int] = [
        "iPhone": 10,
        "MacBook": 5,
        "AirPods": 20
    ]

    func reserveItem(_ item: String, quantity: Int) async -> Bool {
        guard let available = stock[item], available >= quantity else {
            return false
        }

        // Check with external service if item can be reserved
        let canReserve = await checkExternalInventory(item: item)

        guard canReserve else {
            return false
        }

        // Reserve the items
        stock[item] = available - quantity
        return true
    }

    func getStock() -> [String: Int] {
        return stock
    }

    private func checkExternalInventory(item: String) async -> Bool {
        // Simulate external API call
        try? await Task.sleep(nanoseconds: 200_000_000)
        return true
    }
}

struct ActorReentrancyView: View {
    @State private var bankAccount: BankAccountActor?
    @State private var inventory: InventoryManager?
    @State private var resultMessage = "Tap a test button to run the scenario"
    @State private var transactionLog: [String] = []
    @State private var isRunning = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Actor Reentrancy Issues")
                    .font(.headline)

                Text(resultMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                GroupBox("Bank Account Test") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Initial balance: $100")
                        Text("Two concurrent $60 withdrawals")
                        Text("Expected: Only one should succeed")

                        Button("Run Bank Test") {
                            runBankTest()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isRunning)
                    }
                }

                GroupBox("Inventory Test") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Initial stock: 10 iPhones")
                        Text("Two concurrent reserves of 6 each")
                        Text("Expected: Only one should succeed")

                        Button("Run Inventory Test") {
                            runInventoryTest()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isRunning)
                    }
                }

                if !transactionLog.isEmpty {
                    GroupBox("Transaction Log") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(transactionLog, id: \.self) { entry in
                                Text(entry)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Actor Reentrancy")
    }

    func runBankTest() {
        isRunning = true
        resultMessage = "Running..."
        transactionLog = []

        let account = BankAccountActor(initialBalance: 100)
        bankAccount = account

        Task {
            // Two concurrent withdrawals that together exceed the balance
            async let withdrawal1 = account.withdraw(amount: 60)
            async let withdrawal2 = account.withdraw(amount: 60)

            let results = await [withdrawal1, withdrawal2]
            let finalBalance = await account.getBalance()
            let log = await account.getTransactionLog()

            await MainActor.run {
                let successCount = results.filter { $0 }.count
                resultMessage = """
                Withdrawal 1 success: \(results[0])
                Withdrawal 2 success: \(results[1])
                Final balance: $\(finalBalance)

                \(successCount == 2 ? "BUG: Both succeeded! Balance went negative!" : "Correct: Only one succeeded")
                """
                transactionLog = log
                isRunning = false
            }
        }
    }

    func runInventoryTest() {
        isRunning = true
        resultMessage = "Running..."

        let inv = InventoryManager()
        inventory = inv

        Task {
            async let reserve1 = inv.reserveItem("iPhone", quantity: 6)
            async let reserve2 = inv.reserveItem("iPhone", quantity: 6)

            let results = await [reserve1, reserve2]
            let finalStock = await inv.getStock()

            await MainActor.run {
                let successCount = results.filter { $0 }.count
                resultMessage = """
                Reserve 1 success: \(results[0])
                Reserve 2 success: \(results[1])
                Final iPhone stock: \(finalStock["iPhone"] ?? 0)

                \(successCount == 2 ? "BUG: Both succeeded! Stock went negative!" : "Correct: Only one succeeded")
                """
                isRunning = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        ActorReentrancyView()
    }
}
