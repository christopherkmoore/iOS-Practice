import SwiftUI

// MARK: - Exercise: Build a list with pull-to-refresh functionality
// Requirements:
// 1. Load posts on appear
// 2. Pull to refresh reloads the data
// 3. Show last refresh time
// 4. Each post shows title, excerpt, likes count, and relative date

struct PullToRefreshExerciseView: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var lastRefresh: Date?
    @State private var error: Error?

    var body: some View {
        List {
            if let lastRefresh = lastRefresh {
                Section {
                    HStack {
                        Text("Last updated")
                        Spacer()
                        Text(lastRefresh, style: .relative)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }

            Section("Posts") {
                ForEach(posts) { post in
                    PostRowView(post: post)
                }
            }
        }
        .refreshable {
            await loadPosts()
        }
        .overlay {
            if isLoading && posts.isEmpty {
                ProgressView("Loading posts...")
            } else if let error = error, posts.isEmpty {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
            } else if posts.isEmpty && !isLoading {
                ContentUnavailableView("No Posts", systemImage: "doc.text")
            }
        }
        .navigationTitle("Posts")
        .task {
            await loadPosts()
        }
    }

    private func loadPosts() async {
        isLoading = true
        error = nil

        do {
            posts = try await MockAPIService.shared.fetchPosts()
            lastRefresh = Date()
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

struct PostRowView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title)
                .font(.headline)
                .lineLimit(2)

            Text(post.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Label("\(post.likes)", systemImage: "heart.fill")
                    .foregroundColor(.red)
                    .font(.caption)

                Spacer()

                Text(post.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PullToRefreshExerciseView()
    }
}
