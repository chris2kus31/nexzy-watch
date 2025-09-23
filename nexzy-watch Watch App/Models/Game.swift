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
