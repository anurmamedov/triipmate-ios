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
    @Published var driverRides: [MarketplaceRide] = []
    @Published var searchableRides: [MarketplaceRide] = []
    @Published var authError: String?
    @Published var authNotice: String?
    @Published var isAuthWorking = false
    @Published var isProfileWorking = false
    @Published var isProfilePhotoWorking = false
    @Published var isProfileLoading = false
    @Published var isRoleUpdating = false
    @Published var profileError: String?
    @Published var isVehicleWorking = false
    @Published var isRidePublishing = false
    @Published var isDriverRidesLoading = false
    @Published var isDriverRideUpdating = false
    @Published var isRideSearchLoading = false

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
        driverRides = []
        searchableRides = []
        isAuthenticated = false
        authError = nil
        authNotice = nil
        profileError = nil
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
            profileError = "Please log in before adding a profile photo."
            return
        }

        isProfilePhotoWorking = true
        profileError = nil
        defer { isProfilePhotoWorking = false }

        do {
            let path = "profilePhotos/\(authUser.uid).jpg"
            try await storageService.upload(imageData: imageData, path: path, idToken: authUser.idToken)
            let updatedProfile = userProfile.updated(
                profilePhotoPath: path,
                replacesProfilePhotoPath: true
            )
            try await profileService.save(updatedProfile, idToken: authUser.idToken)
            self.userProfile = updatedProfile
            self.profileImageData = imageData
        } catch {
            profileError = error.localizedDescription
        }
    }

    func updateProfile(firstName: String, lastName: String, email: String, phone: String) async {
        guard let currentAuthUser = authUser, let currentProfile = userProfile else {
            profileError = "Please log in before editing your profile."
            return
        }

        isProfileWorking = true
        profileError = nil
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

            let updatedProfile = currentProfile.updated(
                firstName: values.firstName,
                lastName: values.lastName,
                email: values.email,
                phone: values.phone
            )
            try await profileService.save(updatedProfile, idToken: updatedAuthUser.idToken)
            try sessionStore.save(refreshToken: updatedAuthUser.refreshToken)
            authUser = updatedAuthUser
            userProfile = updatedProfile
        } catch {
            profileError = error.localizedDescription
        }
    }

    func updateRole(_ role: AppRole) async {
        guard role != activeRole else { return }
        guard let authUser, let currentProfile = userProfile else {
            profileError = "Please log in before changing travel mode."
            return
        }

        isRoleUpdating = true
        profileError = nil
        defer { isRoleUpdating = false }

        do {
            let updatedProfile = currentProfile.updated(role: role)
            try await profileService.save(updatedProfile, idToken: authUser.idToken)
            userProfile = updatedProfile
            activeRole = role
        } catch {
            profileError = error.localizedDescription
        }
    }

    func refreshProfile() async {
        guard let authUser else {
            profileError = "Please log in before loading your profile."
            return
        }

        isProfileLoading = true
        profileError = nil
        defer { isProfileLoading = false }

        do {
            let profile = try await profileService.fetch(uid: authUser.uid, idToken: authUser.idToken)
            userProfile = profile
            activeRole = profile.role
            profileImageData = nil
            if let path = profile.profilePhotoPath {
                do {
                    profileImageData = try await storageService.download(path: path, idToken: authUser.idToken)
                } catch {
                    profileError = "Your profile loaded, but the photo is temporarily unavailable."
                }
            }
        } catch {
            profileError = error.localizedDescription
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
            driverRides.append(ride)
            driverRides.sort { $0.departureAt.date < $1.departureAt.date }
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func loadDriverRides() async {
        guard let authUser else {
            authError = "Please log in before loading your rides."
            return
        }

        isDriverRidesLoading = true
        authError = nil
        defer { isDriverRidesLoading = false }

        do {
            driverRides = try await rideService.fetchDriverRides(uid: authUser.uid, idToken: authUser.idToken)
        } catch {
            authError = error.localizedDescription
        }
    }

    func loadSearchableRides() async {
        guard let authUser else {
            authError = "Please log in before searching rides."
            return
        }

        isRideSearchLoading = true
        authError = nil
        defer { isRideSearchLoading = false }

        do {
            searchableRides = try await rideService.fetchSearchableRides(idToken: authUser.idToken)
        } catch {
            authError = error.localizedDescription
        }
    }

    func updateDriverRide(_ ride: MarketplaceRide) async -> Bool {
        guard let authUser else {
            authError = "Please log in before updating your ride."
            return false
        }

        guard ride.driverUid == authUser.uid else {
            authError = "You can only update rides that you published."
            return false
        }

        isDriverRideUpdating = true
        authError = nil
        defer { isDriverRideUpdating = false }

        do {
            try await rideService.save(ride, idToken: authUser.idToken)
            replaceDriverRide(ride)
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func cancelDriverRide(_ ride: MarketplaceRide) async -> Bool {
        let cancelledRide = ride.updated(status: .cancelled)
        return await updateDriverRide(cancelledRide)
    }

    func deleteDriverRide(_ ride: MarketplaceRide) async -> Bool {
        guard let authUser else {
            authError = "Please log in before deleting your ride."
            return false
        }

        guard ride.driverUid == authUser.uid else {
            authError = "You can only delete rides that you published."
            return false
        }

        isDriverRideUpdating = true
        authError = nil
        defer { isDriverRideUpdating = false }

        do {
            try await rideService.deleteRide(id: ride.id, idToken: authUser.idToken)
            driverRides.removeAll { $0.id == ride.id }
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
        profileError = nil
        activeRole = profile.role
        profileImageData = nil
        if let path = profile.profilePhotoPath {
            do {
                profileImageData = try await storageService.download(path: path, idToken: authUser.idToken)
            } catch {
                profileError = "Your profile loaded, but the photo is temporarily unavailable."
            }
        }
        savedVehicles = (try? await vehicleService.fetchAll(uid: authUser.uid, idToken: authUser.idToken)) ?? []
        driverRides = (try? await rideService.fetchDriverRides(uid: authUser.uid, idToken: authUser.idToken)) ?? []
        isAuthenticated = true
    }

    private func replaceDriverRide(_ ride: MarketplaceRide) {
        if let index = driverRides.firstIndex(where: { $0.id == ride.id }) {
            driverRides[index] = ride
        } else {
            driverRides.append(ride)
        }
        driverRides.sort { $0.departureAt.date < $1.departureAt.date }
    }
}

extension MarketplaceRide {
    func updated(
        status: RideStatus? = nil,
        availableSeats: Int? = nil,
        totalSeats: Int? = nil,
        pricePerSeatCents: Int? = nil,
        notes: String? = nil
    ) -> MarketplaceRide {
        MarketplaceRide(
            id: id,
            driverUid: driverUid,
            driverDisplayName: driverDisplayName,
            driverProfilePhotoPath: driverProfilePhotoPath,
            from: from,
            to: to,
            departureAt: departureAt,
            expectedArrivalAt: expectedArrivalAt,
            estimatedDurationMinutes: estimatedDurationMinutes,
            availableSeats: availableSeats ?? self.availableSeats,
            totalSeats: totalSeats ?? self.totalSeats,
            pricePerSeatCents: pricePerSeatCents ?? self.pricePerSeatCents,
            vehicle: vehicle,
            status: status ?? self.status,
            notes: notes ?? self.notes,
            createdAt: createdAt,
            updatedAt: FirestoreTimestamp(date: Date())
        )
    }
}
