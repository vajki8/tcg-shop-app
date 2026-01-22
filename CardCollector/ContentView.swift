import SwiftUI
import Combine

// --- 1. ADAT MODELLEK ---

enum CardVariant: String, CaseIterable, Codable {
    case standard = ""
    case matt = "MATT"
    case lucky = "LUCKY"
    case shiny = "SHINY"
    case holo = "HOLO"
    
    var multiplier: Double {
        switch self {
        case .standard: return 1.0
        case .matt: return 1.5
        case .lucky: return 5.0
        case .shiny: return 10.0
        case .holo: return 15.0
        }
    }
    
    var color: Color {
        switch self {
        case .standard: return .clear
        case .matt: return .brown.opacity(0.6)
        case .lucky: return .green
        case .shiny: return .yellow
        case .holo: return .purple
        }
    }
}

enum PackType: String, CaseIterable {
    case standard = "Standard Pack"
    case premium = "Premium Pack"
    
    var price: Double {
        switch self {
        case .standard: return 5.0
        case .premium: return 500.0
        }
    }
    
    var color: [Color] {
        switch self {
        case .standard: return [.indigo, .blue]
        case .premium: return [.yellow, .orange, .black]
        }
    }
}

enum Rarity: String, CaseIterable, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    case mythic = "Mythic"
    case god = "GOD"
    
    var score: Int {
        switch self {
        case .common: return 1; case .rare: return 2; case .epic: return 3; case .legendary: return 4; case .mythic: return 5; case .god: return 6
        }
    }
    
    var color: [Color] {
        switch self {
        case .common: return [.gray, Color(white: 0.3)]
        case .rare: return [.blue, .cyan]
        case .epic: return [.purple, .indigo]
        case .legendary: return [.orange, .yellow]
        case .mythic: return [.red, .pink]
        case .god: return [.yellow, .white, .yellow]
        }
    }
    
    var baseIncome: Double {
        switch self {
        case .common: return 0.05
        case .rare: return 0.25
        case .epic: return 1.25
        case .legendary: return 8.0
        case .mythic: return 50.0
        case .god: return 500.0
        }
    }
    
    var dropRate: Double {
        switch self {
        case .common: return 80.0
        case .rare: return 15.0
        case .epic: return 3.5
        case .legendary: return 1.2
        case .mythic: return 0.28
        case .god: return 0.02
        }
    }
}

struct Card: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let rarity: Rarity
    let variant: CardVariant
    let originalID: Int
    
    var passiveIncome: Double {
        rarity.baseIncome * variant.multiplier
    }
}

// --- 2. JÁTÉK LOGIKA (GameState) ---

class GameState: ObservableObject {
    @Published var money: Double = 15.0
    @Published var collection: [Card] = []
    @Published var equippedCardIDs: [UUID] = []
    let maxShelfSlots = 10
    
    @Published var packsOpened: Int = 0
    @Published var selectedPackType: PackType = .standard
    @Published var isShowingPackSelection: Bool = false
    
    let allCards: [Card]
    
    @Published var isOpeningPack: Bool = false
    @Published var isShowingSummary: Bool = false
    @Published var showSummaryAfterReveal: Bool = false
    @Published var cardsToReveal: [Card] = []
    @Published var allNewCards: [Card] = []
    @Published var currentCardIndex: Int = 0
    
    private var timer: Timer?
    
    init() {
        self.allCards = GameState.generateCardDatabase()
        startPassiveIncome()
    }
    
    // --- OPTIMALIZÁLÁS (AUTO-EQUIP) ---
    func optimizeStash() {
        // 1. Ürítjük a polcot
        equippedCardIDs.removeAll()
        
        // 2. Sorba rendezzük a kártyákat bevétel szerint (csökkenő)
        // A variant multiplier már benne van a passiveIncome-ban, így a Lucky Common lehet jobb mint egy sima Rare.
        let bestCards = collection.sorted { $0.passiveIncome > $1.passiveIncome }
        
        // 3. Kiválasztjuk a top 10-et (vagy kevesebbet, ha nincs annyi)
        let topCards = bestCards.prefix(maxShelfSlots)
        
        // 4. Berakjuk az ID-kat
        equippedCardIDs = topCards.map { $0.id }
    }
    
    func equipCard(_ card: Card) {
        guard equippedCardIDs.count < maxShelfSlots else { return }
        guard !equippedCardIDs.contains(card.id) else { return }
        equippedCardIDs.append(card.id)
    }
    
    func unequipCard(_ card: Card) {
        if let index = equippedCardIDs.firstIndex(of: card.id) {
            equippedCardIDs.remove(at: index)
        }
    }
    
