import SwiftUI

// Felülnézetes bolt-jelenet: padló, polcsor, ajtó, betérő NPC.
struct ShopSceneView: View {
    @ObservedObject var gameState: GameState
    @State private var selectedItem: ShelfDisplayItem?

    private var shelfItems: [ShelfDisplayItem] {
        // A sorrend meg kell egyezzen a GameState NPC-célpont indexeléssel (pakkok, majd kártyák).
        gameState.shelfPacks.map { .pack($0) } + gameState.displayedCards.map { .card($0) }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                FloorBackground()

                VStack(spacing: 0) {
                    ShelfGrid(items: shelfItems, totalSlots: gameState.maxShelfSlots + gameState.maxPackShelfSlots, gameState: gameState) { item in
                        selectedItem = item
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 8)

                    Spacer(minLength: 0)

                    DoorView().padding(.bottom, 10)
                }

                if gameState.isCustomerVisible {
                    Text("🧍")
                        .font(.system(size: 30))
                        .position(x: geo.size.width * gameState.customerXFraction, y: geo.size.height * gameState.customerYFraction)
                }

                if let text = gameState.lastSaleText {
                    Text(text)
                        .font(.caption).bold().foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.black.opacity(0.65))
                        .clipShape(Capsule())
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.55)
                        .transition(.opacity)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.black.opacity(0.15), lineWidth: 1))
        .sheet(item: $selectedItem) { item in
            ShelfItemSheet(item: item, gameState: gameState)
        }
    }
}

private struct FloorBackground: View {
    let columns = 8
    let rows = 6

    var body: some View {
        GeometryReader { geo in
            let tileW = geo.size.width / CGFloat(columns)
            let tileH = geo.size.height / CGFloat(rows)
            ZStack {
                Color(red: 0.87, green: 0.81, blue: 0.68)
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { col in
                        if (row + col).isMultiple(of: 2) {
                            Rectangle()
                                .fill(Color.black.opacity(0.05))
                                .frame(width: tileW, height: tileH)
                                .position(x: tileW * (CGFloat(col) + 0.5), y: tileH * (CGFloat(row) + 0.5))
                        }
                    }
                }
            }
        }
    }
}

private struct DoorView: View {
    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 3).fill(Color.brown).frame(width: 50, height: 8)
            Text("ENTRANCE").font(.system(size: 7, weight: .bold)).foregroundColor(.black.opacity(0.4))
        }
    }
}

private struct ShelfGrid: View {
    let items: [ShelfDisplayItem]
    let totalSlots: Int
    @ObservedObject var gameState: GameState
    let onTap: (ShelfDisplayItem) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<totalSlots, id: \.self) { index in
                if index < items.count {
                    let item = items[index]
                    ShelfSlotView(item: item, gameState: gameState)
                        .onTapGesture { onTap(item) }
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.black.opacity(0.15), style: StrokeStyle(lineWidth: 2, dash: [4]))
                        .frame(height: 46)
                }
            }
        }
    }
}

private struct ShelfSlotView: View {
    let item: ShelfDisplayItem
    @ObservedObject var gameState: GameState

    var body: some View {
        VStack(spacing: 2) {
            switch item {
            case .card(let card):
                LinearGradient(colors: card.rarity.color, startPoint: .top, endPoint: .bottom)
                    .frame(height: 24).clipShape(RoundedRectangle(cornerRadius: 4))
                Text("$\(String(format: "%.0f", gameState.price(for: card)))").font(.system(size: 8, weight: .bold))
            case .pack(let pack):
                SealedPackIcon(color: pack.type == .premium ? .orange : .blue, size: 20)
                Text("$\(String(format: "%.0f", gameState.price(for: pack)))").font(.system(size: 8, weight: .bold))
            }
        }
        .frame(height: 46)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
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
            Rectangle().fill(Color.white.opacity(0.8)).frame(width: size * 0.18, height: size)
            Rectangle().fill(Color.white.opacity(0.8)).frame(width: size, height: size * 0.18)
        }
        .frame(width: size, height: size)
    }
}
