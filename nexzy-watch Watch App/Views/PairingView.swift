//
//  PairingView.swift - Clean Native watchOS Input
//  nexzy-watch
//

import SwiftUI

struct PairingView: View {
    @State private var pairingCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingCodeEntry = false
    
    let codeLength = 6
    
    var body: some View {
        ZStack {
            // Dark background using Nexzy brand color
            Color.nexzyDarkBg
                .ignoresSafeArea()
            
            VStack(spacing: 15) {
                // Logo
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.nexzyBlue, Color.nexzyLightBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 10)
                
                Text("Pair Nexzy")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Enter code from app")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Display entered code if any
                if !pairingCode.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(0..<codeLength, id: \.self) { index in
                            CodeDigitView(
                                digit: digitAt(index),
                                isActive: false
                            )
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                // Main action button
                Button(action: {
                    showingCodeEntry = true
                }) {
                    HStack {
                        Image(systemName: pairingCode.isEmpty ? "number.circle" : "pencil.circle")
                        Text(pairingCode.isEmpty ? "Enter Code" : "Change Code")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.nexzyBlue)
                    .cornerRadius(20)
                }
                .sheet(isPresented: $showingCodeEntry) {
                    CodeEntryView(code: $pairingCode) { finalCode in
                        pairingCode = finalCode
                        showingCodeEntry = false
                        if finalCode.count == codeLength {
                            Task {
                                await pairWatch()
                            }
                        }
                    }
                }
                
                // Error message (only show when present)
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
        }
    }
    
    private func digitAt(_ index: Int) -> String {
        if index < pairingCode.count {
            let stringIndex = pairingCode.index(pairingCode.startIndex, offsetBy: index)
            return String(pairingCode[stringIndex])
        }
        return ""
    }
    
    private func pairWatch() async {
        // Prevent multiple simultaneous attempts
        guard !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            try await AuthManager.shared.pairWatch(with: pairingCode)
            // Success - ContentView will handle navigation
        } catch {
            await MainActor.run {
                isLoading = false
                handleError(error)
                // Clear code on error
                pairingCode = ""
            }
        }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIService.APIError {
            switch apiError {
            case .invalidCode:
                errorMessage = "Invalid code"
            case .rateLimited(let seconds):
                errorMessage = "Wait \(seconds)s"
            case .alreadyPaired:
                errorMessage = "Already paired"
            case .maxDevicesReached:
                errorMessage = "Max devices"
            default:
                errorMessage = "Failed. Try again"
            }
        } else {
            errorMessage = "Connection failed"
        }
    }
}

// Simplified native text input view
struct CodeEntryView: View {
    @Binding var code: String
    @State private var tempCode = ""
    @State private var isSubmitting = false  // Add flag to prevent multiple submits
    let onSubmit: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Enter 6-digit code")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // Show current code length
            Text("\(tempCode.count)/6")
                .font(.caption)
                .foregroundColor(tempCode.count == 6 ? .green : .gray)
            
            // Using TextField with proper limiting
            TextField("000000", text: Binding(
                get: { tempCode },
                set: { newValue in
                    // Immediately filter and limit input
                    let filtered = newValue.filter { $0.isNumber }
                    tempCode = String(filtered.prefix(6))
                    
                    // Auto-submit when 6 digits entered (only once)
                    if tempCode.count == 6 && !isSubmitting {
                        isSubmitting = true
                        // Small delay to allow UI to update
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSubmit(tempCode)
                        }
                    }
                }
            ))
            .font(.title2)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .disabled(isSubmitting)  // Disable input while submitting
            
            Spacer()
        }
        .onAppear {
            tempCode = code
            isSubmitting = false
        }
    }
}

struct CodeDigitView: View {
    let digit: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.nexzyBlue, lineWidth: 1.5)
                .frame(width: 22, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(digit.isEmpty ? Color.white.opacity(0.1) : Color.nexzyBlue.opacity(0.2))
                )
            
            Text(digit.isEmpty ? "•" : digit)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// Note: Color extension moved to ColorExtension.swift to avoid duplicates
