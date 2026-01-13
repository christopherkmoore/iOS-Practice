import SwiftUI

// MARK: - Exercise: Find the concurrency bug(s) in this code
// This view simulates a shopping cart that multiple operations can modify

class ShoppingCart {
    private var items: [String: Int] = [:]
    private var totalPrice: Double = 0

    func addItem(_ name: String, price: Double, quantity: Int = 1) {
        // Simulate some processing delay
        Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.01))

        if let existing = items[name] {
            items[name] = existing + quantity
        } else {
            items[name] = quantity
        }
        totalPrice += price * Double(quantity)
    }

    func removeItem(_ name: String, price: Double) {
        Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.01))

        if let quantity = items[name] {
            if quantity > 1 {
                items[name] = quantity - 1
            } else {
                items.removeValue(forKey: name)
            }
            totalPrice -= price
        }
    }

    func getItemCount() -> Int {
        return items.values.reduce(0, +)
    }

    func getTotalPrice() -> Double {
        return totalPrice
    }

    func getItems() -> [String: Int] {
        return items
    }

    func clear() {
        items.removeAll()
        totalPrice = 0
    }
}

struct RaceConditionView: View {
    @State private var cart = ShoppingCart()
    @State private var resultMessage = "Tap 'Run Test' to simulate concurrent cart operations"
    @State private var isRunning = false

    let products = [
        ("iPhone", 999.0),
        ("MacBook", 1999.0),
        ("AirPods", 249.0),
        ("iPad", 799.0),
        ("Apple Watch", 399.0)
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Shopping Cart Race Condition")
                .font(.headline)

            Text(resultMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            Button(isRunning ? "Running..." : "Run Test") {
                runConcurrencyTest()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)

            Spacer()

            Text("Expected: 50 items added, then 25 removed = 25 items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Race Condition")
    }

    func runConcurrencyTest() {
        isRunning = true
        cart.clear()
        resultMessage = "Running concurrent operations..."

        let group = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "cart.concurrent", attributes: .concurrent)

        // Simulate multiple threads adding items
        for i in 0..<50 {
            group.enter()
            concurrentQueue.async {
                let product = products[i % products.count]
                cart.addItem(product.0, price: product.1)
                group.leave()
            }
        }

        // Simulate multiple threads removing items while adds are happening
        for i in 0..<25 {
            group.enter()
            concurrentQueue.async {
                let product = products[i % products.count]
                cart.removeItem(product.0, price: product.1)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let finalCount = cart.getItemCount()
            let finalPrice = cart.getTotalPrice()
            let items = cart.getItems()

            resultMessage = """
            Final item count: \(finalCount)
            Final total price: $\(String(format: "%.2f", finalPrice))
            Items: \(items)

            Run multiple times - results will vary!
            """
            isRunning = false
        }
    }
}

#Preview {
    NavigationStack {
        RaceConditionView()
    }
}