    var equippedCards: [Card] {
        return collection.filter { equippedCardIDs.contains($0.id) }
    }
    
    private func startPassiveIncome() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.money += (self.totalPassiveIncomePerSecond / 10.0)
        }
    }
    
    var totalPassiveIncomePerSecond: Double {
        equippedCards.reduce(0) { $0 + $1.passiveIncome }
    }
    
    private static let loreTemplates = ["Forged in fire.", "Ancient relic.", "Lost for ages.", "Cursed item.", "Blessed by gods.", "Vibrating with power.", "Cold to the touch.", "Heavy as lead.", "Found in a dragon's hoard.", "Whispers in the dark."]
    private static let prefixes = ["Broken", "Iron", "Golden", "Ancient", "Dark", "Holy", "Cursed", "Swift", "Heavy", "Crystal", "Blood", "Night", "Wooden", "Steel"]
    private static let nouns = ["Sword", "Shield", "Ring", "Amulet", "Helmet", "Boot", "Gem", "Staff", "Dagger", "Orb", "Cloak", "Tome", "Hammer", "Axe"]
    
    static func generateCardDatabase() -> [Card] {
        var cards: [Card] = []
        var idCounter = 1
        func make(count: Int, rarity: Rarity) {
            for _ in 0..<count {
                let name = "\(prefixes.randomElement()!) \(nouns.randomElement()!)"
                cards.append(Card(id: UUID(), name: name, description: loreTemplates.randomElement()!, rarity: rarity, variant: .standard, originalID: idCounter))
                idCounter += 1
            }
        }
        make(count: 85, rarity: .common); make(count: 40, rarity: .rare); make(count: 20, rarity: .epic); make(count: 10, rarity: .legendary); make(count: 3, rarity: .mythic)
        cards.append(Card(id: UUID(), name: "THE ONE ABOVE ALL", description: "Infinite Power.", rarity: .god, variant: .standard, originalID: 999))
        return cards.sorted { $0.originalID < $1.originalID }
    }
    
    func buyPacks(amount: Int) {
        let totalCost = selectedPackType.price * Double(amount)
        guard money >= totalCost else { return }
        
        money -= totalCost
        packsOpened += amount
        self.showSummaryAfterReveal = (amount > 1)
        
        var generatedCards: [Card] = []
        let totalCardsCount = amount * 5
        
        for _ in 0..<totalCardsCount {
            let rarity = selectRarity(for: selectedPackType)
            let possibleCards = allCards.filter { $0.rarity == rarity }
            let baseCard = possibleCards.randomElement() ?? allCards.first!
            let variant = selectVariant(for: selectedPackType)
            let newCard = Card(id: UUID(), name: baseCard.name, description: baseCard.description, rarity: rarity, variant: variant, originalID: baseCard.originalID)
            generatedCards.append(newCard)
            collection.append(newCard)
        }
        
        self.allNewCards = generatedCards
        
        if amount == 1 {
            self.cardsToReveal = generatedCards
        } else {
            let top10 = generatedCards.sorted { ($0.rarity.score * Int($0.variant.multiplier)) > ($1.rarity.score * Int($1.variant.multiplier)) }.prefix(10)
            self.cardsToReveal = top10.sorted { ($0.rarity.score * Int($0.variant.multiplier)) < ($1.rarity.score * Int($1.variant.multiplier)) }
        }
        
        self.currentCardIndex = 0
        self.isOpeningPack = true
        self.isShowingSummary = false
    }
    
    private func selectRarity(for packType: PackType) -> Rarity {
        let random = Double.random(in: 0...100)
        var cumulative = 0.0
        let chances: [Rarity: Double]
        if packType == .premium { chances = [.common: 45.0, .rare: 30.0, .epic: 16.0, .legendary: 7.0, .mythic: 1.9, .god: 0.1] }
        else { chances = [.common: 80.0, .rare: 15.0, .epic: 3.5, .legendary: 1.2, .mythic: 0.28, .god: 0.02] }
        for rarity in Rarity.allCases { cumulative += chances[rarity] ?? 0; if random <= cumulative { return rarity } }
        return .common
    }
    
    private func selectVariant(for packType: PackType) -> CardVariant {
        if packType == .standard { return .standard }
        let random = Double.random(in: 0...100)
        if random < 0.5 { return .holo } else if random < 1.5 { return .shiny } else if random < 3.5 { return .lucky } else if random < 8.5 { return .matt }
        return .standard
    }
    func hasCard(originalID: Int) -> Bool { collection.contains(where: { $0.originalID == originalID }) }
}

