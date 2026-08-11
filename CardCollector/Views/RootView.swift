import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @Environment(\.scenePhase) private var scenePhase

    init() { UITabBar.appearance().backgroundColor = UIColor.secondarySystemBackground }

    var body: some View {
        TabView {
            GameView(gameState: gameState).tabItem { Label("Shop", systemImage: "cart.fill") }
            StashView(gameState: gameState).tabItem { Label("Stash", systemImage: "archivebox.fill") }
            CollectionBookView(gameState: gameState).tabItem { Label("Album", systemImage: "book.closed.fill") }
            StatsView(gameState: gameState).tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
        }
        .accentColor(.indigo)
        .overlay(Group {
            if gameState.isShowingPackSelection { PackSelectionOverlay(gameState: gameState) }
            if gameState.isShowingSummary { PackSummaryView(gameState: gameState) }
            else if gameState.isOpeningPack { BoosterPackSwipeView(gameState: gameState) }
        })
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { gameState.save() }
        }
        .alert("Welcome back!", isPresented: Binding(
            get: { gameState.offlineEarnings != nil },
            set: { if !$0 { gameState.offlineEarnings = nil } }
        )) {
            Button("Nice") { gameState.offlineEarnings = nil }
        } message: {
            if let earnings = gameState.offlineEarnings {
                Text("Your stash earned $\(String(format: "%.2f", earnings)) while you were away.")
            }
        }
    }
}

#Preview { ContentView() }
