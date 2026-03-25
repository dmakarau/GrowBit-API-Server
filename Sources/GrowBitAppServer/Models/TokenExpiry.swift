//
//  TokenExpiry.swift
//  GrowBitAppServer
//

import Foundation

enum TokenExpiry {
    static let access: TimeInterval = 60 * 15           // 15 minutes
    static let refresh: TimeInterval = 60 * 60 * 24 * 7 // 7 days
}
