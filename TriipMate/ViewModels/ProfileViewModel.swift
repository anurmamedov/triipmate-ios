//
//  ProfileViewModel.swift
//  TriipMate
//

import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: TMUser
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let users: UserServicing

    init(user: TMUser, users: UserServicing = UserService()) {
        self.user = user
        self.users = users
    }

    func setRole(_ role: UserRole) async {
        user.role = role
        await save()
    }

    func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await users.update(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
