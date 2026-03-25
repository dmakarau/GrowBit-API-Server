//
//  HabitsController.swift
//  GrowBitAppServer
//
//  Created by Denis Makarau on 03.10.25.
//

import Foundation
import Vapor
import GrowBitSharedDTO

struct HabitsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        
        // /api/:userId — JWT protected
        let api = routes.grouped("api", ":userId")
            .grouped(JWTAuthMiddleware())

        // POST: saving a habbit category
        // /api/:userId/categories
        api.post("categories", use: saveHabitCategory)

        // GET: getting all categories for a user
        // /api/:userId/categories
        api.get("categories", use: getAllCategoriesForUser)

        // DELETE: deleting a category
        // /api/:userId/categories/:categoryId
        api.delete("categories", ":categoryId", use: deleteCategory)
    }
    
    @Sendable func saveHabitCategory(req: Request) async throws -> CategoryResponseDTO {

        // get the user id
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Missing or invalid userId parameter") // HTTP 400
        }

        // Decode request as a simple dictionary to get name and colorCode
        let requestData = try req.content.decode([String: String].self)
        guard let name = requestData["name"],
              let colorCode = requestData["colorCode"] else {
            throw Abort(.badRequest, reason: "Missing required fields: name and colorCode") // HTTP 400
        }

        // Validate empty name
        guard !name.isEmpty else {
            throw Abort(.badRequest, reason: "Category name cannot be empty") // HTTP 400
        }

        // Validate color code format (RRGGBB or #RRGGBB)
        let colorCodePattern = #"^#?([A-Fa-f0-9]{6})$"#
        guard colorCode.range(of: colorCodePattern, options: .regularExpression) != nil else {
            throw Abort(.badRequest, reason: "Color code should be in format RRGGBB or #RRGGBB") // HTTP 400
        }

        // Normalize color code to always include #
        let normalizedColorCode = colorCode.hasPrefix("#") ? colorCode : "#\(colorCode)"

        // Check for duplicate category name for this user (case-insensitive)
        let existingCategories = try await Category.query(on: req.db)
            .filter(\.$user.$id, .equal, userId)
            .all()

        let existingCategory = existingCategories.first(where: { $0.name.lowercased() == name.lowercased() })

        if existingCategory != nil {
            throw Abort(.conflict, reason: "A category with this name already exists") // HTTP 409
        }

        let habitCategory = Category(
            name: name,
            colorCode: normalizedColorCode,
            userId: userId
        )
        try await habitCategory.save(on: req.db)

        // After saving, ensure the ID is assigned
        guard habitCategory.id != nil else {
            throw Abort(.internalServerError, reason: "Failed to get ID after saving category") // HTTP 500
        }

        // DTO for the response
        guard let categoryResponseDTO = CategoryResponseDTO(habitCategory) else {
            throw Abort(.internalServerError, reason: "Failed to create response DTO") // HTTP 500
        }
        
        return categoryResponseDTO
    }
    
    @Sendable func getAllCategoriesForUser(req: Request) async throws -> [CategoryResponseDTO] {
        
        // get the user id
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Missing or invalid userId parameter") // HTTP 400
        }
        
        // get all categories
        return try await Category.query(on: req.db)
            .filter(\.$user.$id, .equal, userId)
            .all()
            .compactMap(CategoryResponseDTO.init)
    }
    
    @Sendable func deleteCategory(req: Request) async throws -> CategoryResponseDTO {
        // get the user id
        guard let userId = req.parameters.get("userId", as: UUID.self),
              let categoryId = req.parameters.get("categoryId", as: UUID.self)
        else {
            throw Abort(.badRequest, reason: "Missing or invalid userId parameter") // HTTP 400
        }
        
        guard let category = try await Category.query(on: req.db)
            .filter(\.$user.$id, .equal, userId)
            .filter(\.$id, .equal, categoryId)
            .first() else {
                throw Abort(.notFound, reason: "Category not found for this user") // HTTP 404
            }
        
        try await category.delete(on: req.db)
        
        guard let categoryDTO = CategoryResponseDTO(category) else {
            throw Abort(.internalServerError, reason: "Failed to create response DTO") // HTTP 500
        }
        
        return categoryDTO
    }

}
