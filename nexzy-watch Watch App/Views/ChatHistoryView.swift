//
//  ChatHistoryView.swift
//  nexzy-watch
//
//  Created by Christopher Moreno on 9/22/25.
//

import SwiftUI

struct ChatHistoryView: View {
    @State private var chatSessions: [ChatSessionData] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if chatSessions.isEmpty {
                    VStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No chat history yet")
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(chatSessions, id: \.id) { session in
                                ChatHistoryRow(session: session)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            // REMOVED: .navigationBarTitleDisplayMode(.inline) - not available in watchOS
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {  // Changed placement for watchOS
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "3B82F6"))
                }
            }
        }
        .task {
            await loadHistory()
        }
    }
    
    private func loadHistory() async {
        // TODO: Load from API
        await MainActor.run {
            isLoading = false
        }
    }
}

struct ChatHistoryRow: View {
    let session: ChatSessionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.message)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
            
            if let game = session.gameContext {
                Label(game, systemImage: "gamecontroller")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "3B82F6"))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}
