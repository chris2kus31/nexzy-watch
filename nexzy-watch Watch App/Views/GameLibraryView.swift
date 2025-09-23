//
//  GameLibraryView.swift
//  nexzy-watch
//
//  Created by Christopher Moreno on 9/22/25.
//

import SwiftUI

struct GameLibraryView: View {
    @Binding var selectedGame: GameData?
    @State private var games: [WatchGameItem] = []  // Changed from GameData to WatchGameItem
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var lastCreatedAt: String?
    @State private var lastId: String?
    @State private var hasMorePages = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    let pageSize = 10
    
    var body: some View {
        NavigationView {  // Wrap in NavigationView for navigation
            ZStack {
                Color.nexzyNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Games")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    
                    if isLoading && games.isEmpty {
                        // Initial loading
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Spacer()
                    } else if games.isEmpty {
                        // Empty state
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "gamecontroller")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.3))
                            Text("No games yet")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Add games on mobile")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                    } else {
                        // Games list with NavigationLinks
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(games) { game in
                                    NavigationLink(destination: GameDetailView(
                                        gameId: game.id,
                                        gameName: game.name
                                    )) {
                                        // Simple row view without button wrapper
                                        HStack(spacing: 10) {
                                            // Game Image
                                            if let imageUrl = game.image {
                                                AsyncImage(url: URL(string: imageUrl)) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 40, height: 40)
                                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    case .failure(_), .empty:
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.white.opacity(0.1))
                                                            .frame(width: 40, height: 40)
                                                            .overlay(
                                                                Image(systemName: "gamecontroller.fill")
                                                                    .font(.system(size: 16))
                                                                    .foregroundColor(Color.nexzyLightBlue)
                                                            )
                                                    @unknown default:
                                                        EmptyView()
                                                    }
                                                }
                                            } else {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(width: 40, height: 40)
                                                    .overlay(
                                                        Image(systemName: "gamecontroller.fill")
                                                            .font(.system(size: 16))
                                                            .foregroundColor(Color.nexzyLightBlue)
                                                    )
                                            }
                                            
                                            // Game Info
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(game.name)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                
                                                // Status badge
                                                Text(game.statusDisplay)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(game.statusColor)
                                            }
                                            
                                            Spacer()
                                            
                                            // Navigation chevron instead of checkmark
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.3))
                                        }
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white.opacity(0.1))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // Load more section
                                if hasMorePages {
                                    if isLoadingMore {
                                        HStack {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.6)
                                            Text("Loading...")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        .padding(.vertical, 10)
                                    } else {
                                        Button(action: {
                                            Task {
                                                await loadMoreGames()
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: "arrow.down.circle")
                                                    .font(.system(size: 14))
                                                Text("Load more")
                                                    .font(.system(size: 12))
                                            }
                                            .foregroundColor(Color.nexzyLightBlue)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.vertical, 10)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        }
                    }
                    
                    // Error message if any
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
            }
            .task {
                await loadGames()
            }
        }
    }
    
    // UPDATED: This now calls the real API
    private func loadGames() async {
        guard !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // REAL API CALL HERE
            let response = try await APIService.shared.getWatchLibrary(limit: pageSize)
            
            await MainActor.run {
                self.games = response.games
                
                // Set cursor for next page
                if response.hasMore, let lastItem = response.games.last {
                    self.lastCreatedAt = lastItem.addedAt
                    self.lastId = lastItem.libraryId
                    self.hasMorePages = true
                } else {
                    self.hasMorePages = false
                }
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load games"
                isLoading = false
                print("❌ Failed to load games: \(error)")
            }
        }
    }
    
    private func loadMoreGames() async {
        guard !isLoadingMore, hasMorePages,
              let lastCreatedAt = lastCreatedAt,
              let lastId = lastId else { return }
        
        await MainActor.run {
            isLoadingMore = true
        }
        
        do {
            let response = try await APIService.shared.getWatchLibrary(
                limit: pageSize,
                lastCreatedAt: lastCreatedAt,
                lastId: lastId
            )
            
            await MainActor.run {
                // Append new games
                self.games.append(contentsOf: response.games)
                
                // Update cursor
                if response.hasMore, let lastItem = response.games.last {
                    self.lastCreatedAt = lastItem.addedAt
                    self.lastId = lastItem.libraryId
                } else {
                    self.hasMorePages = false
                }
                
                isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load more"
                isLoadingMore = false
                hasMorePages = false
            }
        }
    }
}

// NEW GameRow that supports WatchGameItem with images
struct GameRowNew: View {
    let game: WatchGameItem
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var imageLoadFailed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Game Image
                if let imageUrl = game.image, !imageLoadFailed {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure(_):
                            // Fallback to icon on failure
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.nexzyLightBlue)
                                )
                                .onAppear { imageLoadFailed = true }
                        case .empty:
                            // Loading state
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // No image URL - show icon
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.nexzyLightBlue)
                        )
                }
                
                // Game Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Status badge
                    Text(game.statusDisplay)
                        .font(.system(size: 10))
                        .foregroundColor(game.statusColor)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.nexzyLightBlue)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.nexzyBlue.opacity(0.2) : Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Keep your old GameRow for backward compatibility if needed elsewhere
struct GameRow: View {
    let game: GameData
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(isSelected ? Color.nexzyBlue : .white.opacity(0.5))
                
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
                        .foregroundColor(Color.nexzyBlue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.nexzyBlue.opacity(0.2) : Color.white.opacity(0.1))
            )
        }
    }
}
