import SwiftUI

struct GameView: View {
    @ObservedObject var gameState: GameState

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 16) {
                    header
                    ShopFloorView(gameState: gameState)
                        .frame(height: 220)
                        .padding(.horizontal)
                    WarehouseStrip(gameState: gameState)
                    Spacer()
                    orderControls
                }
                .padding(.top, 20)
            }.navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack {
            Text("BALANCE").font(.caption).bold().foregroundColor(.gray)
            Text("$\(String(format: "%.2f", gameState.money))").font(.system(size: 40, weight: .black, design: .rounded))
            Text("Customers buy from your shelf").font(.caption2).foregroundColor(.gray)
        }
    }

    private var orderControls: some View {
        VStack(spacing: 10) {
            HStack {
                BoosterPackVisual(packType: gameState.selectedPackType)
                    .scaleEffect(0.4)
                    .frame(width: 90, height: 120)
                    .clipped()
                    .onTapGesture { withAnimation { gameState.isShowingPackSelection = true } }
                VStack(alignment: .leading, spacing: 4) {
                    Text(gameState.selectedPackType.rawValue).font(.headline)
                    Text("Tap to change type").font(.caption).foregroundColor(.gray)
                }
                Spacer()
            }.padding(.horizontal)

            HStack(spacing: 20) {
                BuyButton(title: "Order 1", subtitle: "To Warehouse", price: gameState.selectedPackType.price, color: gameState.selectedPackType == .premium ? .orange : .blue, action: { gameState.orderPack(gameState.selectedPackType, amount: 1) }, canAfford: gameState.money >= gameState.selectedPackType.price)
                BuyButton(title: "Order 10", subtitle: "To Warehouse", price: gameState.selectedPackType.price * 10, color: gameState.selectedPackType == .premium ? .black : .purple, action: { gameState.orderPack(gameState.selectedPackType, amount: 10) }, canAfford: gameState.money >= gameState.selectedPackType.price * 10)
            }.padding(.bottom, 30).padding(.horizontal)
        }
    }
}

// --- BOLT PADLÓ: POLCON LÉVŐ PAKKOK + BETÉRŐ NPC ---
struct ShopFloorView: View {
    @ObservedObject var gameState: GameState
    @State private var selectedShelfPack: OrderedPack?
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .systemBackground))
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)

            VStack(spacing: 8) {
                HStack {
                    Text("SHOP FLOOR").font(.caption).bold().foregroundColor(.gray)
                    Spacer()
                    Text("\(gameState.shelfPacks.count)/\(gameState.maxPackShelfSlots) sealed packs").font(.caption2).foregroundColor(.gray)
                }.padding([.top, .horizontal], 10)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<gameState.maxPackShelfSlots, id: \.self) { index in
                        if index < gameState.shelfPacks.count {
                            let pack = gameState.shelfPacks[index]
                            PackShelfItem(pack: pack)
                                .onTapGesture { selectedShelfPack = pack }
                        } else {
                            RoundedRectangle(cornerRadius: 8).strokeBorder(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5])).frame(height: 60)
                        }
                    }
                }.padding(.horizontal, 10)

                Spacer(minLength: 0)

                if let text = gameState.lastSaleText {
                    Text(text).font(.caption).bold().foregroundColor(.green).padding(.bottom, 4).transition(.opacity)
                }
            }

            if let emoji = gameState.activeCustomerEmoji {
                Text(emoji)
                    .font(.system(size: 32))
                    .offset(x: gameState.customerXOffset, y: 60)
                    .transition(.opacity)
            }
        }
        .confirmationDialog(
            selectedShelfPack.map { "Sealed \($0.type.rawValue)" } ?? "",
            isPresented: Binding(get: { selectedShelfPack != nil }, set: { if !$0 { selectedShelfPack = nil } }),
            titleVisibility: .visible
        ) {
            if let pack = selectedShelfPack {
                Button("Back to Warehouse") { gameState.removeFromPackShelf(pack) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct PackShelfItem: View {
    let pack: OrderedPack
    var body: some View {
        VStack(spacing: 2) {
            SealedPackIcon(color: pack.type == .premium ? .orange : .blue, size: 26)
            Text("$\(String(format: "%.0f", pack.type.shelfPrice))").font(.system(size: 9, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// --- RAKTÁR: BONTATLAN PAKKOK ---
struct WarehouseStrip: View {
    @ObservedObject var gameState: GameState
    @State private var selectedPack: OrderedPack?

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
            selectedPack.map { "\($0.type.rawValue)" } ?? "",
            isPresented: Binding(get: { selectedPack != nil }, set: { if !$0 { selectedPack = nil } }),
            titleVisibility: .visible
        ) {
            if let pack = selectedPack {
                Button("Open") { gameState.openPack(pack) }
                Button("Put on Shelf") { gameState.moveToPackShelf(pack) }
            }
            Button("Cancel", role: .cancel) {}
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

// Egyszerű, dobozszerű placeholder-grafika a bontatlan pakkokhoz.
struct SealedPackIcon: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .top, endPoint: .bottom))
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.18, height: size)
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: size, height: size * 0.18)
        }
        .frame(width: size, height: size)
    }
}
