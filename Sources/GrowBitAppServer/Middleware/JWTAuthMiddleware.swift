//
//  JWTAuthMiddleware.swift
//  GrowBitAppServer
//

import Vapor

struct JWTAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let payload = try await request.jwt.verify(as: AuthPayload.self)

        if let userIdString = request.parameters.get("userId"),
           let pathUserId = UUID(uuidString: userIdString),
           pathUserId != payload.userId {
            throw Abort(.forbidden, reason: "Access denied")
        }

        return try await next.respond(to: request)
    }
}
