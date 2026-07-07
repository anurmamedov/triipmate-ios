import SwiftUI

final class AppSession: ObservableObject {
    @Published var isAuthenticated = false
    @Published var activeRole: AppRole = .passenger
    @Published var authUser: AuthUser?
    @Published var userProfile: UserProfile?
    @Published var profileImageData: Data?
    @Published var savedVehicles: [SavedVehicle] = []
    @Published var authError: String?
    @Published var isAuthWorking = false
    @Published var isProfileWorking = false
    @Published var isProfilePhotoWorking = false
    @Published var isVehicleWorking = false
    @Published var isRidePublishing = false

    private let authService = LocalFirebaseAuthService()
    private let profileService = LocalFirestoreProfileService()
    private let storageService = LocalStorageProfilePhotoService()
    private let vehicleService = LocalFirestoreVehicleService()
    private let rideService = LocalFirestoreRideService()

    @MainActor
    func register(firstName: String, lastName: String, email: String, phone: String, password: String, confirmPassword: String) async {
        guard password == confirmPassword else {
            authError = "Passwords do not match."
            return
        }
        await performAuth {
            let authUser = try await authService.register(email: email, password: password)
            let profile = UserProfile(
                uid: authUser.uid,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone,
                role: activeRole,
                profilePhotoPath: nil
            )
            try await profileService.save(profile, idToken: authUser.idToken)
            return (authUser, profile)
        }
    }

    @MainActor
    func login(email: String, password: String) async {
        await performAuth {
            let authUser = try await authService.login(email: email, password: password)
            let profile = try await profileService.fetch(uid: authUser.uid, idToken: authUser.idToken)
            if let path = profile.profilePhotoPath {
                profileImageData = try? await storageService.download(path: path, idToken: authUser.idToken)
            }
            savedVehicles = (try? await vehicleService.fetchAll(uid: authUser.uid, idToken: authUser.idToken)) ?? []
            return (authUser, profile)
        }
    }

    @MainActor
    func logout() {
        authUser = nil
        userProfile = nil
        profileImageData = nil
        savedVehicles = []
        isAuthenticated = false
        authError = nil
    }

    @MainActor
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

    @MainActor
    func updateProfile(firstName: String, lastName: String, email: String, phone: String) async {
        guard let currentAuthUser = authUser, let currentProfile = userProfile else {
            authError = "Please log in before editing your profile."
            return
        }

        isProfileWorking = true
        authError = nil
        defer { isProfileWorking = false }

        do {
            let updatedAuthUser: AuthUser
            if email.caseInsensitiveCompare(currentAuthUser.email) == .orderedSame {
                updatedAuthUser = currentAuthUser
            } else {
                updatedAuthUser = try await authService.updateEmail(
                    idToken: currentAuthUser.idToken,
                    email: email
                )
            }

            let updatedProfile = UserProfile(
                uid: currentProfile.uid,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone,
                role: currentProfile.role,
                profilePhotoPath: currentProfile.profilePhotoPath
            )
            try await profileService.save(updatedProfile, idToken: updatedAuthUser.idToken)
            authUser = updatedAuthUser
            userProfile = updatedProfile
        } catch {
            authError = error.localizedDescription
        }
    }

    @MainActor
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

    @MainActor
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

    @MainActor
    private func performAuth(_ action: () async throws -> (AuthUser, UserProfile)) async {
        isAuthWorking = true
        authError = nil
        defer { isAuthWorking = false }

        do {
            let result = try await action()
            authUser = result.0
            userProfile = result.1
            if result.1.profilePhotoPath == nil {
                profileImageData = nil
            }
            activeRole = result.1.role
            isAuthenticated = true
        } catch {
            authError = error.localizedDescription
        }
    }
}
