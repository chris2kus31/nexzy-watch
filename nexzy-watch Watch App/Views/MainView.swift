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
    @State private var transcribedText = ""
    @State private var showGameLibrary = false
    @State private var showChatHistory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Top Bar - Coins
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color(hex: "FFC107"))
                            .font(.system(size: 14))
                        
                        Text("\(coinBalance)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Menu button
                        Button(action: {
                            showChatHistory = true
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 18))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Current Game Context
                    if let game = currentGame {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(Color(hex: "3B82F6"))
                                .font(.system(size: 12))
                            
                            Text(game.name)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                            
                            Button(action: {
                                currentGame = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                    }
                    
                    Spacer()
                    
                    // Main Microphone Button
                    ZStack {
                        // Pulse animation when listening
                        if isListening {
                            Circle()
                                .stroke(Color(hex: "3B82F6"), lineWidth: 2)
                                .scaleEffect(isListening ? 1.5 : 1.0)
                                .opacity(isListening ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 1.0)
                                    .repeatForever(autoreverses: false),
                                    value: isListening
                                )
                        }
                        
                        Button(action: {
                            toggleListening()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: isListening ?
                                                [Color(hex: "EF4444"), Color(hex: "DC2626")] :
                                                [Color(hex: "3B82F6"), Color(hex: "2563EB")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 30))
                            }
                        }
                        .scaleEffect(isListening ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isListening)
                    }
                    
                    // Listening indicator
                    if isListening {
                        Text("Listening...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .transition(.opacity)
                    } else {
                        Text(currentGame != nil ? "Ask about \(currentGame!.name)" : "Ask anything...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Bottom action buttons
                    HStack(spacing: 30) {
                        // Game Library
                        Button(action: {
                            showGameLibrary = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 20))
                                Text("Games")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Settings
                        Button(action: {
                            // Show settings
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 20))
                                Text("Settings")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationBarHidden(true)
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
    }
    
    private func stopListening() {
        // TODO: Stop speech recognition and process
        print("Stopping speech recognition...")
    }
    
    private func loadCoinBalance() async {
        do {
            let response = try await APIService.shared.getCoinBalance()
            await MainActor.run {
                self.coinBalance = response.balance
            }
        } catch {
            print("Failed to load coin balance: \(error)")
        }
    }
}
