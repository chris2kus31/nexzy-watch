//
//  ChatSession.swift
//  nexzy-watch
//

import Foundation

struct ChatSessionData: Decodable {
    let id: String
    let message: String
    let response: String
    let gameContext: String?
    let timestamp: Date
}

struct ChatSessionResponse: Decodable {
    let response: String
    let sessionId: String
    let coinsRemaining: Int
    let gameContext: String?
}

struct ChatHistoryResponse: Decodable {
    let sessions: [ChatSessionData]
}
