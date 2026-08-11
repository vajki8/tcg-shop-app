import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()

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
    }
}

#Preview { ContentView() }
