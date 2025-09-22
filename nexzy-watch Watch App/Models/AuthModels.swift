//
//  AuthModels.swift
//  nexzy-watch
//

import Foundation

struct UserData: Decodable {
    let id: String
    let username: String
    let coins: Int
}

struct ErrorResponse: Decodable {
    let statusCode: Int
    let message: String
}

struct PairWatchResponse: Decodable {
    let message: String
    let accessToken: String
    let refreshToken: String
    let user: UserData
}

struct RefreshTokenResponse: Decodable {
    let message: String
    let accessToken: String
    let refreshToken: String
}

struct ValidateSessionResponse: Decodable {
    let valid: Bool
    let userId: String
    let deviceId: String
}

struct MessageResponse: Decodable {
    let message: String
}
