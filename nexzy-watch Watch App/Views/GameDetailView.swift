//
//  GameDetailView.swift
//  nexzy-watch
//
//  Shows detailed information about a selected game
//

import SwiftUI

struct GameDetailView: View {
    let gameId: String
    let gameName: String // For immediate display while loading
    
    @State private var gameDetail: GameDetailResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var imageLoadFailed = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.nexzyNavy
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    if isLoading {
                        // Loading state
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Loading game details...")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                    } else if let detail = gameDetail {
                        // Game image
                        if let imageUrl = detail.image, !imageLoadFailed {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                case .failure(_):
                                    gameImagePlaceholder
                                        .onAppear { imageLoadFailed = true }
                                case .empty:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 120)
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.5)
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        )
                                @unknown default:
                                    gameImagePlaceholder
                                }
                            }
                        } else {
                            gameImagePlaceholder
                        }
                        
                        // Game title
                        Text(detail.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Game info
                        VStack(spacing: 8) {
                            // Platforms
                            HStack(spacing: 4) {
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.nexzyLightBlue)
                                Text(detail.platformString)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Release date
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.nexzyLightBlue)
                                Text(detail.formattedReleaseDate)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Library status if in library
                            if detail.isInLibrary, let status = detail.libraryStatus {
                                HStack(spacing: 4) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.nexzyGold)
                                    Text(formatStatus(status))
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.nexzyGold)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                        )
                        
                        // Description
                        if let description = detail.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("About")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.nexzyLightBlue)
                                
                                Text(description)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.05))
                            )
                        }
                        
                        // Ask Nexzy AI Button
                        Button(action: {
                            askNexzyAI()
                        }) {
                            HStack(spacing: 8) {
                                // Your Nexzy logo
                                Image("Nexzy-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("Ask Nexzy AI")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.nexzyBlue, Color.nexzyLightBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                        
                    } else if let error = errorMessage {
                        // Error state
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                Task {
                                    await loadGameDetails()
                                }
                            }) {
                                Text("Retry")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.nexzyBlue)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
        }
        .navigationTitle(gameName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadGameDetails()
        }
    }
    
    private var gameImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.1))
            .frame(height: 120)
            .overlay(
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.nexzyLightBlue.opacity(0.5))
            )
    }
    
    private func loadGameDetails() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let details = try await APIService.shared.getGameDetails(gameId: gameId)
            
            await MainActor.run {
                self.gameDetail = details
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load game details"
                isLoading = false
                print("❌ Failed to load game details: \(error)")
            }
        }
    }
    
    private func formatStatus(_ status: String) -> String {
        switch status {
        case "not_started":
            return "Not Started"
        case "playing", "currently_playing":
            return "Playing"
        case "completed":
            return "Completed"
        case "on_hold":
            return "On Hold"
        case "backlog":
            return "Backlog"
        default:
            return status.capitalized
        }
    }
    
    private func askNexzyAI() {
        // TODO: Implement Ask Nexzy AI functionality
        print("🤖 Ask Nexzy AI about: \(gameName)")
        // For now, just dismiss and could pass the game context back
        dismiss()
    }
}
