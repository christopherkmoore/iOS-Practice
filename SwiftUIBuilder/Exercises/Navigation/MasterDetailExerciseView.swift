import SwiftUI

// MARK: - Exercise: Build a master-detail navigation pattern
// Requirements:
// 1. List of users on the left/main view
// 2. Tapping shows user detail with their posts
// 3. Handle loading states for both user list and user posts
// 4. Show empty state when no user is selected (iPad)

struct MasterDetailExerciseView: View {
    @State private var users: [User] = []
    @State private var selectedUser: User?
    @State private var isLoading = false

    var body: some View {
        List(users, selection: $selectedUser) { user in
            NavigationLink(value: user) {
                HStack(spacing: 12) {
                    Image(systemName: user.avatarURL)
                        .font(.title)
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.company)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Users")
        .navigationDestination(for: User.self) { user in
            UserDetailView(user: user)
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            await loadUsers()
        }
    }

    private func loadUsers() async {
        isLoading = true
        do {
            users = try await MockAPIService.shared.fetchUsers()
        } catch {
            // Handle error
        }
        isLoading = false
    }
}

struct UserDetailView: View {
    let user: User
    @State private var posts: [Post] = []
    @State private var isLoading = false

    var body: some View {
        List {
            Section("User Info") {
                HStack(spacing: 16) {
                    Image(systemName: user.avatarURL)
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(user.company)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Posts (\(posts.count))") {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if posts.isEmpty {
                    ContentUnavailableView("No Posts", systemImage: "doc.text")
                } else {
                    ForEach(posts) { post in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.title)
                                .font(.headline)

                            Text(post.body)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)

                            HStack {
                                Label("\(post.likes)", systemImage: "heart.fill")
                                    .foregroundColor(.red)

                                Spacer()

                                Text(post.createdAt, style: .date)
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(user.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPosts()
        }
    }

    private func loadPosts() async {
        isLoading = true
        do {
            posts = try await MockAPIService.shared.fetchPosts(forUserId: user.id)
        } catch {
            // Handle error
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        MasterDetailExerciseView()
    }
}
