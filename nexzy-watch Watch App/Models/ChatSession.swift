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

struct QuestionHistoryResponse: Codable {
    let data: [QuestionHistoryItem]
}

struct QuestionHistoryItem: Codable, Identifiable {
    let sessionId: String
    let createdAt: String
    let title: String
    
    var id: String { sessionId }
    
    // Computed property to format date nicely
    var formattedDate: String {
        // Parse ISO date and format for display
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
    
    // Computed property for relative time (e.g., "2 hours ago")
    var relativeTime: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            let interval = Date().timeIntervalSince(date)
            
            if interval < 60 {
                return "Just now"
            } else if interval < 3600 {
                let minutes = Int(interval / 60)
                return "\(minutes) min ago"
            } else if interval < 86400 {
                let hours = Int(interval / 3600)
                return "\(hours) hour\(hours == 1 ? "" : "s") ago"
            } else {
                let days = Int(interval / 86400)
                return "\(days) day\(days == 1 ? "" : "s") ago"
            }
        }
        return createdAt
    }
}
