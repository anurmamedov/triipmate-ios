//
//  AuthService.swift
//  TriipMate
//
//  Thin async wrapper around FirebaseAuth.
//

import Foundation
import FirebaseAuth

protocol AuthServicing {
    var currentUserID: String? { get }
    func signUp(email: String, password: String) async throws -> String
    func signIn(email: String, password: String) async throws -> String
    func signOut() throws
    func idToken(forceRefresh: Bool) async throws -> String
}

struct AuthService: AuthServicing {
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }

    func signUp(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func idToken(forceRefresh: Bool = false) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "No signed-in user"
            ])
        }
        return try await user.getIDToken(forcingRefresh: forceRefresh)
    }
}
