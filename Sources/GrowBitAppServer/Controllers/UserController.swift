//
//  UserController.swift
//  GrowBitAppServer
//
//  Created by Denis Makarau on 24.09.25.
//

import Foundation
import Vapor
import Fluent
import GrowBitSharedDTO

struct UserController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let api = routes.grouped("api")

        api.post("register", use: register)
        api.post("login", use: login)
        api.post("refresh", use: refresh)
        api.post("logout", use: logout)
    }

    @Sendable func login(req: Request) async throws -> AuthResponseDTO {
        let user = try req.content.decode(User.self)

        guard let existingUser = try await User.query(on: req.db)
            .filter(\.$username == user.username)
            .first() else {
                throw Abort(.badRequest, reason: "User not found")
            }

        let passwordMatch = try await req.password.async.verify(user.password, created: existingUser.password)
        if !passwordMatch {
            throw Abort(.unauthorized, reason: "Wrong password")
        }

        let userId = try existingUser.requireID()

        let authPayload = AuthPayload(
            expiration: .init(value: Date().addingTimeInterval(60 * 15)),
            userId: userId
        )
        let accessToken = try await req.jwt.sign(authPayload)

        let refreshToken = RefreshToken(
            userId: userId,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 7)
        )
        try await refreshToken.save(on: req.db)

        return AuthResponseDTO(
            token: accessToken,
            refreshToken: refreshToken.token,
            userId: userId
        )
    }

    @Sendable func refresh(req: Request) async throws -> RefreshResponseDTO {
        struct RefreshRequest: Content {
            let refreshToken: String
        }
        let body = try req.content.decode(RefreshRequest.self)

        guard let storedToken = try await RefreshToken.query(on: req.db)
            .filter(\.$token == body.refreshToken)
            .with(\.$user)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid refresh token")
        }

        guard storedToken.expiresAt > Date() else {
            try await storedToken.delete(on: req.db)
            throw Abort(.unauthorized, reason: "Refresh token has expired")
        }

        let authPayload = AuthPayload(
            expiration: .init(value: Date().addingTimeInterval(60 * 15)),
            userId: storedToken.$user.id
        )
        let accessToken = try await req.jwt.sign(authPayload)

        return RefreshResponseDTO(token: accessToken)
    }

    @Sendable func logout(req: Request) async throws -> LogoutResponseDTO {
        struct LogoutRequest: Content {
            let refreshToken: String
        }
        let body = try req.content.decode(LogoutRequest.self)

        if let storedToken = try await RefreshToken.query(on: req.db)
            .filter(\.$token == body.refreshToken)
            .first() {
            try await storedToken.delete(on: req.db)
        }

        return LogoutResponseDTO(message: "Logged out successfully")
    }

    @Sendable func register(req: Request) async throws -> RegisterResponseDTO {
        do {
            try User.validate(content: req)
        } catch let error as ValidationsError {
            throw Abort(.unprocessableEntity, reason: error.description)
        }

        let user = try req.content.decode(User.self)
        if let _ = try await User.query(on: req.db)
            .filter(\.$username == user.username)
            .first() {
            throw Abort(.conflict, reason: "Username is already taken")
        }

        user.password = try await req.password.async.hash(user.password)
        try await user.save(on: req.db)

        return RegisterResponseDTO(error: false)
    }
}
