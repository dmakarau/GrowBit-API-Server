//
//  AuthResponseDTO.swift
//  GrowBitAppServer
//

import Foundation
import Vapor

struct AuthResponseDTO: Content {
    let token: String
    let refreshToken: String
    let userId: UUID
}
