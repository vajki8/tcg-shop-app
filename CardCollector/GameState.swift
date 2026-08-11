import SwiftUI
import Combine

// --- JÁTÉK LOGIKA (GameState) ---

class GameState: ObservableObject {
    @Published var money: Double = 15.0
    @Published var collection: [Card] = []
    // "Kirakatba tett, eladásra váró kártya" — az NPC-k ezek közül vásárolnak.
    @Published var displayedCardIDs: [UUID] = []
    let maxShelfSlots = 10

    // Megrendelt, bontatlan pakkok. Raktárban várnak, amíg el nem döntöd,
    // kibontod-e, vagy a polcra teszed bontatlanul eladásra.
    @Published var warehousePacks: [OrderedPack] = []
    @Published var shelfPacks: [OrderedPack] = []
    let maxPackShelfSlots = 5

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

    @Published var offlineEarnings: Double? = nil

    // --- BOLT-SIM: BETÉRŐ VÁSÁRLÓK ---
    @Published var activeCustomerEmoji: String? = nil
    @Published var customerXOffset: CGFloat = -160
    @Published var lastSaleText: String? = nil

    private var customerTimer: Timer?
    private static let saveURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("gamesave.json")

    init() {
        self.allCards = GameState.generateCardDatabase()
        loadAndApplyOfflineIncome()
        scheduleNextCustomer()
    }

    // --- OPTIMALIZÁLÁS (AUTO-BEST) ---
    func optimizeStash() {
        displayedCardIDs.removeAll()
        let bestCards = collection.sorted { $0.sellValue > $1.sellValue }
        let topCards = bestCards.prefix(maxShelfSlots)
        displayedCardIDs = topCards.map { $0.id }
        save()
    }

    func displayCard(_ card: Card) {
        guard displayedCardIDs.count < maxShelfSlots else { return }
        guard !displayedCardIDs.contains(card.id) else { return }
        displayedCardIDs.append(card.id)
        save()
    }

    func removeFromDisplay(_ card: Card) {
        if let index = displayedCardIDs.firstIndex(of: card.id) {
            displayedCardIDs.remove(at: index)
            save()
        }
    }

    func sellCard(_ card: Card) {
        guard let index = collection.firstIndex(of: card) else { return }
        collection.remove(at: index)
        displayedCardIDs.removeAll { $0 == card.id }
        money += card.sellValue
        save()
    }

    var displayedCards: [Card] {
        return collection.filter { displayedCardIDs.contains($0.id) }
    }

    // --- RENDELÉS / RAKTÁR / PAKK-POLC ---

    func orderPack(_ type: PackType, amount: Int = 1) {
        let totalCost = type.price * Double(amount)
        guard money >= totalCost else { return }
        money -= totalCost
        for _ in 0..<amount {
            warehousePacks.append(OrderedPack(id: UUID(), type: type))
        }
        save()
    }

    func openPack(_ pack: OrderedPack) {
        guard let index = warehousePacks.firstIndex(of: pack) else { return }
        warehousePacks.remove(at: index)
        packsOpened += 1
        revealCards(for: pack.type)
    }

    func moveToPackShelf(_ pack: OrderedPack) {
        guard shelfPacks.count < maxPackShelfSlots else { return }
        guard let index = warehousePacks.firstIndex(of: pack) else { return }
        warehousePacks.remove(at: index)
        shelfPacks.append(pack)
        save()
    }

