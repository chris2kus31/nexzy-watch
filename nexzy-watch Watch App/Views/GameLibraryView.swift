//
//  GameLibraryView.swift
//  nexzy-watch
//
//  Created by Christopher Moreno on 9/22/25.
//

import SwiftUI

struct GameLibraryView: View {
    @Binding var selectedGame: GameData?
    @State private var games: [GameData] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(games, id: \.id) { game in
                                GameRow(game: game, isSelected: selectedGame?.id == game.id) {
                                    selectedGame = game
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Game")
            // REMOVED: .navigationBarTitleDisplayMode(.inline) - not available in watchOS
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {  // Changed placement for watchOS
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "3B82F6"))
                }
            }
        }
        .task {
            await loadGames()
        }
    }
    
    private func loadGames() async {
        // TODO: Load from API
        await MainActor.run {
            // Mock data for now
            games = [
                GameData(id: "1", name: "Elden Ring", platform: "PS5", lastPlayed: nil),
                GameData(id: "2", name: "Zelda TOTK", platform: "Switch", lastPlayed: nil),
                GameData(id: "3", name: "Spider-Man 2", platform: "PS5", lastPlayed: nil)
            ]
            isLoading = false
        }
    }
}

struct GameRow: View {
    let game: GameData
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(isSelected ? Color(hex: "3B82F6") : .white.opacity(0.5))
                
                VStack(alignment: .leading) {
                    Text(game.name)
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    if let platform = game.platform {
                        Text(platform)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "3B82F6"))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "3B82F6").opacity(0.2) : Color.white.opacity(0.1))
            )
        }
    }
}
