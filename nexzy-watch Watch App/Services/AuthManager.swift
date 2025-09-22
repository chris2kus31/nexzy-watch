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
    
    private func loadStoredTokens() async {
        self.accessToken = keychain.get(Constants.Storage.authToken)
        self.refreshToken = keychain.get(Constants.Storage.refreshToken)
        
        if accessToken != nil {
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
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func refreshAuthToken() async throws {
        guard let refreshToken = self.refreshToken else {
            throw APIService.APIError.unauthorized
        }
        
        do {
            let response = try await APIService.shared.refreshToken(refreshToken: refreshToken)
            
            // Update tokens
            self.accessToken = response.accessToken
            self.refreshToken = response.refreshToken
            
            // Save new tokens
            keychain.set(response.accessToken, forKey: Constants.Storage.authToken)
            keychain.set(response.refreshToken, forKey: Constants.Storage.refreshToken)
            
        } catch {
            // If refresh fails, clear everything and force re-pair
            await logout()
            throw error
        }
    }
    
    // MARK: - Pairing
    
    func pairWatch(with code: String) async throws {
        let response = try await APIService.shared.pairWatch(code: code)
        await saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            user: response.user
        )
    }
    
    // MARK: - Validation
    
    func validateSession() async -> Bool {
        do {
            let response = try await APIService.shared.validateSession()
            return response.valid
        } catch {
            print("Validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Logout
    
    func logout() async {
        // Clear keychain
        keychain.remove(Constants.Storage.authToken)
        keychain.remove(Constants.Storage.refreshToken)
        keychain.remove(Constants.Storage.userId)
        
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
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
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
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
