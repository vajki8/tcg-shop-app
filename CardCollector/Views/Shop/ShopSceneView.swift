import SwiftUI

// Felülnézetes bolt-jelenet: fal+ablak, faborítású pult a polcokkal, ajtó, sétáló NPC.
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
                WoodFloor()

                VStack(spacing: 0) {
                    ShopWall()
                        .frame(height: 124)

                    CounterPanel {
                        ShelfGrid(items: shelfItems, totalSlots: gameState.maxShelfSlots + gameState.maxPackShelfSlots, gameState: gameState) { item in
                            selectedItem = item
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)

                    Spacer(minLength: 0)

                    DoorView().padding(.bottom, 26)
                }

                if gameState.isCustomerVisible {
                    CustomerSprite(color: gameState.customerColor)
                        .position(x: geo.size.width * gameState.customerXFraction, y: geo.size.height * gameState.customerYFraction)
                }

                if let text = gameState.lastSaleText {
                    Text(text)
                        .font(.caption).bold().foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.black.opacity(0.65))
                        .clipShape(Capsule())
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.62)
                        .transition(.opacity)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ShelfItemSheet(item: item, gameState: gameState)
        }
    }
}

// --- FAL + ABLAK ---
private struct ShopWall: View {
    var body: some View {
        ZStack {
            Color(red: 0.80, green: 0.86, blue: 0.89)
            Rectangle().fill(Color.black.opacity(0.08)).frame(height: 3).frame(maxHeight: .infinity, alignment: .bottom)

            HStack(spacing: 18) {
                WindowPane()
                Text("CARD SHOP").font(.system(size: 11, weight: .black)).foregroundColor(.black.opacity(0.55)).tracking(1)
                WindowPane()
            }
            .padding(.top, 56)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct WindowPane: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.white)
            LinearGradient(colors: [Color(red: 0.75, green: 0.9, blue: 0.96), Color(red: 0.55, green: 0.78, blue: 0.9)], startPoint: .top, endPoint: .bottom)
                .padding(3)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            Rectangle().fill(Color.white).frame(width: 2).padding(3)
            Rectangle().fill(Color.white).frame(height: 2).padding(3)
        }
        .frame(width: 34, height: 26)
    }
}

// --- FAPULT A POLCOKKAL ---
private struct CounterPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(8)
                .background(Color(red: 0.62, green: 0.42, blue: 0.24))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Rectangle()
                .fill(Color(red: 0.45, green: 0.29, blue: 0.15))
                .frame(height: 6)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .padding(.horizontal, 4)
        }
    }
}

// --- FAPADLÓ ---
private struct WoodFloor: View {
    let planks = 9

    var body: some View {
        GeometryReader { geo in
            let plankH = geo.size.height / CGFloat(planks)
            ZStack {
                Color(red: 0.78, green: 0.62, blue: 0.45)
                ForEach(0..<planks, id: \.self) { row in
                    Rectangle()
                        .fill(row.isMultiple(of: 2) ? Color.black.opacity(0.04) : Color.white.opacity(0.05))
                        .frame(height: plankH)
                        .position(x: geo.size.width / 2, y: plankH * (CGFloat(row) + 0.5))
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                        .position(x: geo.size.width / 2, y: plankH * CGFloat(row))
                }
            }
        }
    }
}

// --- AJTÓ ---
private struct DoorView: View {
    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [Color(red: 0.5, green: 0.32, blue: 0.16), Color(red: 0.38, green: 0.23, blue: 0.1)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 46, height: 14)
                Circle().fill(Color.yellow.opacity(0.8)).frame(width: 3, height: 3).padding(.trailing, 6)
            }
            Text("ENTRANCE").font(.system(size: 7, weight: .bold)).foregroundColor(.black.opacity(0.4))
        }
    }
}

// --- BETÉRŐ VÁSÁRLÓ: rajzolt figura, sétáló lábakkal ---
struct CustomerSprite: View {
    let color: Color
    @State private var walkPhase = false

    var body: some View {
        ZStack {
            HStack(spacing: 4) {
                Capsule().fill(Color.black.opacity(0.55)).frame(width: 4, height: 9)
                    .rotationEffect(.degrees(walkPhase ? 18 : -18), anchor: .top)
                Capsule().fill(Color.black.opacity(0.55)).frame(width: 4, height: 9)
                    .rotationEffect(.degrees(walkPhase ? -18 : 18), anchor: .top)
            }
            .offset(y: 11)

            RoundedRectangle(cornerRadius: 5).fill(color).frame(width: 15, height: 16)

            Circle().fill(Color(red: 0.94, green: 0.78, blue: 0.62)).frame(width: 10, height: 10).offset(y: -13)
        }
        .frame(width: 26, height: 32)
        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.28).repeatForever(autoreverses: true)) {
                walkPhase.toggle()
            }
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
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [4]))
                        .frame(height: 44)
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
                    .frame(height: 22).clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color.white.opacity(0.6), lineWidth: 1))
                Text("$\(String(format: "%.0f", gameState.price(for: card)))").font(.system(size: 8, weight: .bold))
            case .pack(let pack):
                SealedPackIcon(color: pack.type == .premium ? .orange : .blue, size: 18)
                Text("$\(String(format: "%.0f", gameState.price(for: pack)))").font(.system(size: 8, weight: .bold))
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.94, green: 0.89, blue: 0.8))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .shadow(color: .black.opacity(0.15), radius: 1.5, y: 1)
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
