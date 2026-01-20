import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: Flashcard.Category?
    @State private var currentIndex = 0
    @State private var shuffledCards: [Flashcard]?

    private var filteredCards: [Flashcard] {
        if let shuffled = shuffledCards {
            return shuffled
        }
        guard let category = selectedCategory else {
            return FlashcardData.allCards
        }
        return FlashcardData.allCards.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryButton(
                            title: "All",
                            count: FlashcardData.allCards.count,
                            isSelected: selectedCategory == nil
                        ) {
                            selectCategory(nil)
                        }

                        ForEach(Flashcard.Category.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                count: cardCount(for: category),
                                isSelected: selectedCategory == category
                            ) {
                                selectCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))

                Divider()

                // Cards
                CardStackView(cards: filteredCards, currentIndex: $currentIndex, onShuffle: shuffleCards)
                    .padding(.top)
            }
            .navigationTitle("Interview Prep")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func cardCount(for category: Flashcard.Category) -> Int {
        FlashcardData.allCards.filter { $0.category == category }.count
    }

    private func selectCategory(_ category: Flashcard.Category?) {
        withAnimation {
            selectedCategory = category
            shuffledCards = nil
            currentIndex = 0
        }
    }

    private func shuffleCards() {
        let cardsToShuffle: [Flashcard]
        if let category = selectedCategory {
            cardsToShuffle = FlashcardData.allCards.filter { $0.category == category }
        } else {
            cardsToShuffle = FlashcardData.allCards
        }
        shuffledCards = cardsToShuffle.shuffled()
        currentIndex = 0
    }
}

struct CategoryButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ContentView()
}
