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
                // White background like ChatGPT
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Bar with proper spacing
                    HStack {
                        // Hamburger menu - smaller
                        Button(action: {
                            showMenu = true
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "0F172A"))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 30, height: 30)
                        
                        Spacer()
                        
                        // Coin balance - moved left to avoid time
                        HStack(spacing: 3) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "FFC107"))
                            Text("\(coinBalance)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "0F172A"))
                        }
                        .padding(.trailing, 20) // Keep away from time
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 15)
                    
                    // Tagline with mic icon - using Nexzy colors
                    HStack(spacing: 6) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "3B82F6"))
                        Text("Tap to Nexzy")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "0F172A"))
                    }
                    .padding(.bottom, 25)
                    
                    // Main Nexzy Logo Button - responsive size with Nexzy blue
                    Button(action: {
                        toggleListening()
                    }) {
                        ZStack {
                            Circle()
                                .fill(isListening ? Color.red : Color(hex: "3B82F6"))
                                .frame(width: 85, height: 85)
                            
                            // Nexzy lightning bolt logo
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(isListening ? 0 : -10))
                                .animation(.easeInOut(duration: 0.3), value: isListening)
                            
                            // Pulse effect when listening
                            if isListening {
                                Circle()
                                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
                                    .scaleEffect(isListening ? 1.4 : 1.0)
                                    .opacity(isListening ? 0 : 1)
                                    .animation(
                                        .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                                        value: isListening
                                    )
                                    .frame(width: 85, height: 85)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isListening ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isListening)
                    
                    Spacer()
                    
                    // Bottom arrow - clean without overlay
                    VStack(spacing: 0) {
                        Button(action: {
                            // TODO: Show recent chats
                        }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(hex: "3B82F6").opacity(0.5))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 40, height: 30)
                    }
                    .padding(.bottom, 15)
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
                .background(Color(hex: "0F172A"))
                
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
                .background(Color(hex: "1A1F2E"))
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
