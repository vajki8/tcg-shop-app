import SwiftUI

// Rendelés a bolt tetején lévő menügombból: pakk típus + mennyiség, raktárba kerül.
struct OrderSheet: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                BoosterPackVisual(packType: gameState.selectedPackType)
                    .scaleEffect(0.55)
                    .frame(height: 160)
                    .padding(.top, 10)

                VStack(spacing: 10) {
                    PackOptionButton(type: .standard, description: "Base chances. No variants.", isSelected: gameState.selectedPackType == .standard, action: { gameState.selectedPackType = .standard })
                    PackOptionButton(type: .premium, description: "Better odds! Chance for MATT, LUCKY, SHINY, HOLO.", isSelected: gameState.selectedPackType == .premium, action: { gameState.selectedPackType = .premium })
                }.padding(.horizontal)

                Spacer()

                HStack(spacing: 20) {
                    BuyButton(title: "Order 1", subtitle: "To Warehouse", price: gameState.selectedPackType.price, color: gameState.selectedPackType == .premium ? .orange : .blue, action: { gameState.orderPack(gameState.selectedPackType, amount: 1); dismiss() }, canAfford: gameState.money >= gameState.selectedPackType.price)
                    BuyButton(title: "Order 10", subtitle: "To Warehouse", price: gameState.selectedPackType.price * 10, color: gameState.selectedPackType == .premium ? .black : .purple, action: { gameState.orderPack(gameState.selectedPackType, amount: 10); dismiss() }, canAfford: gameState.money >= gameState.selectedPackType.price * 10)
                }.padding(.horizontal).padding(.bottom, 20)
            }
            .navigationTitle("Order Packs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
