import SwiftUI

struct StatsView: View {
    @ObservedObject var gameState: GameState
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General")) {
                    HStack { Text("Total Packs Opened"); Spacer(); Text("\(gameState.packsOpened)") }
                    HStack { Text("Cards Collected"); Spacer(); Text("\(gameState.collection.count)") }
                    HStack { Text("Packs In Warehouse"); Spacer(); Text("\(gameState.warehousePacks.count)") }
                    HStack { Text("Sealed Packs On Shelf"); Spacer(); Text("\(gameState.shelfPacks.count)") }
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
