//
//  GrowBitAppServerFetchingCategoriesTests.swift
//  GrowBitAppServer
//
//  Created by Denis Makarau on 08.10.25.
//

@testable import GrowBitAppServer
import VaporTesting
import GrowBitSharedDTO
import Testing
import Fluent

@Suite("Category Fetching Tests")
struct GrowBitAppServerFetchingCategoriesTests {

    @Test("Fetch all categories - Success with multiple categories")
    func fetchAllCategoriesSuccess() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "fetchuser1")

            let categories = [
                ["name": "Work", "colorCode": "#FF0000"],
                ["name": "Personal", "colorCode": "#00FF00"],
                ["name": "Health", "colorCode": "#0000FF"]
            ]
            for category in categories {
                try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(category)
                } afterResponse: { res in
                    #expect(res.status == .ok)
                }
            }

            try await app.testing().test(.GET, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode([CategoryResponseDTO].self)
                #expect(response.count == 3)

                let categoryNames = response.map { $0.name }
                #expect(categoryNames.contains("Work"))
                #expect(categoryNames.contains("Personal"))
                #expect(categoryNames.contains("Health"))

                for category in response {
                    #expect(category.id != nil)
                    #expect(category.colorCode.hasPrefix("#"))
                }
            }
        }
    }

    @Test("Fetch all categories - Success with empty result")
    func fetchAllCategoriesEmptyResult() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "fetchuser2")

            try await app.testing().test(.GET, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode([CategoryResponseDTO].self)
                #expect(response.isEmpty)
            }
        }
    }

    @Test("Fetch all categories - Fail - Invalid userId")
    func fetchAllCategoriesInvalidUserId() async throws {
        try await withApp(configure: configure) { app in
            let (token, _) = try await registerAndLogin(in: app, username: "fetchuser_invalidid")

            try await app.testing().test(.GET, "/api/invalid-uuid/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            } afterResponse: { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test("Fetch all categories - User isolation test")
    func fetchAllCategoriesUserIsolation() async throws {
        try await withApp(configure: configure) { app in
            let (token1, userId1) = try await registerAndLogin(in: app, username: "fetchuser3a")
            let (token2, userId2) = try await registerAndLogin(in: app, username: "fetchuser3b")

            let categories1 = [
                ["name": "Work", "colorCode": "#FF0000"],
                ["name": "Personal", "colorCode": "#00FF00"],
                ["name": "Health", "colorCode": "#0000FF"]
            ]
            for category in categories1 {
                try await app.testing().test(.POST, "/api/\(userId1.uuidString)/categories") { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token1)
                    try req.content.encode(category)
                } afterResponse: { res in
                    #expect(res.status == .ok)
                }
            }

            let categories2 = [
                ["name": "Fitness", "colorCode": "#FFFF00"],
                ["name": "Hobbies", "colorCode": "#FF00FF"]
            ]
            for category in categories2 {
                try await app.testing().test(.POST, "/api/\(userId2.uuidString)/categories") { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token2)
                    try req.content.encode(category)
                } afterResponse: { res in
                    #expect(res.status == .ok)
                }
            }

            try await app.testing().test(.GET, "/api/\(userId1.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token1)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode([CategoryResponseDTO].self)
                #expect(response.count == 3)
                let categoryNames = response.map { $0.name }
                #expect(categoryNames.contains("Work"))
                #expect(categoryNames.contains("Personal"))
                #expect(categoryNames.contains("Health"))
                #expect(!categoryNames.contains("Fitness"))
            }

            try await app.testing().test(.GET, "/api/\(userId2.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token2)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode([CategoryResponseDTO].self)
                #expect(response.count == 2)
                let categoryNames = response.map { $0.name }
                #expect(!categoryNames.contains("Work"))
                #expect(categoryNames.contains("Hobbies"))
                #expect(categoryNames.contains("Fitness"))
            }
        }
    }

    @Test("Fetch all categories - Fail - Cross-user access returns 403")
    func fetchCategoriesCrossUserForbidden() async throws {
        try await withApp(configure: configure) { app in
            let (tokenA, _)  = try await registerAndLogin(in: app, username: "crossuser_a")
            let (_, userBId) = try await registerAndLogin(in: app, username: "crossuser_b")

            try await app.testing().test(.GET, "/api/\(userBId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenA)
            } afterResponse: { res in
                #expect(res.status == .forbidden)
            }
        }
    }

    @Test("Fetch all categories - Verify color normalization persistence")
    func fetchAllCategoriesColorNormalization() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "fetchuser4")

            let categoriesWithColors = [
                ["name": "Cat1", "colorCode": "FF0000"],
                ["name": "Cat2", "colorCode": "#00FF00"]
            ]
            for category in categoriesWithColors {
                try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(category)
                } afterResponse: { res in
                    #expect(res.status == .ok)
                }
            }

            try await app.testing().test(.GET, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode([CategoryResponseDTO].self)
                #expect(response.count == 2)
                for category in response {
                    #expect(category.colorCode.hasPrefix("#"))
                    #expect(category.colorCode.count == 7)
                }
            }
        }
    }
}
