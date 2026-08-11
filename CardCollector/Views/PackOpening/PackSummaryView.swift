import SwiftUI

struct PackSummaryView: View {
    @ObservedObject var gameState: GameState
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        ZStack {
            Color.black.opacity(0.98).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("OPENING SUMMARY").font(.title3).fontWeight(.black).foregroundColor(.white).padding(.top, 40).tracking(1)
                Text("\(gameState.allNewCards.count) Cards Added").font(.caption).foregroundColor(.gray)
                ScrollView { LazyVGrid(columns: columns, spacing: 12) { ForEach(gameState.allNewCards) { card in MiniSummaryCard(card: card) } }.padding() }
                Button(action: { gameState.isShowingSummary = false }) { Text("COLLECT ALL").font(.headline).fontWeight(.bold).foregroundColor(.black).padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(12) }.padding()
            }
        }
    }
}
