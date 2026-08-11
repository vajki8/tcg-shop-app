import SwiftUI

struct BoosterPackVisual: View {
    let packType: PackType
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(LinearGradient(colors: packType.color, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 200, height: 300)
            LinearGradient(colors: [.white.opacity(0), .white.opacity(0.4), .white.opacity(0)], startPoint: .topLeading, endPoint: .bottomTrailing).rotationEffect(.degrees(20))
            RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.3), lineWidth: 1)
            VStack {
                Text(packType == .premium ? "LEGENDARY" : "MYSTERY").font(.title).fontWeight(.black).foregroundColor(.white.opacity(0.6)).offset(y: 20)
                Spacer(); Image(systemName: packType == .premium ? "crown.fill" : "cube.box.fill").font(.system(size: 80)).foregroundColor(.white).shadow(color: packType == .premium ? .orange : .purple, radius: 20); Spacer()
                Text(packType.rawValue.uppercased()).font(.headline).fontWeight(.bold).foregroundColor(.white).padding(10).background(Color.black.opacity(0.3)).cornerRadius(10).padding(.bottom, 30)
            }
        }
    }
}
