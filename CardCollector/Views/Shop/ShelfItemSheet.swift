import SwiftUI

// Egy már polcon lévő tétel (kártya vagy bontatlan pakk) egyesített megjelenítése.
enum ShelfDisplayItem: Identifiable {
    case card(Card)
    case pack(OrderedPack)

    var id: String {
        switch self {
        case .card(let card): return "card-\(card.id.uuidString)"
        case .pack(let pack): return "pack-\(pack.id.uuidString)"
        }
    }

    var basePrice: Double {
        switch self {
        case .card(let card): return card.sellValue
        case .pack(let pack): return pack.type.shelfPrice
        }
    }

    var displayName: String {
        switch self {
        case .card(let card): return card.name
        case .pack(let pack): return "Sealed \(pack.type.rawValue)"
        }
    }
}

// Már kitett tétel kezelése: ár módosítása, levétel, azonnali eladás.
struct ShelfItemSheet: View {
    let item: ShelfDisplayItem
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var price: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 8)
            Text(item.displayName).font(.headline)
            Text("Suggested price: $\(String(format: "%.2f", item.basePrice))").font(.caption).foregroundColor(.gray)

            HStack(spacing: 24) {
                Button { price = max(0.5, price - step) } label: { Image(systemName: "minus.circle.fill").font(.system(size: 34)) }
                Text("$\(String(format: "%.2f", price))").font(.system(size: 32, weight: .bold, design: .rounded)).frame(minWidth: 130)
                Button { price += step } label: { Image(systemName: "plus.circle.fill").font(.system(size: 34)) }
            }.foregroundColor(.indigo)

            Text(hint).font(.caption).bold().foregroundColor(hintColor)

            Button("Update Price") {
                switch item {
                case .card(let card): gameState.updateCardPrice(card, price: price)
                case .pack(let pack): gameState.updatePackPrice(pack, price: price)
                }
                dismiss()
            }
            .font(.headline).foregroundColor(.white)
            .frame(maxWidth: .infinity).padding()
            .background(Color.indigo).clipShape(Capsule())
            .padding(.horizontal)

            HStack(spacing: 12) {
                Button("Remove From Shelf") {
                    switch item {
                    case .card(let card): gameState.removeFromDisplay(card)
                    case .pack(let pack): gameState.removeFromPackShelf(pack)
                    }
                    dismiss()
                }
                .font(.subheadline).foregroundColor(.orange)

                Button("Sell Now") {
                    switch item {
                    case .card(let card): gameState.sellCard(card)
                    case .pack(let pack): gameState.sellPackNow(pack)
                    }
                    dismiss()
                }
                .font(.subheadline).foregroundColor(.red)
            }

            Spacer(minLength: 4)
        }
        .padding()
        .presentationDetents([.height(420)])
        .onAppear {
            switch item {
            case .card(let card): price = gameState.price(for: card)
            case .pack(let pack): price = gameState.price(for: pack)
            }
        }
    }

    private var step: Double { max(0.5, (item.basePrice * 0.1).rounded()) }

    private var hint: String {
        if price > item.basePrice * 1.3 { return "Pricey — fewer customers will buy" }
        if price < item.basePrice * 0.7 { return "Bargain — sells fast, less profit" }
        return "Fair price"
    }

    private var hintColor: Color {
        if price > item.basePrice * 1.3 { return .red }
        if price < item.basePrice * 0.7 { return .green }
        return .gray
    }
}
