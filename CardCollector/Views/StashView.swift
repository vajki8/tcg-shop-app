import SwiftUI

// --- STASH VIEW (OPTIMIZE GOMBBAL) ---
struct StashView: View {
    @ObservedObject var gameState: GameState
    let shelfColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    let inventoryColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // SHELF
                VStack {
                    HStack {
                        Text("ACTIVE SHELF (\(gameState.displayedCardIDs.count)/10)")
                            .font(.headline).foregroundColor(.white.opacity(0.8))

                        Spacer()

                        // --- OPTIMIZE BUTTON ---
                        Button(action: {
                            withAnimation {
                                gameState.optimizeStash()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "wand.and.stars")
                                Text("Auto-Best")
                            }
                            .font(.caption).bold()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal)

                    Text("For Sale — Customers Buy From Here").font(.caption).foregroundColor(.green)

                    LazyVGrid(columns: shelfColumns, spacing: 10) {
                        ForEach(0..<10) { index in
                            if index < gameState.displayedCardIDs.count {
                                let cardId = gameState.displayedCardIDs[index]
                                if let card = gameState.collection.first(where: { $0.id == cardId }) {
                                    ShelfCardItem(card: card)
                                        .onTapGesture { gameState.removeFromDisplay(card) }
                                        .contextMenu {
                                            Button("Remove from Shelf") { gameState.removeFromDisplay(card) }
                                            Button("Sell for $\(String(format: "%.2f", card.sellValue))", role: .destructive) { gameState.sellCard(card) }
                                        }
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5])).frame(height: 90).overlay(Image(systemName: "plus").foregroundColor(.white.opacity(0.2)))
                            }
                        }
                    }.padding()
                }.background(Color.black.opacity(0.9))

                Divider()

                // INVENTORY
                VStack {
                    HStack { Text("INVENTORY").font(.headline).foregroundColor(.gray); Spacer() }.padding(.horizontal).padding(.top, 10)
                    ScrollView {
                        let inventory = gameState.collection.filter { !gameState.displayedCardIDs.contains($0.id) }.sorted { $0.sellValue > $1.sellValue }
                        if inventory.isEmpty {
                            Text("No cards in inventory.\nOpen packs to get cards!").multilineTextAlignment(.center).foregroundColor(.gray).padding(.top, 50)
                        } else {
                            LazyVGrid(columns: inventoryColumns, spacing: 12) {
                                ForEach(inventory) { card in
                                    MiniSummaryCard(card: card)
                                        .onTapGesture { gameState.displayCard(card) }
                                        .contextMenu {
                                            Button("Add to Shelf") { gameState.displayCard(card) }
                                            Button("Sell for $\(String(format: "%.2f", card.sellValue))", role: .destructive) { gameState.sellCard(card) }
                                        }
                                }
                            }.padding()
                        }
                    }
                }.background(Color(UIColor.systemGroupedBackground))
            }.navigationBarHidden(true)
        }
    }
}

// --- HELPER VIEWS ---
struct ShelfCardItem: View {
    let card: Card
    var body: some View {
        VStack(spacing: 0) {
            ZStack { LinearGradient(colors: card.rarity.color, startPoint: .top, endPoint: .bottom); Image(systemName: "tag.fill").font(.caption).foregroundColor(.white.opacity(0.8)) }.frame(height: 60)
            VStack(spacing: 0) { Text(card.name).font(.system(size: 7, weight: .bold)).lineLimit(1).foregroundColor(.primary).padding(2); Text("$\(String(format: "%.2f", card.sellValue))").font(.system(size: 7, weight: .black)).foregroundColor(.green).padding(.bottom, 2) }.frame(height: 30).frame(maxWidth: .infinity).background(Color.white)
        }.clipShape(RoundedRectangle(cornerRadius: 6)).overlay(RoundedRectangle(cornerRadius: 6).stroke(card.variant != .standard ? card.variant.color : Color.white, lineWidth: 2)).shadow(color: card.rarity.color.first!.opacity(0.5), radius: 5)
    }
}
