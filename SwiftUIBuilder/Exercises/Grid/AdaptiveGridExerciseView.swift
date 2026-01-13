import SwiftUI

// MARK: - Exercise: Build an adaptive grid that changes based on device/orientation
// Requirements:
// 1. Grid adapts to screen size (more columns on larger screens)
// 2. Use adaptive GridItem
// 3. Support both list and grid view toggle
// 4. Animate between view modes

struct AdaptiveGridExerciseView: View {
    @State private var products: [Product] = []
    @State private var isGridView = true
    @State private var isLoading = false

    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)]
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if products.isEmpty {
                ContentUnavailableView("No Products", systemImage: "bag")
                    .frame(minHeight: 200)
            } else {
                if isGridView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(products) { product in
                            ProductGridCard(product: product)
                        }
                    }
                    .padding()
                    .transition(.opacity)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(products) { product in
                            ProductListCard(product: product)
                        }
                    }
                    .padding()
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut, value: isGridView)
        .navigationTitle("Products")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isGridView.toggle()
                } label: {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                }
            }
        }
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

struct ProductGridCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "bag.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue.opacity(0.5))
                }

            Text(product.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            HStack {
                Text("$\(product.price, specifier: "%.0f")")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()

                if !product.inStock {
                    Text("Out")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

struct ProductListCard: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "bag.fill")
                        .foregroundColor(.blue.opacity(0.5))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)

                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("$\(product.price, specifier: "%.0f")")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            Spacer()

            if product.inStock {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Text("Out of Stock")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

#Preview {
    NavigationStack {
        AdaptiveGridExerciseView()
    }
}
