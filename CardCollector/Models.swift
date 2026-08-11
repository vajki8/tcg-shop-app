import SwiftUI

// --- ADAT MODELLEK ---

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

enum PackType: String, CaseIterable, Codable {
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

    // Esély, hogy egy betérő NPC megvegye a bontatlan pakkot egy boltlátogatás során.
    // Ideiglenes placeholder-görbe, amíg nincs igazi balance-fázis.
    var customerInterest: Double {
        switch self {
        case .standard: return 0.5
        case .premium: return 0.08
        }
    }

    // Bontatlan pakk eladási ára a polcon (kis felár a rendelési árhoz képest).
    var shelfPrice: Double { price * 1.15 }
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

    // Ideiglenes fix eladási ár. A bolt-sim balance fázisban ezt
    // az NPC-vásárlási görbe váltja majd fel.
    var baseSellValue: Double {
        switch self {
        case .common: return 1.0
        case .rare: return 6.0
        case .epic: return 35.0
        case .legendary: return 220.0
        case .mythic: return 1400.0
        case .god: return 15000.0
        }
    }

    // Esély, hogy egy betérő NPC megvegye ezt a ritkaságú kártyát egy
    // boltlátogatás során — minél olcsóbb/gyakoribb, annál nagyobb eséllyel kel el.
    var customerInterest: Double {
        switch self {
        case .common: return 0.7
        case .rare: return 0.35
        case .epic: return 0.12
        case .legendary: return 0.04
        case .mythic: return 0.01
        case .god: return 0.0005
        }
    }
}

struct Card: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let name: String
    let description: String
    let rarity: Rarity
    let variant: CardVariant
    let originalID: Int

    var sellValue: Double {
        rarity.baseSellValue * variant.multiplier
    }
}

// Egy megrendelt, még bontatlan pakk — vagy a raktárban vár, vagy a polcon
// eladásra van kitéve az NPC-knek.
struct OrderedPack: Identifiable, Equatable, Codable {
    let id: UUID
    let type: PackType
}
