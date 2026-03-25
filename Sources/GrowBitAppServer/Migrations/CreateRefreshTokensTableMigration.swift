//
//  CreateRefreshTokensTableMigration.swift
//  GrowBitAppServer
//

import Fluent

struct CreateRefreshTokensTableMigration: AsyncMigration {

    func prepare(on database: any Database) async throws {
        try await database.schema("refresh_tokens")
            .id()
            .field("token", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("expires_at", .datetime, .required)
            .unique(on: "token")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("refresh_tokens").delete()
    }
}
