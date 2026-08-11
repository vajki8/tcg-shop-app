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
