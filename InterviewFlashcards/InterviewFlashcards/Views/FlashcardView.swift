import SwiftUI

struct FlashcardView: View {
    let card: Flashcard
    @Binding var isFlipped: Bool

    var body: some View {
        ZStack {
            // Back (Answer)
            cardFace(
                text: card.answer,
                label: "Answer",
                tintColor: .green
            )
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(isFlipped ? 1 : 0)

            // Front (Question)
            cardFace(
                text: card.question,
                label: "Question",
                tintColor: .blue
            )
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(isFlipped ? 0 : 1)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
    }

    private func cardFace(text: String, label: String, tintColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(card.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.2))
                    .foregroundStyle(categoryColor)
                    .clipShape(Capsule())
            }

            Spacer()

            Text(text)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)

            Spacer()

            Text("Tap to flip")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(tintColor.opacity(0.08))
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var categoryColor: Color {
        switch card.category {
        case .swift: return .red
        case .concurrency: return .orange
        case .testing: return .purple
        case .swiftui: return .blue
        }
    }
}

#Preview {
    FlashcardView(
        card: Flashcard(
            question: "What's the difference between a data race and a race condition?",
            answer: "A data race is when two threads access the same memory simultaneously and at least one is writing. A race condition is when the outcome depends on timing.",
            category: .concurrency
        ),
        isFlipped: .constant(false)
    )
    .padding()
    .frame(height: 400)
}
