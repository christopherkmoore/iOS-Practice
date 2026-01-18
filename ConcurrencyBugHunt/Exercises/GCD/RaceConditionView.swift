import SwiftUI

// MARK: - Exercise: Find the concurrency bug(s) in this code
// This view simulates a shopping cart that multiple operations can modify

class ShoppingCart {
    private var items: [String: Int] = [:]
    private var totalPrice: Double = 0
    private var queue = DispatchQueue(label: "concurrency.queue")
    
    func addItem(_ name: String, price: Double, quantity: Int = 1) {
        // Simulate some processing delay
        Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.01))
        
        queue.sync {
            if let existing = items[name] {
                items[name] = existing + quantity
            } else {
                items[name] = quantity
            }
            totalPrice += price * Double(quantity)
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
    @State private var operationCount: Double = 10

    let products = [
        ("iPhone", 999.0),
        ("MacBook", 1999.0),
        ("AirPods", 249.0),
        ("iPad", 799.0),
        ("Apple Watch", 399.0)
    ]

    private var addCount: Int { Int(operationCount) }

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

            VStack(spacing: 8) {
                Text("Concurrent Operations: \(addCount)")
                    .font(.subheadline)
                Slider(value: $operationCount, in: 2...100, step: 2)
                Text("Low values = wrong counts. High values = crashes.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Button(isRunning ? "Running..." : "Run Test") {
                runConcurrencyTest()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)

            Spacer()

            Text("Expected: \(addCount) items")
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

        // Add items concurrently
        for i in 0..<addCount {
            group.enter()
            concurrentQueue.async {
                let product = self.products[i % self.products.count]
                self.cart.addItem(product.0, price: product.1)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let finalCount = self.cart.getItemCount()
            let finalPrice = self.cart.getTotalPrice()
            let items = self.cart.getItems()

            self.resultMessage = """
            Final item count: \(finalCount)
            Final total price: $\(String(format: "%.2f", finalPrice))
            Items: \(items)

            Run multiple times - results will vary!
            """
            self.isRunning = false
        }
    }
}

#Preview {
    NavigationStack {
        RaceConditionView()
    }
}
