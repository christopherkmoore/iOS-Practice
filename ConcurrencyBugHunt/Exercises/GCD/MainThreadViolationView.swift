import SwiftUI

// MARK: - Exercise: Find the concurrency bug(s) in this code
// This view fetches user data and updates the UI

class UserProfileLoader: ObservableObject {
    @Published var userName: String = "Loading..."
    @Published var userEmail: String = ""
    @Published var profileImageData: Data?
    @Published var isLoading: Bool = false
    @Published var posts: [String] = []

    func loadUserProfile(userId: String) {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate network delay
            Thread.sleep(forTimeInterval: 1.0)

            // Simulate fetched data
            let fetchedName = "John Doe"
            let fetchedEmail = "john.doe@example.com"

            // Update the UI with fetched data
            self.userName = fetchedName
            self.userEmail = fetchedEmail
            self.isLoading = false

            // Load additional data
            self.loadUserPosts(userId: userId)
        }
    }

    private func loadUserPosts(userId: String) {
        DispatchQueue.global(qos: .background).async {
            // Simulate loading posts
            Thread.sleep(forTimeInterval: 0.5)

            let fetchedPosts = [
                "Just had a great coffee!",
                "Working on some Swift code today",
                "Loving the new iOS features",
                "Beach day with family",
                "New project announcement coming soon!"
            ]

            self.posts = fetchedPosts
        }
    }

    func loadProfileImage() {
        DispatchQueue.global(qos: .utility).async {
            Thread.sleep(forTimeInterval: 1.5)

            // Simulate image data
            let fakeImageData = Data(repeating: 0, count: 1000)
            self.profileImageData = fakeImageData
        }
    }
}

struct MainThreadViolationView: View {
    @StateObject private var loader = UserProfileLoader()

    var body: some View {
        VStack(spacing: 20) {
            Text("User Profile Loader")
                .font(.headline)

            if loader.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(loader.profileImageData != nil ? .green : .gray)

                        VStack(alignment: .leading) {
                            Text(loader.userName)
                                .font(.title2)
                            Text(loader.userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Text("Recent Posts")
                        .font(.headline)

                    ForEach(loader.posts, id: \.self) { post in
                        Text("• \(post)")
                            .font(.body)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            HStack {
                Button("Load Profile") {
                    loader.loadUserProfile(userId: "user_123")
                }
                .buttonStyle(.borderedProminent)

                Button("Load Image") {
                    loader.loadProfileImage()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Text("Watch the console for warnings about\npublishing changes from background threads")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Main Thread Violation")
    }
}

#Preview {
    NavigationStack {
        MainThreadViolationView()
    }
}
