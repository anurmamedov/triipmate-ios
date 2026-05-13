//
//  AuthViewModel.swift
//  TriipMate
//
//  Owns the auth state machine that drives RootView routing.
//

import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {

    enum State: Equatable {
        case loading
        case signedOut
        case signedIn(TMUser)
    }

    @Published private(set) var state: State = .loading
    @Published var errorMessage: String?
    @Published var isWorking = false

    private let auth: AuthServicing
    private let users: UserServicing
    private var authHandle: AuthStateDidChangeListenerHandle?

    init(
        auth: AuthServicing = AuthService(),
        users: UserServicing = UserService()
    ) {
        self.auth = auth
        self.users = users
        observeAuthChanges()
    }

    deinit {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }

    private func observeAuthChanges() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firUser in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let firUser else {
                    self.state = .signedOut
                    return
                }
                await self.hydrateProfile(uid: firUser.uid, email: firUser.email ?? "")
            }
        }
    }

    private func hydrateProfile(uid: String, email: String) async {
        do {
            if let existing = try await users.fetch(uid: uid) {
                state = .signedIn(existing)
            } else {
                let fresh = TMUser.newProfile(uid: uid, email: email)
                try await users.create(fresh)
                state = .signedIn(fresh)
            }
        } catch {
            errorMessage = "Could not load profile: \(error.localizedDescription)"
            state = .signedOut
        }
    }

    func signUp(email: String, password: String) async {
        await perform {
            _ = try await self.auth.signUp(email: email, password: password)
        }
    }

    func signIn(email: String, password: String) async {
        await perform {
            _ = try await self.auth.signIn(email: email, password: password)
        }
    }

    func signOut() {
        do {
            try auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func perform(_ block: @escaping () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await block()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
