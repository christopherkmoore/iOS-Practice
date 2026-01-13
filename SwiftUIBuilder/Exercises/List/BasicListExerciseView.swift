import SwiftUI

// MARK: - Exercise: Build a basic list that loads data from the mock API
// Requirements:
// 1. Show a loading indicator while fetching
// 2. Display users in a List with name, email, and company
// 3. Handle and display errors gracefully
// 4. Add a retry button when an error occurs

struct BasicListExerciseView: View {
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading users...")
            } else if let error = error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Retry") {
                        Task { await loadUsers() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if users.isEmpty {
                ContentUnavailableView("No Users", systemImage: "person.slash")
            } else {
                List(users) { user in
                    UserRowView(user: user)
                }
            }
        }
        .navigationTitle("Users")
        .task {
            await loadUsers()
        }
    }

    private func loadUsers() async {
        isLoading = true
        error = nil

        do {
            users = try await MockAPIService.shared.fetchUsers()
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

struct UserRowView: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: user.avatarURL)
                .font(.largeTitle)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(user.company)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        BasicListExerciseView()
    }
}
