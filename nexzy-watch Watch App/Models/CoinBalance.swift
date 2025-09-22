//
//  CoinBalance.swift
//  nexzy-watch
//

import Foundation

struct CoinBalanceResponse: Decodable {
    let coins: Int
    let nexzyTokens: Int
    let username: String
    let updatedAt: String
    
    // Computed property for backward compatibility
    var balance: Int {
        return coins
    }
}
