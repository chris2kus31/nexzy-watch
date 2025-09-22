import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isValidating = true
    
    var body: some View {
        Group {
            if isValidating {
                // Splash screen while checking auth
                SplashView()
            } else if authManager.isAuthenticated {
                MainView()
            } else {
                PairingView()
            }
        }
        .task {
            await validateSession()
        }
    }
    
    private func validateSession() async {
        // Check if we have stored tokens
        if await authManager.getAuthToken() != nil {
            // Validate with backend
            let isValid = await authManager.validateSession()
            if !isValid {
                // Invalid session, need to re-pair
                await authManager.logout()
            }
        }
        
        withAnimation {
            isValidating = false
        }
    }
}
