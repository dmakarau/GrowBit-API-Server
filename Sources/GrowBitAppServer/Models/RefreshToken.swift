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

    init() {}

    init(id: UUID? = nil, userId: UUID, expiresAt: Date) {
        self.id = id
        self.token = UUID().uuidString
        self.$user.id = userId
        self.expiresAt = expiresAt
    }
}
