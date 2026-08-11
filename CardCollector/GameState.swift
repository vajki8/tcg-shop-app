import SwiftUI
import Combine

// --- JÁTÉK LOGIKA (GameState) ---

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
