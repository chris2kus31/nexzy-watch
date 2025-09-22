//
//  MenuView.swift
//  nexzy-watch
//
//  Menu component for navigation options
//

import SwiftUI

struct MenuView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showGameLibrary: Bool
    @Binding var showChatHistory: Bool
    @StateObject private var authManager = AuthManager.shared
    @State private var showUnpairConfirm = false
    
    var body: some View {
        ZStack {
            // Background
            Color.nexzyNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - just the title
                HStack {
                    Text("Menu")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                
                // Menu Options
                ScrollView {
                    VStack(spacing: 8) {
                        // Games
                        MenuButton(
                            icon: "gamecontroller.fill",
                            title: "Games",
                            iconColor: Color.nexzyLightBlue,
                            action: {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showGameLibrary = true
                                }
                            }
                        )
                        
                        // History
                        MenuButton(
                            icon: "clock.fill",
                            title: "History",
                            iconColor: Color.nexzyLightBlue,
                            action: {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showChatHistory = true
                                }
                            }
                        )
                        
                        // Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1)
                            .padding(.vertical, 4)
                        
                        // Unpair
                        MenuButton(
                            icon: "link.badge.minus",
                            title: "Unpair",
                            iconColor: .red,
                            textColor: .red,
                            backgroundColor: Color.red.opacity(0.15),
                            action: {
                                showUnpairConfirm = true
                            }
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            }
        }
        .alert("Unpair Watch?", isPresented: $showUnpairConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Unpair", role: .destructive) {
                Task {
                    try? await authManager.unpairWatch()
                }
            }
        } message: {
            Text("You'll need to pair again from the mobile app")
        }
    }
}

// Reusable Menu Button Component
struct MenuButton: View {
    let icon: String
    let title: String
    var iconColor: Color = Color.nexzyLightBlue
    var textColor: Color = .white
    var backgroundColor: Color = Color.white.opacity(0.1)
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(textColor)
                
                Spacer()
                
                if textColor == .white {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
