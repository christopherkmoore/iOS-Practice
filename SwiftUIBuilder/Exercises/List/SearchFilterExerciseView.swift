import SwiftUI

// MARK: - Exercise: Build a searchable and filterable product list
// Requirements:
// 1. Search bar that filters products by name/description
// 2. Category filter (segmented control or picker)
// 3. Toggle to show only in-stock items
// 4. Display product count based on current filters
// 5. Debounce search to avoid excessive API calls

struct SearchFilterExerciseView: View {
    @State private var products: [Product] = []
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showInStockOnly = false
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>?

    let categories = ["All", "Electronics", "Wearables", "Accessories"]

    var filteredProducts: [Product] {
        products.filter { product in
            let matchesStock = !showInStockOnly || product.inStock
            let matchesCategory = selectedCategory == "All" || product.category == selectedCategory
            return matchesStock && matchesCategory
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("In Stock Only", isOn: $showInStockOnly)
            }

            Section {
                HStack {
                    Text("Showing")
                    Spacer()
                    Text("\(filteredProducts.count) of \(products.count) products")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }

            Section("Products") {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if filteredProducts.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(filteredProducts) { product in
                        ProductRowView(product: product)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search products...")
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
        }
        .navigationTitle("Products")
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

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            Task { await loadProducts() }
            return
        }

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }

            isLoading = true
            do {
                products = try await MockAPIService.shared.searchProducts(query: query)
            } catch {
                if !Task.isCancelled {
                    // Handle error
                }
            }
            isLoading = false
        }
    }
}

struct ProductRowView: View {
    let product: Product

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)

                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack {
                    Text("$\(product.price, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(product.category)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
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
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SearchFilterExerciseView()
    }
}
