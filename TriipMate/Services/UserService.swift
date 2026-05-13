//
//  UserService.swift
//  TriipMate
//
//  Firestore read/write for the user profile document.
//

import Foundation
import FirebaseFirestore

protocol UserServicing {
    func fetch(uid: String) async throws -> TMUser?
    func create(_ user: TMUser) async throws
    func update(_ user: TMUser) async throws
}

struct UserService: UserServicing {
    private var collection: CollectionReference {
        Firestore.firestore().collection("users")
    }

    func fetch(uid: String) async throws -> TMUser? {
        let snapshot = try await collection.document(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: TMUser.self)
    }

    func create(_ user: TMUser) async throws {
        try collection.document(user.id).setData(from: user, merge: false)
    }

    func update(_ user: TMUser) async throws {
        var updated = user
        updated.updatedAt = Date()
        try collection.document(user.id).setData(from: updated, merge: true)
    }
}
