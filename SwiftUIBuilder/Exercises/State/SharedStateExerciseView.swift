import SwiftUI

// MARK: - Exercise: Demonstrate shared state patterns
// Requirements:
// 1. Use @StateObject, @ObservedObject, @EnvironmentObject appropriately
// 2. Show a shopping cart that persists across views
// 3. Badge showing item count in navigation
// 4. Proper state propagation through view hierarchy

class CartManager: ObservableObject {
    @Published var items: [CartItem] = []

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }

    func addToCart(_ product: Product) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(product: product, quantity: 1))
        }
    }

    func removeFromCart(_ product: Product) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            if items[index].quantity > 1 {
                items[index].quantity -= 1
            } else {
                items.remove(at: index)
            }
        }
    }

    func clearCart() {
        items.removeAll()
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let product: Product
    var quantity: Int
}

struct SharedStateExerciseView: View {
    @StateObject private var cartManager = CartManager()
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var showCart = false

    var body: some View {
        List {
            Section {
                Text("This demo shows @StateObject owned by parent, passed as @EnvironmentObject to children")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Products") {
                if isLoading {
                    ProgressView()
                } else {
                    ForEach(products) { product in
                        ProductCartRow(product: product)
                    }
                }
            }
        }
        .navigationTitle("Shop")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCart = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart")

                        if cartManager.totalItems > 0 {
                            Text("\(cartManager.totalItems)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCart) {
            CartView()
        }
        .environmentObject(cartManager)
        .task {
            await loadProducts()
        }
    }

    private func loadProducts() async {
        isLoading = true
        do {
            products = try await MockAPIService.shared.fetchProducts()
        } catch {
            // Handle error
        }
        isLoading = false
    }
}

struct ProductCartRow: View {
    let product: Product
    @EnvironmentObject var cartManager: CartManager

    var quantityInCart: Int {
        cartManager.items.first(where: { $0.product.id == product.id })?.quantity ?? 0
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                Text("$\(product.price, specifier: "%.0f")")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            Spacer()

            if quantityInCart > 0 {
                HStack(spacing: 12) {
                    Button {
                        cartManager.removeFromCart(product)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }

                    Text("\(quantityInCart)")
                        .fontWeight(.semibold)
                        .frame(minWidth: 20)

                    Button {
                        cartManager.addToCart(product)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Button("Add") {
                    cartManager.addToCart(product)
                }
                .buttonStyle(.bordered)
                .disabled(!product.inStock)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if cartManager.items.isEmpty {
                    ContentUnavailableView(
                        "Cart Empty",
                        systemImage: "cart",
                        description: Text("Add some products to your cart")
                    )
                } else {
                    List {
                        ForEach(cartManager.items) { item in
                            CartItemRow(item: item)
                        }
                        .onDelete { indexSet in
                            cartManager.items.remove(atOffsets: indexSet)
                        }

                        Section {
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text("$\(cartManager.totalPrice, specifier: "%.2f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }

                        Section {
                            Button {
                                // Checkout action
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Checkout")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Clear Cart", role: .destructive) {
                                cartManager.clearCart()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cart (\(cartManager.totalItems))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    @EnvironmentObject var cartManager: CartManager

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.product.name)
                    .font(.headline)
                Text("$\(item.product.price, specifier: "%.0f") each")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    cartManager.removeFromCart(item.product)
                } label: {
                    Image(systemName: "minus.circle")
                }

                Text("\(item.quantity)")
                    .frame(minWidth: 24)

                Button {
                    cartManager.addToCart(item.product)
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
            .buttonStyle(.plain)

            Text("$\(item.product.price * Double(item.quantity), specifier: "%.0f")")
                .fontWeight(.semibold)
                .frame(width: 60, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationStack {
        SharedStateExerciseView()
    }
}
