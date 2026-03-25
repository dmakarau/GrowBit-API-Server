//
//  GrowBitAppServerRefreshTokenTests.swift
//  GrowBitAppServer
//

import Foundation
@testable import GrowBitAppServer
import GrowBitSharedDTO
import VaporTesting
import Testing
import Fluent

@Suite("Refresh Token Tests")
struct GrowBitAppServerRefreshTokenTests {

    private func createAndLoginUser(in app: Application, username: String = "refreshuser") async throws -> (accessToken: String, refreshToken: String, userId: UUID) {
        let user = User(username: username, password: "password")
        try await app.testing().test(.POST, "/api/register") { req in
            try req.content.encode(user)
        } afterResponse: { res in
            #expect(res.status == .ok)
        }

        var accessToken = ""
        var refreshToken = ""
        var userId = UUID()

        try await app.testing().test(.POST, "/api/login") { req in
            try req.content.encode(user)
        } afterResponse: { res in
            #expect(res.status == .ok)
            let response = try res.content.decode(AuthResponseDTO.self)
            accessToken = response.token
            refreshToken = response.refreshToken
            userId = response.userId
        }

        return (accessToken, refreshToken, userId)
    }

    @Test("Login returns both access token and refresh token")
    func loginReturnsBothTokens() async throws {
        try await withApp(configure: configure) { app in
            let (accessToken, refreshToken, _) = try await createAndLoginUser(in: app)
            #expect(!accessToken.isEmpty)
            #expect(!refreshToken.isEmpty)
        }
    }

    @Test("Refresh success - returns new access token")
    func refreshSuccess() async throws {
        try await withApp(configure: configure) { app in
            let (originalToken, refreshToken, _) = try await createAndLoginUser(in: app)

            var newAccessToken = ""
            try await app.testing().test(.POST, "/api/refresh") { req in
                try req.content.encode(["refreshToken": refreshToken])
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode(RefreshResponseDTO.self)
                #expect(!response.token.isEmpty)
                newAccessToken = response.token
            }

            #expect(newAccessToken != originalToken)
        }
    }

    @Test("Refresh fails with invalid token")
    func refreshFailsInvalidToken() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.POST, "/api/refresh") { req in
                try req.content.encode(["refreshToken": "not-a-real-token"])
            } afterResponse: { res in
                #expect(res.status == .unauthorized)
                #expect(res.body.string.contains("Invalid refresh token"))
            }
        }
    }

    @Test("Refresh fails with expired token")
    func refreshFailsExpiredToken() async throws {
        try await withApp(configure: configure) { app in
            let (_, _, userId) = try await createAndLoginUser(in: app)

            // Insert an already-expired refresh token directly into the DB
            let expiredToken = RefreshToken(
                userId: userId,
                expiresAt: Date().addingTimeInterval(-60)
            )
            try await expiredToken.save(on: app.db)

            try await app.testing().test(.POST, "/api/refresh") { req in
                try req.content.encode(["refreshToken": expiredToken.token])
            } afterResponse: { res in
                #expect(res.status == .unauthorized)
                #expect(res.body.string.contains("expired"))
            }
        }
    }
}
