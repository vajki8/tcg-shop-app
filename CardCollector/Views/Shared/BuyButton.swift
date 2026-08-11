import SwiftUI

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
