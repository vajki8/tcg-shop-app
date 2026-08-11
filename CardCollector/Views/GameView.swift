import SwiftUI

struct GameView: View {
    @ObservedObject var gameState: GameState
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 30) {
                    VStack {
                        Text("BALANCE").font(.caption).bold().foregroundColor(.gray)
                        HStack {
                            Text("$\(String(format: "%.2f", gameState.money))").font(.system(size: 40, weight: .black, design: .rounded))
                            HStack(spacing: 2) { Image(systemName: "bolt.fill"); Text("$\(String(format: "%.2f", gameState.totalPassiveIncomePerSecond))/s") }
                                .font(.caption).bold().padding(6).background(Color.green.opacity(0.2)).foregroundColor(.green).clipShape(Capsule())
                        }
                        Text("Income from Stash only").font(.caption2).foregroundColor(.gray)
                    }.padding(.top, 40)
                    Spacer()
                    BoosterPackVisual(packType: gameState.selectedPackType).shadow(color: .black.opacity(0.3), radius: 20, y: 10).scaleEffect(gameState.isOpeningPack ? 1.1 : 1.0).onTapGesture { withAnimation { gameState.isShowingPackSelection = true } }
                    Text("Tap pack to change type").font(.caption).foregroundColor(.gray)
                    Spacer()
                    HStack(spacing: 20) {
                        BuyButton(title: "1 Pack", subtitle: "5 Cards", price: gameState.selectedPackType.price, color: gameState.selectedPackType == .premium ? .orange : .blue, action: { gameState.buyPacks(amount: 1) }, canAfford: gameState.money >= gameState.selectedPackType.price)
                        BuyButton(title: "10 Packs", subtitle: "50 Cards", price: gameState.selectedPackType.price * 10, color: gameState.selectedPackType == .premium ? .black : .purple, action: { gameState.buyPacks(amount: 10) }, canAfford: gameState.money >= gameState.selectedPackType.price * 10)
                    }.padding(.bottom, 40).padding(.horizontal).disabled(gameState.isOpeningPack)
                }
            }.navigationBarHidden(true)
        }
    }
}
