//
//  GrowBitAppServerSavingCategoryTests.swift
//  GrowBitAppServer
//
//  Created by Denis Makarau on 06.10.25.
//

@testable import GrowBitAppServer
import VaporTesting
import GrowBitSharedDTO
import Testing
import Fluent

@Suite("Category Creation Tests")
struct GrowBitAppServerSavingCategoryTests {

    private func registerAndLogin(in app: Application, username: String) async throws -> (token: String, userId: UUID) {
        let user = User(username: username, password: "password")
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
            let response = try res.content.decode(AuthResponseDTO.self)
            token = response.token
            userId = response.userId
        }
        return (token, userId)
    }

    @Test("Category creation - Success")
    func categoryCreationSuccess() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "testuser")

            let requestBody = ["name": "test category", "colorCode": "#FFFFFF"]
            try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(requestBody)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode(CategoryResponseDTO.self)
                #expect(response.name == "test category")
                #expect(response.colorCode == "#FFFFFF")
            }
        }
    }

    @Test("Category creation - Fail - Missing name")
    func categoryCreationFailMissingName() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "testuser2")

            let requestBody = ["colorCode": "#FFFFFF"]
            try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(requestBody)
            } afterResponse: { res in
                #expect(res.status == .badRequest)
                #expect(res.body.string.contains("Missing required fields"))
            }
        }
    }

    @Test("Category creation - Fail - Missing colorCode")
    func categoryCreationFailMissingColorCode() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "testuser3")

            let requestBody = ["name": "test category"]
            try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(requestBody)
            } afterResponse: { res in
                #expect(res.status == .badRequest)
                #expect(res.body.string.contains("Missing required fields"))
            }
        }
    }

    @Test("Category creation - Fail - Invalid userId")
    func categoryCreationFailInvalidUserId() async throws {
        try await withApp(configure: configure) { app in
            let (token, _) = try await registerAndLogin(in: app, username: "testuser_invalidid")

            let requestBody = ["name": "test category", "colorCode": "#FFFFFF"]
            try await app.testing().test(.POST, "/api/invalid-uuid/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(requestBody)
            } afterResponse: { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test("Category creation - Fail - Empty name")
    func categoryCreationFailEmptyName() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "testuser4")

            let requestBody = ["name": "", "colorCode": "#FFFFFF"]
            try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(requestBody)
            } afterResponse: { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test("Category creation - Fail - Invalid color code format")
    func categoryCreationFailInvalidColorCode() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "testuser5")

            let requestBody = ["name": "test category", "colorCode": "FF$FF§FF"]
            try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(requestBody)
            } afterResponse: { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test("Category creation - Success - Valid color codes")
    func categoryCreationSuccessVariousColors() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "testuser6")

            let validColors = ["#000000", "#FFFFFF", "#FF0000", "#00FF00", "#0000FF", "#abcdef", "#123456"]
            for (index, color) in validColors.enumerated() {
                let requestBody = ["name": "category \(index)", "colorCode": color]
                try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(requestBody)
                } afterResponse: { res in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(CategoryResponseDTO.self)
                    #expect(response.colorCode.uppercased() == color.uppercased())
                }
            }
        }
    }

    @Test("Category creation - Success - Color normalization")
    func categoryCreationSuccessColorNormalization() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "testuser7")

            let testCases: [(input: String, expected: String)] = [
                ("FF0000", "#FF0000"),
                ("00FF00", "#00FF00"),
                ("0000FF", "#0000FF"),
                ("abcdef", "#ABCDEF"),
                ("123456", "#123456")
            ]
            for (index, testCase) in testCases.enumerated() {
                let requestBody = ["name": "normalized category \(index)", "colorCode": testCase.input]
                try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(requestBody)
                } afterResponse: { res in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(CategoryResponseDTO.self)
                    #expect(response.colorCode.uppercased() == testCase.expected.uppercased())
                }
            }
        }
    }
}

enum TestError: Error {
    case userCreationFailed
}
