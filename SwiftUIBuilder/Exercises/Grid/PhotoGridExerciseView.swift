import SwiftUI

// MARK: - Exercise: Build a photo grid using LazyVGrid
// Requirements:
// 1. Display photos in a 3-column grid
// 2. Each cell shows a colored placeholder with title overlay
// 3. Tapping a photo shows a detail sheet
// 4. Category filter at the top

struct PhotoGridExerciseView: View {
    @State private var photos: [Photo] = []
    @State private var selectedCategory = "All"
    @State private var selectedPhoto: Photo?
    @State private var isLoading = false

    let categories = ["All", "Nature", "Urban"]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var filteredPhotos: [Photo] {
        if selectedCategory == "All" {
            return photos
        }
        return photos.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if filteredPhotos.isEmpty {
                    ContentUnavailableView("No Photos", systemImage: "photo.on.rectangle.angled")
                        .frame(minHeight: 200)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filteredPhotos) { photo in
                            PhotoGridCell(photo: photo)
                                .onTapGesture {
                                    selectedPhoto = photo
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Photos")
        .task {
            await loadPhotos()
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailSheet(photo: photo)
        }
    }

    private func loadPhotos() async {
        isLoading = true
        do {
            photos = try await MockAPIService.shared.fetchPhotos()
        } catch {
            // Handle error
        }
        isLoading = false
    }
}

struct PhotoGridCell: View {
    let photo: Photo

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(named: photo.thumbnailColor))
                .aspectRatio(1, contentMode: .fit)

            Text(photo.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(4)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PhotoDetailSheet: View {
    let photo: Photo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(named: photo.thumbnailColor))
                    .aspectRatio(4/3, contentMode: .fit)
                    .padding()

                Text(photo.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Label(photo.category, systemImage: "folder")
                    .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle("Photo Detail")
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

#Preview {
    NavigationStack {
        PhotoGridExerciseView()
    }
}
