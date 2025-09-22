import Foundation
import WatchKit

class APIService: ObservableObject {
    static let shared = APIService()
    private let session = URLSession.shared
    
    private init() {}
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError
        case unauthorized
        case rateLimited(retryAfter: Int)
        case serverError(String)
        case noConnection
        case invalidCode
        case alreadyPaired
        case maxDevicesReached
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .noData:
                return "No data received"
            case .decodingError:
                return "Failed to decode response"
            case .unauthorized:
                return "Session expired"
            case .rateLimited(let seconds):
                return "Too many attempts. Wait \(seconds) seconds"
            case .serverError(let message):
                return message
            case .noConnection:
                return "No internet connection"
            case .invalidCode:
                return "Invalid or expired code"
            case .alreadyPaired:
                return "Watch already paired"
            case .maxDevicesReached:
                return "Maximum watches reached"
            }
        }
    }
    
    // MARK: - Generic Request Method
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authenticated: Bool = true,
        includeDeviceId: Bool = false
    ) async throws -> T {
        guard let url = URL(string: Constants.apiBaseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = Constants.apiTimeout
        
        // Debug log headers
        print("📋 Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        // Add auth token if needed
        if authenticated, let token = await AuthManager.shared.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add device ID header if needed
        if includeDeviceId, let deviceId = await AuthManager.shared.getDeviceId() {
            request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        }
        
        // Add body if present
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                print("📤 Request Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
            } catch {
                print("❌ Failed to serialize body: \(error)")
                throw APIError.decodingError
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("Invalid response")
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
                
            case 401:
                // Try to parse specific error first
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    print("❌ 401 Error: \(errorResponse.message)")
                    if errorResponse.message.contains("Invalid or expired") {
                        throw APIError.invalidCode
                    }
                } else if let rawString = String(data: data, encoding: .utf8) {
                    print("❌ 401 Raw Response: \(rawString)")
                }
                
                // Token expired, try refresh if we're authenticated
                if authenticated {
                    try await AuthManager.shared.refreshAuthToken()
                    // Retry request with new token
                    return try await self.request(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        authenticated: authenticated,
                        includeDeviceId: includeDeviceId
                    )
                }
                throw APIError.unauthorized
                
            case 403:
                throw APIError.maxDevicesReached
                
            case 409:
                throw APIError.alreadyPaired
                
            case 429:
                // Parse retry-after if available
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                let seconds = Int(retryAfter ?? "300") ?? 300
                throw APIError.rateLimited(retryAfter: seconds)
                
            default:
                // Log the full error response for debugging
                if let rawString = String(data: data, encoding: .utf8) {
                    print("❌ Error \(httpResponse.statusCode): \(rawString)")
                }
                
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.message)
                }
                throw APIError.serverError("Status code: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ Request failed: \(error)")
            if error is APIError {
                throw error
            }
            throw APIError.noConnection
        }
    }
    
    // MARK: - Auth Endpoints
    
    func pairWatch(code: String) async throws -> PairWatchResponse {
        let deviceId = await AuthManager.shared.getOrCreateDeviceId()
        let deviceName = "\(await getUsername())'s Apple Watch"
        
        // Ensure body matches PairWatchDto structure exactly
        let body: [String: Any] = [
            "code": code,
            "deviceId": deviceId,
            "deviceName": deviceName,
            "capabilities": [
                "hasHaptics": true,
                "screenSize": WKInterfaceDevice.current().screenBounds.width > 180 ? "45mm" : "41mm",
                "osVersion": "watchOS \(WKInterfaceDevice.current().systemVersion)"
            ]
        ]
        
        // Debug logging
        print("📱 Pairing Request:")
        print("  Code: \(code)")
        print("  DeviceID: \(deviceId)")
        print("  DeviceName: \(deviceName)")
        print("  Endpoint: \(Constants.apiBaseURL)/auth/watch/pair")
        print("  Body: \(body)")
        
        return try await request(
            endpoint: "/auth/watch/pair",
            method: "POST",
            body: body,
            authenticated: false
        )
    }
    
    func refreshToken(refreshToken: String) async throws -> RefreshTokenResponse {
        let deviceId = await AuthManager.shared.getOrCreateDeviceId()
        
        let body: [String: Any] = [
            "refreshToken": refreshToken,
            "deviceId": deviceId
        ]
        
        return try await request(
            endpoint: "/auth/watch/refresh",
            method: "POST",
            body: body,
            authenticated: false
        )
    }
    
    func validateSession() async throws -> ValidateSessionResponse {
        return try await request(
            endpoint: "/auth/watch/validate",
            method: "GET",
            authenticated: true,
            includeDeviceId: true
        )
    }
    
    func unpairWatch() async throws -> MessageResponse {
        let deviceId = await AuthManager.shared.getOrCreateDeviceId()
        
        let body: [String: Any] = [
            "deviceId": deviceId
        ]
        
        return try await request(
            endpoint: "/auth/watch/unpair",
            method: "POST",
            body: body,
            authenticated: true
        )
    }
    
    // MARK: - Game & Chat Endpoints
    
    func getCoinBalance() async throws -> CoinBalanceResponse {
        // Updated endpoint to match your backend
        return try await request(endpoint: "/auth/watch/coins", method: "GET")
    }
    
    func getUserGames() async throws -> UserGamesResponse {
        return try await request(endpoint: "/games/library")
    }
    
    func startChatSession(
        message: String,
        gameId: String? = nil
    ) async throws -> ChatSessionResponse {
        let body: [String: Any] = [
            "message": message,
            "gameId": gameId ?? ""
        ]
        return try await request(
            endpoint: "/chat/session",
            method: "POST",
            body: body
        )
    }
    
    func getChatHistory(limit: Int = 20) async throws -> ChatHistoryResponse {
        return try await request(
            endpoint: "/chat/history?limit=\(limit)"
        )
    }
    
    // MARK: - Chat History with Cursor Pagination
    
    func getQuestionHistory(
        limit: Int = 10,
        lastCreatedAt: String? = nil,
        lastId: String? = nil
    ) async throws -> QuestionHistoryResponse {
        var endpoint = "/questions/all?limit=\(limit)"
        
        // Add cursor parameters if provided
        if let lastCreatedAt = lastCreatedAt, let lastId = lastId {
            endpoint += "&lastCreatedAt=\(lastCreatedAt)&lastId=\(lastId)"
        }
        
        return try await request(
            endpoint: endpoint,
            method: "GET",
            authenticated: true
        )
    }
    
    // MARK: - Helper Methods
    
    private func getUsername() async -> String {
        // Try to get from stored user data, fallback to "User"
        if let username = UserDefaults.standard.string(forKey: "username") {
            return username
        }
        return "User"
    }
}

// ALL STRUCT DEFINITIONS REMOVED - They're now in separate model files:
// - AuthModels.swift (UserData, PairWatchResponse, etc.)
// - Game.swift (GameData, UserGamesResponse)
// - ChatSession.swift (ChatSessionData, ChatSessionResponse, ChatHistoryResponse)
// - CoinBalance.swift (CoinBalanceResponse)
