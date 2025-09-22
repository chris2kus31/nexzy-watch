//
//  ChatHistoryView.swift
//  nexzy-watch
//
//  Created by Christopher Moreno on 9/22/25.
//

import SwiftUI

struct ChatHistoryView: View {
    @State private var historyItems: [QuestionHistoryItem] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var lastCreatedAt: String?
    @State private var lastId: String?
    @State private var hasMorePages = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    let pageSize = 10
    
    var body: some View {
        ZStack {
            Color.nexzyNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - reduced padding
                HStack {
                    Text("History")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6) // Reduced from 10
                
                if isLoading && historyItems.isEmpty {
                    // Initial loading
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Spacer()
                } else if historyItems.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No chat history yet")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Start a conversation!")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    Spacer()
                } else {
                    // History list
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(historyItems) { item in
                                ChatHistoryRow(item: item) {
                                    // Handle tap - could open chat session
                                    openChatSession(sessionId: item.sessionId)
                                }
                            }
                            
                            // Load more indicator
                            if hasMorePages {
                                if isLoadingMore {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.6)
                                        Text("Loading...")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(.vertical, 10)
                                } else {
                                    // Load more trigger
                                    Button(action: {
                                        Task {
                                            await loadMoreHistory()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.down.circle")
                                                .font(.system(size: 14))
                                            Text("Load more")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundColor(Color.nexzyLightBlue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.vertical, 10)
                                }
                            } else if !historyItems.isEmpty {
                                // End of list indicator
                                Text("End of history")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.3))
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    }
                }
                
                // Error message if any
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
        }
        .task {
            await loadHistory()
        }
    }
    
    private func loadHistory() async {
        guard !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response = try await APIService.shared.getQuestionHistory(limit: pageSize)
            
            await MainActor.run {
                self.historyItems = response.data
                
                // Set cursor for next page if we got full page
                if response.data.count == pageSize,
                   let lastItem = response.data.last {
                    self.lastCreatedAt = lastItem.createdAt
                    self.lastId = lastItem.sessionId
                    self.hasMorePages = true
                } else {
                    self.hasMorePages = false
                }
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load history"
                isLoading = false
                print("❌ Failed to load history: \(error)")
            }
        }
    }
    
    private func loadMoreHistory() async {
        guard !isLoadingMore, hasMorePages,
              let lastCreatedAt = lastCreatedAt,
              let lastId = lastId else { return }
        
        await MainActor.run {
            isLoadingMore = true
        }
        
        do {
            let response = try await APIService.shared.getQuestionHistory(
                limit: pageSize,
                lastCreatedAt: lastCreatedAt,
                lastId: lastId
            )
            
            await MainActor.run {
                // Append new items
                self.historyItems.append(contentsOf: response.data)
                
                // Update cursor if we got more items
                if response.data.count == pageSize,
                   let lastItem = response.data.last {
                    self.lastCreatedAt = lastItem.createdAt
                    self.lastId = lastItem.sessionId
                } else {
                    self.hasMorePages = false
                }
                
                isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load more"
                isLoadingMore = false
                hasMorePages = false
            }
        }
    }
    
    private func openChatSession(sessionId: String) {
        // TODO: Navigate to chat session detail view
        // For now, just dismiss and could pass the sessionId back
        print("Opening session: \(sessionId)")
        dismiss()
    }
}

struct ChatHistoryRow: View {
    let item: QuestionHistoryItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Time with clock icon
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(item.relativeTime)
                        .font(.system(size: 11))
                }
                .foregroundColor(Color.nexzyLightBlue.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
