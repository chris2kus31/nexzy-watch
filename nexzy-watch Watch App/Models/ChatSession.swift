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
    
    // Computed property for relative time (e.g., "2 hours ago")
    var relativeTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: createdAt) {
            let interval = Date().timeIntervalSince(date)
            
            if interval < 60 {
                return "Just now"
            } else if interval < 3600 {
                let minutes = Int(interval / 60)
                return "\(minutes) min\(minutes == 1 ? "" : "s") ago"
            } else if interval < 86400 {
                let hours = Int(interval / 3600)
                return "\(hours) hr\(hours == 1 ? "" : "s") ago"
            } else if interval < 604800 {
                let days = Int(interval / 86400)
                return "\(days) day\(days == 1 ? "" : "s") ago"
            } else if interval < 2592000 {
                let weeks = Int(interval / 604800)
                return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
            } else {
                let months = Int(interval / 2592000)
                return "\(months) month\(months == 1 ? "" : "s") ago"
            }
        }
        return "Unknown"
    }
}
