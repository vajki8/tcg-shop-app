import SwiftUI

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
