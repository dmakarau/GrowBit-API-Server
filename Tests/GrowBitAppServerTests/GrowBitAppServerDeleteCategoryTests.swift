//
//  GrowBitAppServerDeleteCategoryTests.swift
//  GrowBitAppServer
//
//  Created by Denis Makarau on 08.10.25.
//

@testable import GrowBitAppServer
import VaporTesting
import GrowBitSharedDTO
import Testing
import Fluent

@Suite("Category Deletion Tests")
struct GrowBitAppServerDeleteCategoryTests {

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

    @Test("Delete category - Success")
    func deleteCategorySuccess() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "deleteuser1")

            let categoryRequestBody = ["name": "Test Category", "colorCode": "#FF0000"]
            var categoryId: UUID?
            try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(categoryRequestBody)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode(CategoryResponseDTO.self)
                categoryId = response.id
                #expect(response.name == "Test Category")
            }

            guard let unwrappedCategoryId = categoryId else {
                throw TestError.userCreationFailed
            }

            try await app.testing().test(.DELETE, "/api/\(userId.uuidString)/categories/\(unwrappedCategoryId.uuidString)") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode(CategoryResponseDTO.self)
                #expect(response.id == unwrappedCategoryId)
                #expect(response.name == "Test Category")
                #expect(response.colorCode == "#FF0000")
            }

            let deletedCategory = try await Category.query(on: app.db)
                .filter(\.$id == unwrappedCategoryId)
                .first()
            #expect(deletedCategory == nil)
        }
    }

    @Test("Delete category - Verify category is removed from list")
    func deleteCategoryVerifyRemoval() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "deleteuser2")

            let categories = [
                ["name": "Work", "colorCode": "#FF0000"],
                ["name": "Personal", "colorCode": "#00FF00"],
                ["name": "Health", "colorCode": "#0000FF"]
            ]

            var categoryIds: [UUID] = []
            for category in categories {
                try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(category)
                } afterResponse: { res in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(CategoryResponseDTO.self)
                    categoryIds.append(response.id)
                }
            }

            #expect(categoryIds.count == 3)

            try await app.testing().test(.DELETE, "/api/\(userId.uuidString)/categories/\(categoryIds[1].uuidString)") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode(CategoryResponseDTO.self)
                #expect(response.id == categoryIds[1])
                #expect(response.name == "Personal")
                #expect(response.colorCode == "#00FF00")
            }

            let deletedCategory = try await Category.query(on: app.db)
                .filter(\.$id == categoryIds[1])
                .first()
            #expect(deletedCategory == nil)

            var category = try await Category.query(on: app.db)
                .filter(\.$id == categoryIds[0])
                .first()
            #expect(category != nil)

            category = try await Category.query(on: app.db)
                .filter(\.$id == categoryIds[2])
                .first()
            #expect(category != nil)
        }
    }

    @Test("Delete category - Fail - Invalid categoryId")
    func deleteCategoryInvalidCategoryId() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "deleteuser3")

            try await app.testing().test(.DELETE, "/api/\(userId.uuidString)/categories/invalid-uuid") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            } afterResponse: { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test("Delete category - Fail - Non-existent categoryId")
    func deleteCategoryNonExistentCategoryId() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "deleteuser4")

            let nonExistentId = UUID()
            try await app.testing().test(.DELETE, "/api/\(userId.uuidString)/categories/\(nonExistentId.uuidString)") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            } afterResponse: { res in
                #expect(res.status == .notFound)
                #expect(res.body.string.contains("Category not found"))
            }
        }
    }

    @Test("Delete category - Fail - Invalid userId")
    func deleteCategoryInvalidUserId() async throws {
        try await withApp(configure: configure) { app in
            let (token, userId) = try await registerAndLogin(in: app, username: "deleteuser5")

            let categoryRequestBody = ["name": "Test Category", "colorCode": "#FF0000"]
            var categoryId: UUID?
            try await app.testing().test(.POST, "/api/\(userId.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(categoryRequestBody)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode(CategoryResponseDTO.self)
                categoryId = response.id
            }

            guard let unwrappedCategoryId = categoryId else {
                throw TestError.userCreationFailed
            }

            try await app.testing().test(.DELETE, "/api/invalid-uuid/categories/\(unwrappedCategoryId.uuidString)") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            } afterResponse: { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test("Delete category - User isolation test")
    func deleteCategoryUserIsolation() async throws {
        try await withApp(configure: configure) { app in
            let (token1, userId1) = try await registerAndLogin(in: app, username: "deleteuser6a")
            let (token2, userId2) = try await registerAndLogin(in: app, username: "deleteuser6b")

            let categoryRequestBody = ["name": "User1 Category", "colorCode": "#FF0000"]
            var user1CategoryId: UUID?
            try await app.testing().test(.POST, "/api/\(userId1.uuidString)/categories") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token1)
                try req.content.encode(categoryRequestBody)
            } afterResponse: { res in
                #expect(res.status == .ok)
                let response = try res.content.decode(CategoryResponseDTO.self)
                user1CategoryId = response.id
            }

            guard let unwrappedUser1CategoryId = user1CategoryId else {
                throw TestError.userCreationFailed
            }

            // user2 tries to delete user1's category via user2's path — not found (belongs to user1)
            try await app.testing().test(.DELETE, "/api/\(userId2.uuidString)/categories/\(unwrappedUser1CategoryId.uuidString)") { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token2)
            } afterResponse: { res in
                #expect(res.status == .notFound)
                #expect(res.body.string.contains("Category not found"))
            }

            let category = try await Category.query(on: app.db)
                .filter(\.$id == unwrappedUser1CategoryId)
                .filter(\.$user.$id == userId1)
                .first()
            #expect(category != nil)
        }
    }
}
