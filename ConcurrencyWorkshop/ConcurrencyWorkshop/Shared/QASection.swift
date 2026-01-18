import SwiftUI

/// A Q&A view with expandable answers (similar to Exercises section)
struct QAListView: View {
    let items: [QAItem]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.blue)

                    Text("Questions")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                // Question cards
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    QuestionCard(number: index + 1, question: item.question, answer: item.answer)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.08))
            )
            .padding()
        }
    }
}

// MARK: - Question Card

private struct QuestionCard: View {
    let number: Int
    let question: String
    let answer: String
    @State private var showAnswer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Q\(number)")
                .font(.caption2)
                .foregroundColor(.secondary)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAnswer.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showAnswer ? "checkmark.circle.fill" : "eye")
                        .font(.caption)
                    Text(showAnswer ? "Hide Answer" : "Show Answer")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            if showAnswer {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
}

/// Data model for a Q&A pair
struct QAItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

#Preview {
    QAListView(items: [
        QAItem(
            question: "What is AsyncSequence and how do you consume it?",
            answer: """
            AsyncSequence is like Sequence, but each element is delivered asynchronously. You consume it with `for await`:

            for await number in numberStream {
                print("Got: \\(number)")
            }

            The loop suspends at each iteration, waiting for the next value. When the sequence ends, the loop exits normally.
            """
        ),
        QAItem(
            question: "How does task cancellation work with for-await loops?",
            answer: """
            Task cancellation works automatically—one of the best features!

            let task = Task {
                for await value in someStream {
                    process(value)
                }
            }
            task.cancel()  // Loop exits cleanly

            When the task is cancelled, the `for await` loop stops iterating. No manual checking required.
            """
        ),
        QAItem(
            question: "What built-in AsyncSequences does Swift provide?",
            answer: """
            Swift provides several built-in AsyncSequences:

            • URL.lines - Read files line by line
            • FileHandle.bytes - Stream bytes from a file
            • NotificationCenter.notifications - Subscribe to notifications
            • URLSession.bytes - Stream download data as it arrives

            These cover most common use cases without building custom sequences.
            """
        )
    ])
}
