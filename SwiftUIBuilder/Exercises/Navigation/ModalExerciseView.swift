import SwiftUI

// MARK: - Exercise: Build various modal presentation patterns
// Requirements:
// 1. Sheet presentation with dismiss handling
// 2. Full screen cover for immersive experiences
// 3. Alert presentation
// 4. Confirmation dialog
// 5. Pass data back from modal to parent

struct ModalExerciseView: View {
    @State private var products: [Product] = []
    @State private var selectedProduct: Product?
    @State private var showAddSheet = false
    @State private var showFullScreenDetail = false
    @State private var productToDelete: Product?
    @State private var showDeleteConfirmation = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    var body: some View {
        List {
            Section {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Product", systemImage: "plus.circle.fill")
                }
            }

            Section("Products") {
                if isLoading {
                    ProgressView()
                } else {
                    ForEach(products) { product in
                        ProductModalRow(product: product)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedProduct = product
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    productToDelete = product
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Modal Patterns")
        .task {
            await loadProducts()
        }
        // Sheet presentation
        .sheet(isPresented: $showAddSheet) {
            AddProductSheet { newProductName in
                alertMessage = "Added: \(newProductName)"
                showAlert = true
            }
        }
        // Item-based sheet
        .sheet(item: $selectedProduct) { product in
            ProductDetailModal(product: product) {
                showFullScreenDetail = true
            }
        }
        // Confirmation dialog
        .confirmationDialog(
            "Delete Product",
            isPresented: $showDeleteConfirmation,
            presenting: productToDelete
        ) { product in
            Button("Delete \(product.name)", role: .destructive) {
                deleteProduct(product)
            }
            Button("Cancel", role: .cancel) {}
        } message: { product in
            Text("Are you sure you want to delete \(product.name)?")
        }
        // Alert
        .alert("Success", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        // Full screen cover
        .fullScreenCover(isPresented: $showFullScreenDetail) {
            if let product = selectedProduct {
                FullScreenProductView(product: product)
            }
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

    private func deleteProduct(_ product: Product) {
        products.removeAll { $0.id == product.id }
        alertMessage = "Deleted: \(product.name)"
        showAlert = true
    }
}

struct ProductModalRow: View {
    let product: Product

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.headline)
                Text("$\(product.price, specifier: "%.0f")")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
    }
}

struct AddProductSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var productName = ""
    let onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Product Name", text: $productName)
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(productName)
                        dismiss()
                    }
                    .disabled(productName.isEmpty)
                }
            }
        }
    }
}

struct ProductDetailModal: View {
    let product: Product
    let onShowFullScreen: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.5))
                    }

                Text(product.name)
                    .font(.title)
                    .fontWeight(.bold)

                Text(product.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("$\(product.price, specifier: "%.0f")")
                    .font(.title2)
                    .foregroundColor(.green)

                Button("View Full Screen") {
                    dismiss()
                    onShowFullScreen()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Product Detail")
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

struct FullScreenProductView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.blue.opacity(0.1).ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)

                Text(product.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(product.description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("$\(product.price, specifier: "%.0f")")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.green)

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ModalExerciseView()
    }
}
