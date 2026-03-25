//
//  RefreshResponseDTO.swift
//  GrowBitAppServer
//

import Foundation
import Vapor

struct RefreshResponseDTO: Content {
    let token: String
}
