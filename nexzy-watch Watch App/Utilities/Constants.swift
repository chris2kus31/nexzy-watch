import Foundation

struct Constants {
    // API Configuration
    static let apiBaseURL = "https://bf4ea9ec557c.ngrok.app" // Your ngrok URL
    static let apiTimeout: TimeInterval = 30
    
    // API Endpoints
    struct Endpoints {
        static let login = "/auth/watch/pair"
        static let refreshToken = "/auth/refresh"
        static let coinBalance = "/user/coins"
        static let chatSession = "/chat/session"
        static let userGames = "/games/library"
    }
    
    // Storage Keys
    struct Storage {
        static let authToken = "nexzy.authToken"
        static let refreshToken = "nexzy.refreshToken"
        static let userId = "nexzy.userId"
        static let deviceId = "nexzy.deviceId"  // ← ADD THIS LINE
        static let lastGameId = "nexzy.lastGameId"
    }
    
    // App Configuration
    static let maxRecentGames = 10
    static let sessionTimeout: TimeInterval = 1800 // 30 minutes
}
