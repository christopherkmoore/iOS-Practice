import SwiftUI

struct CardStackView: View {
    let cards: [Flashcard]
    @Binding var currentIndex: Int
    var onShuffle: (() -> Void)?

    @State private var offset: CGPoint = .zero
    @State private var swipeDirection: SwipeDirection = .idle
    @State private var flippedStates: [UUID: Bool] = [:]

    private let triggerThreshold: CGFloat = 150
    private let minimumDistance: CGFloat = 20
    private let visibleCount = 3

    enum SwipeDirection {
        case left, right, idle

        init(offset: CGFloat) {
            if offset > 0 {
                self = .right
            } else if offset < 0 {
                self = .left
            } else {
                self = .idle
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            progressHeader
            progressBar

            GeometryReader { geometry in
                if cards.isEmpty {
                    ContentUnavailableView(
                        "No Cards",
                        systemImage: "rectangle.stack",
                        description: Text("Select a category with cards")
                    )
                } else {
                    ZStack {
                        ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                            let cardIndex = currentIndex + index
                            let progress = index == 0 ? min(abs(offset.x) / triggerThreshold, 1) : 0

                            FlashcardView(
                                card: card,
                                isFlipped: bindingForCard(card.id)
                            )
                            .frame(
                                width: geometry.size.width - 32,
                                height: geometry.size.height
                            )
                            .modifier(CardSwipeEffect(
                                index: index,
                                offset: offset,
                                triggerThreshold: triggerThreshold
                            ))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(swipeGesture)
                }
            }
            .padding(.horizontal, 16)

            navigationHint
        }
    }

    // MARK: - Subviews

    private var progressHeader: some View {
        HStack {
            Text("\(currentIndex + 1) / \(cards.count)")
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    flippedStates.removeAll()
                    onShuffle?()
                }
            } label: {
                Image(systemName: "shuffle")
                    .font(.subheadline.weight(.medium))
            }
            .tint(.secondary)

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentIndex = 0
                    flippedStates.removeAll()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
            }
            .disabled(currentIndex == 0)
            .tint(.secondary)
        }
        .padding(.horizontal, 20)
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 20)
    }

    private var navigationHint: some View {
        HStack {
            Button {
                goToPreviousCard()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.subheadline.weight(.medium))
            }
            .disabled(currentIndex == 0)
            .tint(.secondary)

            Spacer()

            if currentIndex < cards.count - 1 {
                Label("Swipe", systemImage: "hand.draw")
                    .font(.caption)
                    .foregroundStyle(swipeDirection == .left ? .primary : .secondary)
            } else {
                Text("Done!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Computed Properties

    private var progress: CGFloat {
        guard cards.count > 0 else { return 0 }
        return CGFloat(currentIndex + 1) / CGFloat(cards.count)
    }

    private var visibleCards: [Flashcard] {
        let endIndex = min(currentIndex + visibleCount, cards.count)
        guard currentIndex < endIndex else { return [] }
        return Array(cards[currentIndex..<endIndex])
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: minimumDistance)
            .onChanged { value in
                let translation = value.translation.width
                let correction = correctionFor(translation)
                offset = CGPoint(x: translation + correction, y: 0)
                swipeDirection = SwipeDirection(offset: offset.x)
            }
            .onEnded { value in
                handleSwipeEnd(translation: value.translation.width)
            }
    }

    // MARK: - Helper Functions

    private func bindingForCard(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { flippedStates[id] ?? false },
            set: { flippedStates[id] = $0 }
        )
    }

    private func correctionFor(_ translation: CGFloat) -> CGFloat {
        if translation >= minimumDistance {
            return -minimumDistance
        } else if translation <= -minimumDistance {
            return minimumDistance
        } else {
            return -translation
        }
    }

    private func handleSwipeEnd(translation: CGFloat) {
        // Only allow swipe left to go to next card
        if translation < -triggerThreshold && currentIndex < cards.count - 1 {
            let screenWidth = UIScreen.main.bounds.width

            withAnimation(.spring(duration: 0.4)) {
                offset.x = -screenWidth
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex += 1
                offset = .zero
                swipeDirection = .idle
            }
        } else {
            // Snap back for any other case
            withAnimation(.bouncy) {
                offset = .zero
                swipeDirection = .idle
            }
        }
    }

    private func goToPreviousCard() {
        guard currentIndex > 0 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex -= 1
        }
    }
}

// MARK: - Card Swipe Effect Modifier

struct CardSwipeEffect: ViewModifier {
    let index: Int
    let offset: CGPoint
    let triggerThreshold: CGFloat

    func body(content: Content) -> some View {
        let progress = min(abs(offset.x) / triggerThreshold, 1)

        switch index {
        case 0:
            // Top card: moves with drag, rotates
            let angle = Angle(degrees: Double(offset.x) / 25)
            content
                .offset(x: offset.x, y: offset.y)
                .rotationEffect(angle, anchor: .bottom)
                .zIndex(4)

        case 1:
            // Second card: scales up and moves up as top card is dragged
            content
                .offset(y: CGFloat((1 - progress) * 20))
                .scaleEffect(CGFloat(0.95 + progress * 0.05))
                .zIndex(3)

        case 2:
            // Third card: scales up and moves up
            content
                .offset(y: CGFloat(40 - progress * 20))
                .scaleEffect(CGFloat(0.9 + progress * 0.05))
                .zIndex(2)

        default:
            content
                .opacity(0)
        }
    }
}

#Preview {
    CardStackView(
        cards: FlashcardData.allCards,
        currentIndex: .constant(0)
    )
}
