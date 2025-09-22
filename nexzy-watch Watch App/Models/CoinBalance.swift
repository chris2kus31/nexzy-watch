//
//  CoinBalance.swift
//  nexzy-watch
//

import Foundation

struct CoinBalanceResponse: Decodable {
    let balance: Int
    let dailyBonusAvailable: Bool?
}
