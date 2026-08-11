import SwiftUI

struct MiniSummaryCard: View {
    let card: Card
    var body: some View {
        VStack(spacing: 0) {
            ZStack { LinearGradient(colors: card.rarity.color, startPoint: .top, endPoint: .bottom); if card.variant != .standard { Image(systemName: "sparkles").font(.caption).foregroundColor(.white) } else { Image(systemName: "shield").font(.caption).foregroundColor(.white.opacity(0.6)) } }.frame(height: 50)
            VStack(spacing: 2) { Text(card.name).font(.system(size: 8, weight: .bold)).lineLimit(1).foregroundColor(.primary); if card.variant != .standard { Text(card.variant.rawValue).font(.system(size: 7, weight: .black)).foregroundColor(card.variant.color) } else { Text("$\(String(format: "%.2f", card.sellValue))").font(.system(size: 7)).foregroundColor(.green) } }.frame(height: 30).frame(maxWidth: .infinity).background(Color(UIColor.systemGray6))
        }.clipShape(RoundedRectangle(cornerRadius: 6)).overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(card.variant != .standard ? card.variant.color : card.rarity.color.first!, lineWidth: 2))
    }
}
