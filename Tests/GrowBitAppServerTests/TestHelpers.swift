//
//  TestHelpers.swift
//  GrowBitAppServer
//

import Foundation
@testable import GrowBitAppServer
import VaporTesting
import Testing

func registerAndLogin(in app: Application, username: String, password: String = "password") async throws -> (token: String, userId: UUID) {
    let user = User(username: username, password: password)
    try await app.testing().test(.POST, "/api/register") { req in
        try req.content.encode(user)
    } afterResponse: { res in
        #expect(res.status == .ok)
    }

    var token = ""
    var userId = UUID()
    try await app.testing().test(.POST, "/api/login") { req in
        try req.content.encode(user)
    } afterResponse: { res in
        #expect(res.status == .ok)
        let response = try res.content.decode(AuthResponseDTO.self)
        token = response.token
        userId = response.userId
    }
    return (token, userId)
}

enum TestError: Error {
    case userCreationFailed
}
