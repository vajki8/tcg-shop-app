import SwiftUI

struct CollectionBookView: View {
    @ObservedObject var gameState: GameState
    @State private var selectedCard: Card?
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(gameState.allCards) { card in
                        let isOwned = gameState.hasCard(originalID: card.originalID)
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(isOwned ? LinearGradient(colors: card.rarity.color, startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)).aspectRatio(0.7, contentMode: .fit)
                                if !isOwned { Image(systemName: "questionmark").foregroundColor(.gray) }
                            }
                            Text(card.name).font(.caption).lineLimit(1).opacity(isOwned ? 1 : 0.5)
                        }.onTapGesture { if isOwned { selectedCard = card } }
                    }
                }.padding()
            }.navigationTitle("Album (\(Set(gameState.collection.map{$0.originalID}).count)/\(gameState.allCards.count))")
             .sheet(item: $selectedCard) { card in ZStack { Color.black.ignoresSafeArea(); RealCardView(card: card, width: 300); VStack { Spacer(); Button("Close"){selectedCard=nil}.foregroundColor(.white).padding() } } }
        }
    }
}