// --- 3. UI KOMPONENSEK ---

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    init() { UITabBar.appearance().backgroundColor = UIColor.secondarySystemBackground }
    
    var body: some View {
        TabView {
            GameView(gameState: gameState).tabItem { Label("Shop", systemImage: "cart.fill") }
            StashView(gameState: gameState).tabItem { Label("Stash", systemImage: "archivebox.fill") }
            CollectionBookView(gameState: gameState).tabItem { Label("Album", systemImage: "book.closed.fill") }
            StatsView(gameState: gameState).tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
        }
        .accentColor(.indigo)
        .overlay(Group {
            if gameState.isShowingPackSelection { PackSelectionOverlay(gameState: gameState) }
            if gameState.isShowingSummary { PackSummaryView(gameState: gameState) }
            else if gameState.isOpeningPack { BoosterPackSwipeView(gameState: gameState) }
        })
    }
}

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
                        Text("ACTIVE SHELF (\(gameState.equippedCardIDs.count)/10)")
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
                    
                    Text("Generates Income").font(.caption).foregroundColor(.green)
                    
                    LazyVGrid(columns: shelfColumns, spacing: 10) {
                        ForEach(0..<10) { index in
                            if index < gameState.equippedCardIDs.count {
                                let cardId = gameState.equippedCardIDs[index]
                                if let card = gameState.collection.first(where: { $0.id == cardId }) {
                                    ShelfCardItem(card: card).onTapGesture { gameState.unequipCard(card) }
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
                        let inventory = gameState.collection.filter { !gameState.equippedCardIDs.contains($0.id) }.sorted { $0.passiveIncome > $1.passiveIncome }
                        if inventory.isEmpty {
                            Text("No cards in inventory.\nOpen packs to get cards!").multilineTextAlignment(.center).foregroundColor(.gray).padding(.top, 50)
                        } else {
                            LazyVGrid(columns: inventoryColumns, spacing: 12) {
                                ForEach(inventory) { card in
                                    MiniSummaryCard(card: card).onTapGesture { gameState.equipCard(card) }
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
            ZStack { LinearGradient(colors: card.rarity.color, startPoint: .top, endPoint: .bottom); Image(systemName: "bolt.fill").font(.caption).foregroundColor(.white.opacity(0.8)) }.frame(height: 60)
            VStack(spacing: 0) { Text(card.name).font(.system(size: 7, weight: .bold)).lineLimit(1).foregroundColor(.primary).padding(2); Text("$\(String(format: "%.2f", card.passiveIncome))/s").font(.system(size: 7, weight: .black)).foregroundColor(.green).padding(.bottom, 2) }.frame(height: 30).frame(maxWidth: .infinity).background(Color.white)
        }.clipShape(RoundedRectangle(cornerRadius: 6)).overlay(RoundedRectangle(cornerRadius: 6).stroke(card.variant != .standard ? card.variant.color : Color.white, lineWidth: 2)).shadow(color: card.rarity.color.first!.opacity(0.5), radius: 5)
    }
}

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

// --- EGYÉB MARADT A RÉGI ---
struct PackSelectionOverlay: View {
    @ObservedObject var gameState: GameState
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea().onTapGesture { withAnimation { gameState.isShowingPackSelection = false } }
            VStack(spacing: 20) {
                Text("SELECT PACK TYPE").font(.headline).foregroundColor(.white).padding()
                PackOptionButton(type: .standard, description: "Base chances. No variants.", isSelected: gameState.selectedPackType == .standard, action: { gameState.selectedPackType = .standard; withAnimation { gameState.isShowingPackSelection = false } })
                PackOptionButton(type: .premium, description: "Better odds! Chance for MATT, LUCKY, SHINY, HOLO.", isSelected: gameState.selectedPackType == .premium, action: { gameState.selectedPackType = .premium; withAnimation { gameState.isShowingPackSelection = false } })
                Button("Cancel") { withAnimation { gameState.isShowingPackSelection = false } }.foregroundColor(.white).padding(.top)
            }.padding().background(Color(UIColor.systemGray6)).cornerRadius(20).padding()
        }
    }
}
struct PackOptionButton: View {
    let type: PackType, description: String, isSelected: Bool, action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(type.rawValue).font(.title3).bold()
                    Text(description).font(.caption).foregroundColor(.gray)
                    Text("Price: $\(Int(type.price))").font(.subheadline).foregroundColor(.green).bold().padding(.top, 2)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(.blue).font(.title) }
            }.padding().background(Color.white).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3))
        }.foregroundColor(.black)
    }
}
struct BoosterPackSwipeView: View {
    @ObservedObject var gameState: GameState
    @State private var offset: CGSize = .zero
    @State private var isDragging: Bool = false
    var currentCard: Card? { if gameState.cardsToReveal.indices.contains(gameState.currentCardIndex) { return gameState.cardsToReveal[gameState.currentCardIndex] }; return nil }
    var nextCard: Card? { let nextIndex = gameState.currentCardIndex + 1; if gameState.cardsToReveal.indices.contains(nextIndex) { return gameState.cardsToReveal[nextIndex] }; return nil }
    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            VStack {
                if gameState.showSummaryAfterReveal { Text("TOP 10 PICKS").font(.headline).foregroundColor(.yellow).tracking(2).padding(.top, 50) }
                else { Text("OPENING PACK").font(.headline).foregroundColor(.gray).tracking(2).padding(.top, 50) }
                Spacer()
                ZStack {
                    if let next = nextCard { RealCardView(card: next, width: 300).scaleEffect(0.92).offset(y: 15).brightness(-0.1).opacity(1).id(next.id) }
                    if let current = currentCard { RealCardView(card: current, width: 300).offset(x: offset.width, y: offset.height).rotationEffect(.degrees(Double(offset.width / 15))).shadow(color: Color.black.opacity(0.4), radius: 20).scaleEffect(1.0).gesture(DragGesture().onChanged { g in isDragging = true; offset = g.translation }.onEnded { g in isDragging = false; if abs(offset.width) > 100 || abs(offset.height) > 100 { finishCardReveal(direction: offset) } else { withAnimation(.spring()){ offset = .zero } } }).onTapGesture { finishCardReveal(direction: CGSize(width: 500, height: 0)) }.id(current.id).transition(.scale(scale: 0.92).combined(with: .opacity)) }
                }.padding(.bottom, 50)
                Spacer()
                Text(isDragging ? "Release to reveal" : "Swipe sideways or Tap").font(.subheadline).foregroundColor(.white.opacity(0.5)).padding(.bottom, 50)
            }
        }
    }
    func finishCardReveal(direction: CGSize) {
        let flyAwayOffset = CGSize(width: direction.width > 0 ? 1000 : -1000, height: direction.height * 1.5)
        withAnimation(.easeIn(duration: 0.3)) { offset = flyAwayOffset }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { if gameState.currentCardIndex < gameState.cardsToReveal.count - 1 { gameState.currentCardIndex += 1; offset = .zero } else { finishOpening() } }
    }
    func finishOpening() { gameState.isOpeningPack = false; gameState.isShowingSummary = gameState.showSummaryAfterReveal }
}
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
struct MiniSummaryCard: View {
    let card: Card
    var body: some View {
        VStack(spacing: 0) {
            ZStack { LinearGradient(colors: card.rarity.color, startPoint: .top, endPoint: .bottom); if card.variant != .standard { Image(systemName: "sparkles").font(.caption).foregroundColor(.white) } else { Image(systemName: "shield").font(.caption).foregroundColor(.white.opacity(0.6)) } }.frame(height: 50)
            VStack(spacing: 2) { Text(card.name).font(.system(size: 8, weight: .bold)).lineLimit(1).foregroundColor(.primary); if card.variant != .standard { Text(card.variant.rawValue).font(.system(size: 7, weight: .black)).foregroundColor(card.variant.color) } else { Text("$\(String(format: "%.2f", card.passiveIncome))/s").font(.system(size: 7)).foregroundColor(.green) } }.frame(height: 30).frame(maxWidth: .infinity).background(Color(UIColor.systemGray6))
        }.clipShape(RoundedRectangle(cornerRadius: 6)).overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(card.variant != .standard ? card.variant.color : card.rarity.color.first!, lineWidth: 2))
    }
}
struct RealCardView: View {
    let card: Card; let width: CGFloat; var height: CGFloat { width * 1.45 }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.08).fill(Color(white: 0.96))
            RoundedRectangle(cornerRadius: width * 0.06).strokeBorder(LinearGradient(colors: card.variant != .standard ? [card.variant.color, card.rarity.color.last!] : card.rarity.color, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: width * 0.04).padding(width * 0.04)
            VStack(spacing: 0) {
                ZStack { LinearGradient(colors: card.rarity.color.map({$0.opacity(0.8)}), startPoint: .top, endPoint: .bottom); Image(systemName: iconForRarity(card.rarity)).font(.system(size: width * 0.4)).foregroundColor(.white.opacity(0.3)) }.frame(height: height * 0.5).clipShape(Rectangle()).padding(.top, width * 0.12).padding(.horizontal, width * 0.12)
                VStack(spacing: 4) { Text(card.name).font(.system(size: width * 0.09, weight: .bold, design: .serif)).foregroundColor(.black).lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center); Rectangle().fill(Color.black.opacity(0.2)).frame(height: 1).padding(.horizontal, 10); Text(card.description).font(.system(size: width * 0.055, design: .serif)).italic().foregroundColor(.gray).lineLimit(3).multilineTextAlignment(.leading) }.frame(maxHeight: .infinity).padding(.horizontal, width * 0.12).padding(.bottom, width * 0.1)
                HStack { HStack(spacing: 2) { Image(systemName: "dollarsign.circle.fill"); Text("$\(String(format: "%.2f", card.passiveIncome))/s") }; Spacer(); if card.variant != .standard { Text(card.variant.rawValue).fontWeight(.black).foregroundColor(card.variant.color) } else { Text(card.rarity.rawValue.uppercased()).fontWeight(.black) } }.font(.system(size: width * 0.05, weight: .bold)).foregroundColor(.white).padding(6).background(Color.black.opacity(0.9)).padding(.horizontal, width * 0.08).padding(.bottom, width * 0.08)
            }
            if card.variant == .holo || card.variant == .shiny { LinearGradient(colors: [.white.opacity(0.0), .white.opacity(0.3), .white.opacity(0.0)], startPoint: .topLeading, endPoint: .bottomTrailing).rotationEffect(.degrees(30)).mask(RoundedRectangle(cornerRadius: width * 0.08)) }
        }.frame(width: width, height: height)
    }
    func iconForRarity(_ rarity: Rarity) -> String { switch rarity { case .common: return "shield"; case .rare: return "star"; case .epic: return "bolt"; case .legendary: return "crown"; case .mythic: return "flame"; case .god: return "sun.max" } }
}
struct BoosterPackVisual: View {
    let packType: PackType
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(LinearGradient(colors: packType.color, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 200, height: 300)
            LinearGradient(colors: [.white.opacity(0), .white.opacity(0.4), .white.opacity(0)], startPoint: .topLeading, endPoint: .bottomTrailing).rotationEffect(.degrees(20))
            RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.3), lineWidth: 1)
            VStack {
                Text(packType == .premium ? "LEGENDARY" : "MYSTERY").font(.title).fontWeight(.black).foregroundColor(.white.opacity(0.6)).offset(y: 20)
                Spacer(); Image(systemName: packType == .premium ? "crown.fill" : "cube.box.fill").font(.system(size: 80)).foregroundColor(.white).shadow(color: packType == .premium ? .orange : .purple, radius: 20); Spacer()
                Text(packType.rawValue.uppercased()).font(.headline).fontWeight(.bold).foregroundColor(.white).padding(10).background(Color.black.opacity(0.3)).cornerRadius(10).padding(.bottom, 30)
            }
        }
    }
}
struct BuyButton: View {
    let title: String, subtitle: String, price: Double, color: Color, action: () -> Void, canAfford: Bool
    var body: some View {
        Button(action: action) {
            VStack {
                Text(title).font(.headline).fontWeight(.bold)
                Text(subtitle).font(.caption).opacity(0.8)
                Divider().background(Color.white.opacity(0.5)).padding(.vertical, 4)
                Text("$\(Int(price))").font(.title3).fontWeight(.heavy)
            }.frame(maxWidth: .infinity).padding().background(canAfford ? color : Color.gray).foregroundColor(.white).cornerRadius(12).shadow(color: canAfford ? color.opacity(0.4) : .clear, radius: 8, y: 4)
        }.disabled(!canAfford)
    }
}
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
struct StatsView: View {
    @ObservedObject var gameState: GameState
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General")) {
                    HStack { Text("Total Packs Opened"); Spacer(); Text("\(gameState.packsOpened)") }
                    HStack { Text("Cards Collected"); Spacer(); Text("\(gameState.collection.count)") }
                    HStack { Text("Income (Active)"); Spacer(); Text("$\(String(format: "%.2f", gameState.totalPassiveIncomePerSecond))/s").foregroundColor(.green) }
                }
                Section(header: Text("Variants Found")) {
                    ForEach(CardVariant.allCases.filter{$0 != .standard}, id: \.self) { variant in
                        let count = gameState.collection.filter { $0.variant == variant }.count
                        HStack { Text(variant.rawValue); Spacer(); Text("\(count)").bold() }
                    }
                }
            }.navigationTitle("Stats")
        }
    }
}

#Preview { ContentView() }
