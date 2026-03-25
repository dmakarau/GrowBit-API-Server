//
//  CreateRefreshTokensTableMigration.swift
//  GrowBitAppServer
//

import Fluent
import SQLKit

struct CreateRefreshTokensTableMigration: AsyncMigration {

    func prepare(on database: any Database) async throws {
        try await database.schema("refresh_tokens")
            .id()
            .field("token", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("expires_at", .datetime, .required)
            .unique(on: "token")
            .create()

        if let sql = database as? any SQLDatabase {
            try await sql.raw("CREATE INDEX idx_rt_user_id ON refresh_tokens (user_id)").run()
            try await sql.raw("CREATE INDEX idx_rt_user_expires ON refresh_tokens (user_id, expires_at)").run()
        }
    }

    func revert(on database: any Database) async throws {
        try await database.schema("refresh_tokens").delete()
    }
}
