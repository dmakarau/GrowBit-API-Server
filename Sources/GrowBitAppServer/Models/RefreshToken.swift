//
//  RefreshToken.swift
//  GrowBitAppServer
//

import Foundation
import Fluent
import Vapor

final class RefreshToken: Model, @unchecked Sendable {
    static let schema = "refresh_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "token")
    var token: String

    @Parent(key: "user_id")
    var user: User

    @Field(key: "expires_at")
    var expiresAt: Date

    // Transient — holds the raw token after creation, never persisted
    var rawToken: String = ""

    static func hash(_ raw: String) -> String {
        SHA256.hash(data: Data(raw.utf8)).hex
    }

    init() {}

    init(id: UUID? = nil, userId: UUID, expiresAt: Date) {
        let raw = UUID().uuidString
        self.id = id
        self.rawToken = raw
        self.token = RefreshToken.hash(raw)
        self.$user.id = userId
        self.expiresAt = expiresAt
    }
}
