import SwiftUI

// Új tétel polcra tételéhez: saját ár beállítása kitehetés előtt.
struct PriceEditorSheet: View {
    let title: String
    let suggestedPrice: Double
    let confirmLabel: String
    let onConfirm: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var price: Double

    init(title: String, suggestedPrice: Double, confirmLabel: String, onConfirm: @escaping (Double) -> Void) {
        self.title = title
        self.suggestedPrice = suggestedPrice
        self.confirmLabel = confirmLabel
        self.onConfirm = onConfirm
        _price = State(initialValue: suggestedPrice)
    }

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 8)
            Text(title).font(.headline)
            Text("Suggested price: $\(String(format: "%.2f", suggestedPrice))").font(.caption).foregroundColor(.gray)

            HStack(spacing: 24) {
                Button { price = max(0.5, price - step) } label: { Image(systemName: "minus.circle.fill").font(.system(size: 34)) }
                Text("$\(String(format: "%.2f", price))").font(.system(size: 32, weight: .bold, design: .rounded)).frame(minWidth: 130)
                Button { price += step } label: { Image(systemName: "plus.circle.fill").font(.system(size: 34)) }
            }.foregroundColor(.indigo)

            Text(hint).font(.caption).bold().foregroundColor(hintColor)

            Button("Reset to Suggested") { price = suggestedPrice }.font(.caption)

            Button(confirmLabel) { onConfirm(price); dismiss() }
                .font(.headline).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding()
                .background(Color.green).clipShape(Capsule())
                .padding(.horizontal)

            Spacer(minLength: 4)
        }
        .padding()
        .presentationDetents([.height(360)])
    }

    private var step: Double { max(0.5, (suggestedPrice * 0.1).rounded()) }

    private var hint: String {
        if price > suggestedPrice * 1.3 { return "Pricey — fewer customers will buy" }
        if price < suggestedPrice * 0.7 { return "Bargain — sells fast, less profit" }
        return "Fair price"
    }

    private var hintColor: Color {
        if price > suggestedPrice * 1.3 { return .red }
        if price < suggestedPrice * 0.7 { return .green }
        return .gray
    }
}
