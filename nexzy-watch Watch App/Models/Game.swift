//
//  Game.swift
//  nexzy-watch
//

import Foundation
import SwiftUI

struct GameData: Decodable {
    let id: String
    let name: String
    let platform: String?
    let lastPlayed: Date?
}

struct UserGamesResponse: Decodable {
    let games: [GameData]
}

struct WatchLibraryResponse: Codable {
    let games: [WatchGameItem]
    let hasMore: Bool
}

struct WatchGameItem: Codable, Identifiable {
    let id: String
    let libraryId: String
    let name: String
    let image: String?
    let status: GameStatus
    let addedAt: String
    
    enum GameStatus: String, Codable {
        case notStarted = "not_started"
        case playing = "playing"
        case currentlyPlaying = "currently_playing"  // Added this case
        case completed = "completed"
        case onHold = "on_hold"
        case backlog = "backlog"  // Added in case this comes up too
        case dropped = "dropped"  // Added in case this comes up too
    }
    
    // Status display helper
    var statusDisplay: String {
        switch status {
        case .notStarted:
            return "Not Started"
        case .playing, .currentlyPlaying:
            return "Playing"
        case .completed:
            return "Completed"
        case .onHold:
            return "On Hold"
        case .backlog:
            return "Backlog"
        case .dropped:
            return "Dropped"
        }
    }
    
    // Status color helper
    var statusColor: Color {
        switch status {
        case .notStarted:
            return Color.gray
        case .playing, .currentlyPlaying:
            return Color.nexzyLightBlue
        case .completed:
            return Color.green
        case .onHold:
            return Color.orange
        case .backlog:
            return Color.purple
        case .dropped:
            return Color.red.opacity(0.7)
        }
    }
}

struct GameDetailResponse: Codable {
    let id: String
    let name: String
    let image: String?
    let released: String?
    let platforms: [String]
    let description: String?
    let isInLibrary: Bool
    let libraryStatus: String?
    
    // Format release date for display
    var formattedReleaseDate: String {
        guard let released = released else { return "TBA" }
        
        // Parse YYYY-MM-DD format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: released) {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        return released
    }
    
    // Get platform string
    var platformString: String {
        if platforms.isEmpty {
            return "Unknown"
        }
        return platforms.joined(separator: ", ")
    }
}
