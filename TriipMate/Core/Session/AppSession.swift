import SwiftUI

@MainActor
final class AppSession: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isRestoringSession = true
    @Published var activeRole: AppRole = .passenger
    @Published var authUser: AuthUser?
    @Published var userProfile: UserProfile?
    @Published var profileImageData: Data?
    @Published var savedVehicles: [SavedVehicle] = []
    @Published var authError: String?
    @Published var authNotice: String?
    @Published var isAuthWorking = false
    @Published var isProfileWorking = false
    @Published var isProfilePhotoWorking = false
    @Published var isVehicleWorking = false
    @Published var isRidePublishing = false

    private let authService = LocalFirebaseAuthService()
    private let sessionStore = AuthSessionStore()
    private let profileService = LocalFirestoreProfileService()
    private let storageService = LocalStorageProfilePhotoService()
    private let vehicleService = LocalFirestoreVehicleService()
    private let rideService = LocalFirestoreRideService()

    init() {
        Task { await restoreSession() }
    }

    func register(firstName: String, lastName: String, email: String, phone: String, password: String, confirmPassword: String) async {
        let values: (firstName: String, lastName: String, email: String, phone: String)
        do {
            values = try AuthValidator.registration(
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone,
                password: password,
                confirmPassword: confirmPassword
            )
        } catch {
            authError = error.localizedDescription
            return
        }

        await performAuth {
            let authUser = try await authService.register(email: values.email, password: password)
            let profile = UserProfile(
                uid: authUser.uid,
                firstName: values.firstName,
                lastName: values.lastName,
                email: values.email,
                phone: values.phone,
                role: activeRole,
                profilePhotoPath: nil
            )
            try await profileService.save(profile, idToken: authUser.idToken)
            return (authUser, profile)
        }
    }

    func login(email: String, password: String) async {
        let normalizedEmail: String
        do {
            normalizedEmail = try AuthValidator.login(email: email, password: password)
        } catch {
            authError = error.localizedDescription
            return
        }

        await performAuth {
            let authUser = try await authService.login(email: normalizedEmail, password: password)
            let profile = try await profileService.fetch(uid: authUser.uid, idToken: authUser.idToken)
            return (authUser, profile)
        }
    }

    func logout() {
        try? sessionStore.clear()
        authUser = nil
        userProfile = nil
        profileImageData = nil
        savedVehicles = []
        isAuthenticated = false
        authError = nil
        authNotice = nil
    }

    func sendPasswordReset(email: String) async -> Bool {
        isAuthWorking = true
        authError = nil
        authNotice = nil
        defer { isAuthWorking = false }

        do {
            let email = try AuthValidator.normalizedEmail(email)
            try await authService.sendPasswordReset(email: email)
            authNotice = "Reset link created. Open the Firebase Emulator UI to complete the reset."
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func clearAuthFeedback() {
        authError = nil
        authNotice = nil
    }

    func updateProfilePhoto(_ imageData: Data) async {
        guard let authUser, let userProfile else {
            authError = "Please log in before adding a profile photo."
            return
        }

        isProfilePhotoWorking = true
        authError = nil
        defer { isProfilePhotoWorking = false }

        do {
            let path = "profilePhotos/\(authUser.uid).jpg"
            try await storageService.upload(imageData: imageData, path: path, idToken: authUser.idToken)
            let updatedProfile = UserProfile(
                uid: userProfile.uid,
                firstName: userProfile.firstName,
                lastName: userProfile.lastName,
                email: userProfile.email,
                phone: userProfile.phone,
                role: userProfile.role,
                profilePhotoPath: path
            )
            try await profileService.save(updatedProfile, idToken: authUser.idToken)
            self.userProfile = updatedProfile
            self.profileImageData = imageData
        } catch {
            authError = error.localizedDescription
        }
    }

    func updateProfile(firstName: String, lastName: String, email: String, phone: String) async {
        guard let currentAuthUser = authUser, let currentProfile = userProfile else {
            authError = "Please log in before editing your profile."
            return
        }

        isProfileWorking = true
        authError = nil
        defer { isProfileWorking = false }

        do {
            let values = try AuthValidator.profile(
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone
            )
            let updatedAuthUser: AuthUser
            if values.email.caseInsensitiveCompare(currentAuthUser.email) == .orderedSame {
                updatedAuthUser = currentAuthUser
            } else {
                updatedAuthUser = try await authService.updateEmail(
                    idToken: currentAuthUser.idToken,
                    email: values.email
                )
            }

            let updatedProfile = UserProfile(
                uid: currentProfile.uid,
                firstName: values.firstName,
                lastName: values.lastName,
                email: values.email,
                phone: values.phone,
                role: currentProfile.role,
                profilePhotoPath: currentProfile.profilePhotoPath
            )
            try await profileService.save(updatedProfile, idToken: updatedAuthUser.idToken)
            try sessionStore.save(refreshToken: updatedAuthUser.refreshToken)
            authUser = updatedAuthUser
            userProfile = updatedProfile
        } catch {
            authError = error.localizedDescription
        }
    }

    func saveVehicle(_ vehicle: SavedVehicle) async -> Bool {
        guard let authUser else {
            authError = "Please log in before saving a vehicle."
            return false
        }

        isVehicleWorking = true
        authError = nil
        defer { isVehicleWorking = false }

        do {
            try await vehicleService.save(vehicle, uid: authUser.uid, idToken: authUser.idToken)
            if let index = savedVehicles.firstIndex(where: { $0.id == vehicle.id }) {
                savedVehicles[index] = vehicle
            } else {
                savedVehicles.append(vehicle)
            }
            savedVehicles.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func publishRide(_ ride: MarketplaceRide, vehicleToSave: SavedVehicle?) async -> Bool {
        guard let authUser else {
            authError = "Please log in before publishing a ride."
            return false
        }

        isRidePublishing = true
        authError = nil
        defer { isRidePublishing = false }

        do {
            if let vehicleToSave {
                try await vehicleService.save(vehicleToSave, uid: authUser.uid, idToken: authUser.idToken)
                if let index = savedVehicles.firstIndex(where: { $0.id == vehicleToSave.id }) {
                    savedVehicles[index] = vehicleToSave
                } else {
                    savedVehicles.append(vehicleToSave)
                }
                savedVehicles.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            }

            try await rideService.save(ride, idToken: authUser.idToken)
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    private func performAuth(_ action: () async throws -> (AuthUser, UserProfile)) async {
        isAuthWorking = true
        authError = nil
        authNotice = nil
        defer { isAuthWorking = false }

        do {
            let result = try await action()
            try sessionStore.save(refreshToken: result.0.refreshToken)
            await applyAuthenticatedUser(result.0, profile: result.1)
        } catch {
            authError = error.localizedDescription
        }
    }

    private func restoreSession() async {
        defer { isRestoringSession = false }

        do {
            guard let refreshToken = try sessionStore.loadRefreshToken() else {
                return
            }
            let authUser = try await authService.restore(refreshToken: refreshToken)
            let profile = try await profileService.fetch(uid: authUser.uid, idToken: authUser.idToken)
            try sessionStore.save(refreshToken: authUser.refreshToken)
            await applyAuthenticatedUser(authUser, profile: profile)
        } catch {
            if shouldDiscardSavedSession(after: error) {
                try? sessionStore.clear()
                authError = "Your saved login has expired. Please log in again."
            } else {
                authError = "Could not restore your login. Make sure the local Firebase server is running."
            }
        }
    }

    private func shouldDiscardSavedSession(after error: Error) -> Bool {
        guard let authError = error as? LocalAuthError else {
            return false
        }
        switch authError {
        case .server, .profileNotFound:
            return true
        case .invalidResponse, .invalidInput:
            return false
        }
    }

    private func applyAuthenticatedUser(_ authUser: AuthUser, profile: UserProfile) async {
        self.authUser = authUser
        userProfile = profile
        activeRole = profile.role
        profileImageData = nil
        if let path = profile.profilePhotoPath {
            profileImageData = try? await storageService.download(path: path, idToken: authUser.idToken)
        }
        savedVehicles = (try? await vehicleService.fetchAll(uid: authUser.uid, idToken: authUser.idToken)) ?? []
        isAuthenticated = true
    }
}
