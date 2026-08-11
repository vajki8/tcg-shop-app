import SwiftUI

struct BoosterPackSwipeView: View {
    @ObservedObject var gameState: GameState
    @State private var offset: CGSize = .zero
    @State private var isDragging: Bool = false
    var currentCard: Card? { if gameState.cardsToReveal.indices.contains(gameState.currentCardIndex) { return gameState.cardsToReveal[gameState.currentCardIndex] }; return nil }
    var nextCard: Card? { let nextIndex = gameState.currentCardIndex + 1; if gameState.cardsToReveal.indices.contains(nextIndex) { return gameState.cardsToReveal[nextIndex] }; return nil }
    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            VStack {
                if gameState.showSummaryAfterReveal { Text("TOP 10 PICKS").font(.headline).foregroundColor(.yellow).tracking(2).padding(.top, 50) }
                else { Text("OPENING PACK").font(.headline).foregroundColor(.gray).tracking(2).padding(.top, 50) }
                Spacer()
                ZStack {
                    if let next = nextCard { RealCardView(card: next, width: 300).scaleEffect(0.92).offset(y: 15).brightness(-0.1).opacity(1).id(next.id) }
                    if let current = currentCard { RealCardView(card: current, width: 300).offset(x: offset.width, y: offset.height).rotationEffect(.degrees(Double(offset.width / 15))).shadow(color: Color.black.opacity(0.4), radius: 20).scaleEffect(1.0).gesture(DragGesture().onChanged { g in isDragging = true; offset = g.translation }.onEnded { g in isDragging = false; if abs(offset.width) > 100 || abs(offset.height) > 100 { finishCardReveal(direction: offset) } else { withAnimation(.spring()){ offset = .zero } } }).onTapGesture { finishCardReveal(direction: CGSize(width: 500, height: 0)) }.id(current.id).transition(.scale(scale: 0.92).combined(with: .opacity)) }
                }.padding(.bottom, 50)
                Spacer()
                Text(isDragging ? "Release to reveal" : "Swipe sideways or Tap").font(.subheadline).foregroundColor(.white.opacity(0.5)).padding(.bottom, 50)
            }
        }
    }
    func finishCardReveal(direction: CGSize) {
        let flyAwayOffset = CGSize(width: direction.width > 0 ? 1000 : -1000, height: direction.height * 1.5)
        withAnimation(.easeIn(duration: 0.3)) { offset = flyAwayOffset }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { if gameState.currentCardIndex < gameState.cardsToReveal.count - 1 { gameState.currentCardIndex += 1; offset = .zero } else { finishOpening() } }
    }
    func finishOpening() { gameState.isOpeningPack = false; gameState.isShowingSummary = gameState.showSummaryAfterReveal }
}
