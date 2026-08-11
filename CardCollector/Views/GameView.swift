import SwiftUI

struct GameView: View {
    @ObservedObject var gameState: GameState
    @State private var isShowingOrderSheet = false
    @State private var isShowingWarehouseSheet = false

    var body: some View {
        ZStack {
            ShopSceneView(gameState: gameState)
                .ignoresSafeArea()

            VStack {
                HStack(alignment: .top) {
                    balanceHUD
                    Spacer()
                    VStack(spacing: 12) {
                        cornerButton(icon: "cart.badge.plus", color: .indigo, action: { isShowingOrderSheet = true })
                        cornerButton(icon: "shippingbox.fill", color: .brown, badge: gameState.warehousePacks.count, action: { isShowingWarehouseSheet = true })
                    }
                }
                .padding(.top, 54)
                .padding(.horizontal, 16)
                Spacer()
            }
        }
        .sheet(isPresented: $isShowingOrderSheet) {
            OrderSheet(gameState: gameState)
        }
        .sheet(isPresented: $isShowingWarehouseSheet) {
            WarehouseSheet(gameState: gameState)
        }
    }

    private var balanceHUD: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BALANCE").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.8))
            Text("$\(String(format: "%.2f", gameState.money))").font(.system(size: 26, weight: .black, design: .rounded)).foregroundColor(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func cornerButton(icon: String, color: Color, badge: Int = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.title3).bold()
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Circle().fill(color))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Circle().fill(Color.red))
                        .offset(x: 6, y: -6)
                }
            }
        }
    }
}
