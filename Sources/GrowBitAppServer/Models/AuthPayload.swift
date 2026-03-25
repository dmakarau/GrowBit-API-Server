//
//  AuthPayload.swift
//  GrowBitAppServer
//
//  Created by Denis Makarau on 25.09.25.
//

import Foundation
import JWT

struct AuthPayload: JWTPayload {

    typealias Payload = AuthPayload

    enum CodingKeys: String, CodingKey {
        case expiration = "exp"
        case userId = "uid"
        case tokenId = "jti"
    }

    var expiration: ExpirationClaim
    var userId: UUID
    var tokenId: UUID

    init(expiration: ExpirationClaim, userId: UUID) {
        self.expiration = expiration
        self.userId = userId
        self.tokenId = UUID()
    }

    func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