    func removeFromPackShelf(_ pack: OrderedPack) {
        guard let index = shelfPacks.firstIndex(of: pack) else { return }
        shelfPacks.remove(at: index)
        warehousePacks.append(pack)
        save()
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

    private func revealCards(for packType: PackType) {
        var generatedCards: [Card] = []
        for _ in 0..<5 {
            let rarity = selectRarity(for: packType)
            let possibleCards = allCards.filter { $0.rarity == rarity }
            let baseCard = possibleCards.randomElement() ?? allCards.first!
            let variant = selectVariant(for: packType)
            let newCard = Card(id: UUID(), name: baseCard.name, description: baseCard.description, rarity: rarity, variant: variant, originalID: baseCard.originalID)
            generatedCards.append(newCard)
            collection.append(newCard)
        }

        self.allNewCards = generatedCards
        self.cardsToReveal = generatedCards
        self.showSummaryAfterReveal = false
        self.currentCardIndex = 0
        self.isOpeningPack = true
        self.isShowingSummary = false
        save()
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

    // --- BOLT-SIM: NPC LÁTOGATÁSOK ---

    private struct SaleCandidate {
        let chance: Double
        let value: Double
        let sell: () -> String
    }

    private var saleCandidates: [SaleCandidate] {
        let packCandidates = shelfPacks.map { pack in
            SaleCandidate(chance: pack.type.customerInterest, value: pack.type.shelfPrice) { [weak self] in
                self?.shelfPacks.removeAll { $0.id == pack.id }
                self?.money += pack.type.shelfPrice
                self?.save()
                return "Sold a sealed \(pack.type.rawValue) for $\(String(format: "%.2f", pack.type.shelfPrice))"
            }
        }
        let cardCandidates = displayedCards.map { card in
            SaleCandidate(chance: card.rarity.customerInterest, value: card.sellValue) { [weak self] in
                let value = card.sellValue
                self?.sellCard(card)
                return "Sold \(card.name) for $\(String(format: "%.2f", value))"
            }
        }
        return packCandidates + cardCandidates
    }

    private func scheduleNextCustomer() {
        let delay = Double.random(in: 3...7)
        customerTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.spawnCustomer()
        }
    }

    private func spawnCustomer() {
        let candidates = saleCandidates
        guard let target = candidates.randomElement() else {
            scheduleNextCustomer()
            return
        }

        activeCustomerEmoji = "🧍"
        withAnimation(.easeInOut(duration: 1.2)) { customerXOffset = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            guard let self else { return }
            if Double.random(in: 0...1) < target.chance {
                self.lastSaleText = target.sell()
            } else {
                self.lastSaleText = "A customer left without buying."
            }
            withAnimation(.easeInOut(duration: 1.0)) { self.customerXOffset = 160 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
                guard let self else { return }
                self.activeCustomerEmoji = nil
                self.customerXOffset = -160
                self.lastSaleText = nil
                self.scheduleNextCustomer()
            }
        }
    }

    // --- PERZISZTENCIA ---

    private struct SaveData: Codable {
        var money: Double
        var collection: [Card]
        var displayedCardIDs: [UUID]
        var warehousePacks: [OrderedPack]
        var shelfPacks: [OrderedPack]
        var packsOpened: Int
        var lastSavedAt: Date
    }

    func save() {
        let data = SaveData(money: money, collection: collection, displayedCardIDs: displayedCardIDs, warehousePacks: warehousePacks, shelfPacks: shelfPacks, packsOpened: packsOpened, lastSavedAt: Date())
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: GameState.saveURL, options: .atomic)
    }

    private func loadAndApplyOfflineIncome() {
        guard let raw = try? Data(contentsOf: GameState.saveURL),
              let data = try? JSONDecoder().decode(SaveData.self, from: raw) else { return }

        money = data.money
        collection = data.collection
        displayedCardIDs = data.displayedCardIDs
        warehousePacks = data.warehousePacks
        shelfPacks = data.shelfPacks
        packsOpened = data.packsOpened

        let elapsedSeconds = Date().timeIntervalSince(data.lastSavedAt)
        guard elapsedSeconds > 5 else { return }

        // Közelítés: átlagosan 5 mp-enként tér be egy vásárló, és minden
        // eladható tétel várható értékének átlagát fizeti ki visszamenőleg.
        // Éles bolt-sim nélkül ez csak egy nagyságrendi becslés.
        let candidates = saleCandidates
        guard !candidates.isEmpty else { return }
        let averageExpectedValuePerVisit = candidates
            .map { $0.chance * $0.value }
            .reduce(0, +) / Double(candidates.count)
        let estimatedVisits = min(elapsedSeconds / 5.0, 200)
        let income = estimatedVisits * averageExpectedValuePerVisit
        if income > 0 {
            money += income
            offlineEarnings = income
        }
    }
}
