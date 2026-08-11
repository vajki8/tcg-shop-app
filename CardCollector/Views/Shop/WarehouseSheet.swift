import SwiftUI

// A megrendelt, még bontatlan pakkok kezelése — kibontás vagy polcra tétel.
struct WarehouseSheet: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPack: OrderedPack?
    @State private var packToPrice: OrderedPack?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            Group {
                if gameState.warehousePacks.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "shippingbox").font(.system(size: 44)).foregroundColor(.gray)
                        Text("No packs ordered yet.").foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(gameState.warehousePacks) { pack in
                                WarehousePackItem(pack: pack)
                                    .onTapGesture { selectedPack = pack }
                            }
                        }.padding()
                    }
                }
            }
            .navigationTitle("Warehouse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .confirmationDialog(
            selectedPack.map { $0.type.rawValue } ?? "",
            isPresented: Binding(get: { selectedPack != nil }, set: { if !$0 { selectedPack = nil } }),
            titleVisibility: .visible
        ) {
            if let pack = selectedPack {
                Button("Open") { gameState.openPack(pack); dismiss() }
                Button("Put on Shelf") { packToPrice = pack }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $packToPrice) { pack in
            PriceEditorSheet(title: "Sealed \(pack.type.rawValue)", suggestedPrice: pack.type.shelfPrice, confirmLabel: "Put on Shelf") { price in
                gameState.moveToPackShelf(pack, price: price)
            }
        }
    }
}

struct WarehousePackItem: View {
    let pack: OrderedPack
    var body: some View {
        VStack(spacing: 6) {
            SealedPackIcon(color: pack.type == .premium ? .orange : .blue, size: 34)
            Text(pack.type == .premium ? "Premium" : "Standard").font(.system(size: 10, weight: .bold))
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
