//
//  User.swift
//  TriipMate
//
//  The user profile stored in Firestore at `/users/{uid}`.
//

import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case driver
    case passenger

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .driver:    return "Driver"
        case .passenger: return "Passenger"
        }
    }
}

struct TMUser: Codable, Identifiable, Equatable {
    let id: String          // Firebase Auth UID
    var email: String
    var name: String
    var bio: String
    var avatarURL: URL?
    var role: UserRole?
    var createdAt: Date
    var updatedAt: Date

    static func newProfile(uid: String, email: String) -> TMUser {
        let now = Date()
        return TMUser(
            id: uid,
            email: email,
            name: "",
            bio: "",
            avatarURL: nil,
            role: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}
