import Foundation
import Security

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserData?
    
    private let keychain = KeychainWrapper()
    private var accessToken: String?
    private var refreshToken: String?
    
    private init() {
        // Load tokens from keychain on init
        Task {
            await loadStoredTokens()
        }
    }
    
    // MARK: - Device ID Management
    
    func getOrCreateDeviceId() async -> String {
        if let deviceId = keychain.get(Constants.Storage.deviceId) {
            return deviceId
        }
        
        // Generate new device ID
        let deviceId = UUID().uuidString
        keychain.set(deviceId, forKey: Constants.Storage.deviceId)
        return deviceId
    }
    
    func getDeviceId() async -> String? {
        return keychain.get(Constants.Storage.deviceId)
    }
    
    // MARK: - Token Management
    
    func getAuthToken() async -> String? {
        return accessToken
    }
    
    func getRefreshToken() async -> String? {
        // Make sure we're returning the stored refresh token
        if refreshToken == nil {
            refreshToken = keychain.get(Constants.Storage.refreshToken)
        }
        return refreshToken
    }
    
    private func loadStoredTokens() async {
        self.accessToken = keychain.get(Constants.Storage.authToken)
        self.refreshToken = keychain.get(Constants.Storage.refreshToken)
        
        // Debug logging
        print("📱 Loaded tokens from keychain:")
        print("  Access Token: \(accessToken != nil ? "✅ Found" : "❌ Not found")")
        print("  Refresh Token: \(refreshToken != nil ? "✅ Found" : "❌ Not found")")
        
        if accessToken != nil && refreshToken != nil {
            await MainActor.run {
                self.isAuthenticated = true
            }
        }
    }
    
    func saveTokens(accessToken: String, refreshToken: String, user: UserData) async {
        // Save to keychain
        keychain.set(accessToken, forKey: Constants.Storage.authToken)
        keychain.set(refreshToken, forKey: Constants.Storage.refreshToken)
        keychain.set(user.id, forKey: Constants.Storage.userId)
        
        // Save username for display
        UserDefaults.standard.set(user.username, forKey: "username")
        UserDefaults.standard.set(user.coins, forKey: "coinBalance")
        
        // Update local properties
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        // Debug logging
        print("💾 Saved new tokens to keychain")
        print("  Access Token: ✅")
        print("  Refresh Token: ✅")
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func refreshAuthToken() async throws {
        guard let currentRefreshToken = self.refreshToken ?? keychain.get(Constants.Storage.refreshToken) else {
            print("❌ No refresh token available for refresh")
            throw APIService.APIError.unauthorized
        }
        
        print("🔄 Attempting to refresh token...")
        
        do {
            let response = try await APIService.shared.refreshToken(refreshToken: currentRefreshToken)
            
            // Update tokens
            self.accessToken = response.accessToken
            self.refreshToken = response.refreshToken
            
            // Save new tokens to keychain
            keychain.set(response.accessToken, forKey: Constants.Storage.authToken)
            keychain.set(response.refreshToken, forKey: Constants.Storage.refreshToken)
            
            print("✅ Token refresh successful")
            
            // RefreshTokenResponse only has accessToken and refreshToken, no user data
            // Keep existing user data unchanged
            
        } catch {
            print("❌ Token refresh failed: \(error)")
            
            // Only logout if refresh token is truly expired (60 days)
            // Don't logout for temporary network issues
            if case APIService.APIError.unauthorized = error {
                await logout()
            }
            throw error
        }
    }
    
    // MARK: - Pairing
    
    func pairWatch(with code: String) async throws {
        let response = try await APIService.shared.pairWatch(code: code)
        
        // Make sure we save both tokens
        await saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            user: response.user
        )
        
        print("✅ Watch paired successfully")
    }
    
    // MARK: - Validation
    
    func validateSession() async -> Bool {
        // First check if we have tokens
        guard let _ = accessToken ?? keychain.get(Constants.Storage.authToken),
              let _ = refreshToken ?? keychain.get(Constants.Storage.refreshToken) else {
            print("❌ No tokens found for validation")
            return false
        }
        
        do {
            // Try to validate the current session
            let response = try await APIService.shared.validateSession()
            print("✅ Session valid: \(response.valid)")
            return response.valid
        } catch {
            print("❌ Session validation failed: \(error)")
            
            // If validation fails due to expired token, try to refresh
            if case APIService.APIError.unauthorized = error {
                do {
                    print("🔄 Attempting to refresh expired token...")
                    try await refreshAuthToken()
                    // After successful refresh, we're authenticated
                    return true
                } catch {
                    print("❌ Refresh also failed: \(error)")
                    return false
                }
            }
            
            return false
        }
    }
    
    // MARK: - Logout
    
    func logout() async {
        print("🚪 Logging out...")
        
        // Clear keychain
        keychain.remove(Constants.Storage.authToken)
        keychain.remove(Constants.Storage.refreshToken)
        keychain.remove(Constants.Storage.userId)
        keychain.remove(Constants.Storage.deviceId) // Also clear device ID on logout
        
        // Clear memory
        accessToken = nil
        refreshToken = nil
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "coinBalance")
        
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    func unpairWatch() async throws {
        _ = try await APIService.shared.unpairWatch()
        await logout()
    }
}

// MARK: - Simple Keychain Wrapper

class KeychainWrapper {
    
    func set(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.nexzy.watch", // Add service identifier
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            print("❌ Keychain save failed for \(key): \(status)")
        }
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.nexzy.watch", // Add service identifier
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }
    
    func remove(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.nexzy.watch" // Add service identifier
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
