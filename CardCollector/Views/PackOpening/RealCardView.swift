import SwiftUI

struct RealCardView: View {
    let card: Card; let width: CGFloat; var height: CGFloat { width * 1.45 }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.08).fill(Color(white: 0.96))
            RoundedRectangle(cornerRadius: width * 0.06).strokeBorder(LinearGradient(colors: card.variant != .standard ? [card.variant.color, card.rarity.color.last!] : card.rarity.color, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: width * 0.04).padding(width * 0.04)
            VStack(spacing: 0) {
                ZStack { LinearGradient(colors: card.rarity.color.map({$0.opacity(0.8)}), startPoint: .top, endPoint: .bottom); Image(systemName: iconForRarity(card.rarity)).font(.system(size: width * 0.4)).foregroundColor(.white.opacity(0.3)) }.frame(height: height * 0.5).clipShape(Rectangle()).padding(.top, width * 0.12).padding(.horizontal, width * 0.12)
                VStack(spacing: 4) { Text(card.name).font(.system(size: width * 0.09, weight: .bold, design: .serif)).foregroundColor(.black).lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center); Rectangle().fill(Color.black.opacity(0.2)).frame(height: 1).padding(.horizontal, 10); Text(card.description).font(.system(size: width * 0.055, design: .serif)).italic().foregroundColor(.gray).lineLimit(3).multilineTextAlignment(.leading) }.frame(maxHeight: .infinity).padding(.horizontal, width * 0.12).padding(.bottom, width * 0.1)
                HStack { HStack(spacing: 2) { Image(systemName: "dollarsign.circle.fill"); Text("$\(String(format: "%.2f", card.sellValue))") }; Spacer(); if card.variant != .standard { Text(card.variant.rawValue).fontWeight(.black).foregroundColor(card.variant.color) } else { Text(card.rarity.rawValue.uppercased()).fontWeight(.black) } }.font(.system(size: width * 0.05, weight: .bold)).foregroundColor(.white).padding(6).background(Color.black.opacity(0.9)).padding(.horizontal, width * 0.08).padding(.bottom, width * 0.08)
            }
            if card.variant == .holo || card.variant == .shiny { LinearGradient(colors: [.white.opacity(0.0), .white.opacity(0.3), .white.opacity(0.0)], startPoint: .topLeading, endPoint: .bottomTrailing).rotationEffect(.degrees(30)).mask(RoundedRectangle(cornerRadius: width * 0.08)) }
        }.frame(width: width, height: height)
    }
    func iconForRarity(_ rarity: Rarity) -> String { switch rarity { case .common: return "shield"; case .rare: return "star"; case .epic: return "bolt"; case .legendary: return "crown"; case .mythic: return "flame"; case .god: return "sun.max" } }
}
