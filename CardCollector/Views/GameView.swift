import SwiftUI

struct GameView: View {
    @ObservedObject var gameState: GameState
    @State private var isShowingOrderSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 12) {
                    header
                    ShopSceneView(gameState: gameState)
                        .frame(height: 320)
                        .padding(.horizontal)
                    WarehouseStrip(gameState: gameState)
                        .padding(.bottom, 10)
                }
                .padding(.top, 8)

                VStack {
                    HStack {
                        Spacer()
                        Button { isShowingOrderSheet = true } label: {
                            Image(systemName: "cart.badge.plus")
                                .font(.title3).bold()
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Circle().fill(Color.indigo))
                                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                        }
                    }
                    Spacer()
                }.padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingOrderSheet) {
                OrderSheet(gameState: gameState)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text("BALANCE").font(.caption).bold().foregroundColor(.gray)
            Text("$\(String(format: "%.2f", gameState.money))").font(.system(size: 34, weight: .black, design: .rounded))
        }
    }
}

// --- RAKTÁR: BONTATLAN PAKKOK ---
struct WarehouseStrip: View {
    @ObservedObject var gameState: GameState
    @State private var selectedPack: OrderedPack?
    @State private var packToPrice: OrderedPack?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WAREHOUSE (\(gameState.warehousePacks.count))").font(.caption).bold().foregroundColor(.gray).padding(.horizontal)
            if gameState.warehousePacks.isEmpty {
                Text("No packs ordered yet.").font(.caption).foregroundColor(.gray).padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(gameState.warehousePacks) { pack in
                            WarehousePackItem(pack: pack)
                                .onTapGesture { selectedPack = pack }
                        }
                    }.padding(.horizontal)
                }
            }
        }
        .confirmationDialog(
            selectedPack.map { $0.type.rawValue } ?? "",
            isPresented: Binding(get: { selectedPack != nil }, set: { if !$0 { selectedPack = nil } }),
            titleVisibility: .visible
        ) {
            if let pack = selectedPack {
                Button("Open") { gameState.openPack(pack) }
                Button("Put on Shelf") { packToPrice = pack }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $packToPrice) { pack in
            PriceEditorSheet(title: "Sealed \(pack.type.rawValue)", suggestedPrice: pack.type.shelfPrice, confirmLabel: "Put on Shelf") { price in
                gameState.moveToPackShelf(pack, price: price)
            }
        }
    }
}

struct WarehousePackItem: View {
    let pack: OrderedPack
    var body: some View {
        VStack(spacing: 4) {
            SealedPackIcon(color: pack.type == .premium ? .orange : .blue, size: 30)
            Text(pack.type == .premium ? "Premium" : "Standard").font(.system(size: 9, weight: .bold))
        }
        .frame(width: 64, height: 64)
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
