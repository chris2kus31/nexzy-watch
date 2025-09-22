//
//  Game.swift
//  nexzy-watch
//

import Foundation

struct GameData: Decodable {
    let id: String
    let name: String
    let platform: String?
    let lastPlayed: Date?
}

struct UserGamesResponse: Decodable {
    let games: [GameData]
}
