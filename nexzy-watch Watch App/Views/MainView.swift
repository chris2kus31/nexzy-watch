//
//  MainView.swift
//  nexzy-watch
//
//  Created by Christopher Moreno on 9/22/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var coinBalance = 0
    @State private var currentGame: GameData?
    @State private var isListening = false
    @State private var showMenu = false
    @State private var showGameLibrary = false
    @State private var showChatHistory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Navy background matching Nexzy logo
                Color.nexzyNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top bar with hamburger menu - properly positioned
                    HStack {
                        // Hamburger menu on left
                        Button(action: {
                            showMenu = true
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 30, height: 30)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8) // Back to original position
                    .padding(.bottom, 10)
                    
                    // Coin balance bar - centered
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.nexzyGold)
                        Text("\(coinBalance)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("coins")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.15))
                    )
                    .padding(.bottom, 15)
                    
                    // Main Nexzy Logo Button - using PNG image
                    VStack(spacing: 10) {
                        Button(action: {
                            toggleListening()
                        }) {
                            ZStack {
                                // Background circle for tap area
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 90, height: 90)
                                
                                // Your Nexzy logo PNG
                                Image("Nexzy-logo") // Using your actual image name
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .opacity(isListening ? 0.9 : 1.0)
                                
                                // Pulse effect when listening
                                if isListening {
                                    Circle()
                                        .stroke(Color.red.opacity(0.5), lineWidth: 3)
                                        .scaleEffect(isListening ? 1.4 : 1.0)
                                        .opacity(isListening ? 0 : 1)
                                        .animation(
                                            .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                                            value: isListening
                                        )
                                        .frame(width: 80, height: 80)
                                }
                                
                                // Optional: Red overlay when listening
                                if isListening {
                                    Circle()
                                        .fill(Color.red.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(isListening ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isListening)
                        
                        // Status text below button
                        Text(isListening ? "Listening..." : "Tap to speak")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isListening ? Color.red.opacity(0.8) : Color.nexzyLightBlue.opacity(0.8))
                    }
                    
                    Spacer(minLength: 10)
                    
                    // Bottom arrow - properly positioned
                    Button(action: {
                        showChatHistory = true
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.nexzyLightBlue.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 8) // Reduced padding to avoid bleeding
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showMenu) {
            MenuView(
                showGameLibrary: $showGameLibrary,
                showChatHistory: $showChatHistory
            )
        }
        .sheet(isPresented: $showGameLibrary) {
            GameLibraryView(selectedGame: $currentGame)
        }
        .sheet(isPresented: $showChatHistory) {
            ChatHistoryView()
        }
        .task {
            await loadCoinBalance()
        }
    }
    
    private func toggleListening() {
        withAnimation {
            isListening.toggle()
        }
        
        if isListening {
            startListening()
        } else {
            stopListening()
        }
    }
    
    private func startListening() {
        // TODO: Implement speech recognition
        print("Starting speech recognition...")
        WKInterfaceDevice.current().play(.start)
    }
    
    private func stopListening() {
        // TODO: Stop speech recognition and process
        print("Stopping speech recognition...")
        WKInterfaceDevice.current().play(.stop)
    }
    
    private func loadCoinBalance() async {
        do {
            let response = try await APIService.shared.getCoinBalance()
            await MainActor.run {
                self.coinBalance = response.coins
            }
        } catch {
            print("Failed to load coin balance: \(error)")
        }
    }
}

// Menu View
struct MenuView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showGameLibrary: Bool
    @Binding var showChatHistory: Bool
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Menu")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 16))
                    }
                }
                .padding()
                .background(Color.nexzyDarkBg)
                
                // Menu items
                VStack(spacing: 0) {
                    // Game Library
                    MenuRow(
                        icon: "gamecontroller",
                        title: "Games",
                        action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showGameLibrary = true
                            }
                        }
                    )
                    
                    Divider()
                    
                    // Chat History
                    MenuRow(
                        icon: "clock",
                        title: "History",
                        action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showChatHistory = true
                            }
                        }
                    )
                    
                    Divider()
                    
                    // Unpair
                    MenuRow(
                        icon: "link.badge.minus",
                        title: "Unpair",
                        titleColor: .red,
                        action: {
                            Task {
                                try? await authManager.unpairWatch()
                            }
                        }
                    )
                    
                    Spacer()
                }
                .background(Color.nexzyNavy)
            }
        }
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    var titleColor: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(titleColor.opacity(0.8))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(titleColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(titleColor.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// Note: Color extension moved to ColorExtension.swift to avoid duplicates
