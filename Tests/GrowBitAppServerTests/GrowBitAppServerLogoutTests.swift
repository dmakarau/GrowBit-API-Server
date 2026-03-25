//
//  GrowBitAppServerLogoutTests.swift
//  GrowBitAppServer
//

import Foundation
@testable import GrowBitAppServer
import GrowBitSharedDTO
import VaporTesting
import Testing

@Suite("Logout Tests")
struct GrowBitAppServerLogoutTests {

    private func createAndLoginUser(in app: Application, username: String) async throws -> (accessToken: String, refreshToken: String) {
        let user = User(username: username, password: "password")
        try await app.testing().test(.POST, "/api/register") { req in
            try req.content.encode(user)
        } afterResponse: { res in
            #expect(res.status == .ok)
        }

        var accessToken = ""
        var refreshToken = ""

        try await app.testing().test(.POST, "/api/login") { req in
            try req.content.encode(user)
        } afterResponse: { res in
            #expect(res.status == .ok)
            let response = try res.content.decode(AuthResponseDTO.self)
            accessToken = response.token
            refreshToken = response.refreshToken
        }

        return (accessToken, refreshToken)
    }

    @Test("Logout success - refresh token is revoked")
    func logoutRevokesRefreshToken() async throws {
        try await withApp(configure: configure) { app in
            let (_, refreshToken) = try await createAndLoginUser(in: app, username: "logoutuser1")

            try await app.testing().test(.POST, "/api/logout") { req in
                try req.content.encode(["refreshToken": refreshToken])
            } afterResponse: { res in
                #expect(res.status == .ok)
            }

            // Revoked token should no longer work for refresh
            try await app.testing().test(.POST, "/api/refresh") { req in
                try req.content.encode(["refreshToken": refreshToken])
            } afterResponse: { res in
                #expect(res.status == .unauthorized)
            }
        }
    }

    @Test("Logout with unknown token returns 200 (idempotent)")
    func logoutUnknownTokenIsIdempotent() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.POST, "/api/logout") { req in
                try req.content.encode(["refreshToken": "totally-fake-token"])
            } afterResponse: { res in
                #expect(res.status == .ok)
            }
        }
    }

    @Test("Double logout is idempotent")
    func doubleLogoutIsIdempotent() async throws {
        try await withApp(configure: configure) { app in
            let (_, refreshToken) = try await createAndLoginUser(in: app, username: "logoutuser2")

            try await app.testing().test(.POST, "/api/logout") { req in
                try req.content.encode(["refreshToken": refreshToken])
            } afterResponse: { res in
                #expect(res.status == .ok)
            }

            try await app.testing().test(.POST, "/api/logout") { req in
                try req.content.encode(["refreshToken": refreshToken])
            } afterResponse: { res in
                #expect(res.status == .ok)
            }
        }
    }

    @Test("Logout one session, other session still works")
    func logoutOneSessionKeepsOtherAlive() async throws {
        try await withApp(configure: configure) { app in
            let user = User(username: "logoutuser3", password: "password")
            try await app.testing().test(.POST, "/api/register") { req in
                try req.content.encode(user)
            } afterResponse: { res in
                #expect(res.status == .ok)
            }

            // First login
            var refreshToken1 = ""
            try await app.testing().test(.POST, "/api/login") { req in
                try req.content.encode(user)
            } afterResponse: { res in
                let response = try res.content.decode(AuthResponseDTO.self)
                refreshToken1 = response.refreshToken
            }

            // Second login
            var refreshToken2 = ""
            try await app.testing().test(.POST, "/api/login") { req in
                try req.content.encode(user)
            } afterResponse: { res in
                let response = try res.content.decode(AuthResponseDTO.self)
                refreshToken2 = response.refreshToken
            }

            // Logout first session
            try await app.testing().test(.POST, "/api/logout") { req in
                try req.content.encode(["refreshToken": refreshToken1])
            } afterResponse: { res in
                #expect(res.status == .ok)
            }

            // Second session should still be valid
            try await app.testing().test(.POST, "/api/refresh") { req in
                try req.content.encode(["refreshToken": refreshToken2])
            } afterResponse: { res in
                #expect(res.status == .ok)
            }
        }
    }
}
