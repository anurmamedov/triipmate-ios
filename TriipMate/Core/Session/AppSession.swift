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
    @Published var passengerRideRequests: [JoinRideRequest] = []
    @Published var passengerTrips: [PassengerTrip] = []
    @Published var driverRideRequests: [JoinRideRequest] = []
    @Published var conversations: [RideConversation] = []
    @Published var messagesByConversationId: [String: [RideMessage]] = [:]
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
    @Published var isRideRequestWorking = false
    @Published var isPassengerTripsLoading = false
    @Published var isDriverRequestsLoading = false
    @Published var isConversationsLoading = false
    @Published var isMessagesLoading = false
    @Published var isMessageSending = false

    private let authService = LocalFirebaseAuthService()
    private let sessionStore = AuthSessionStore()
    private let profileService = LocalFirestoreProfileService()
    private let storageService = LocalStorageProfilePhotoService()
    private let vehicleService = LocalFirestoreVehicleService()
    private let rideService = LocalFirestoreRideService()
    private let rideRequestService = LocalFirestoreRideRequestService()
    private let passengerTripService = LocalFirestorePassengerTripService()
    private let messagingService = LocalFirestoreMessagingService()

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
                countryCode: UserProfile.countryCode(fromPhone: values.phone),
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
        passengerRideRequests = []
        passengerTrips = []
        driverRideRequests = []
        conversations = []
        messagesByConversationId = [:]
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

    func updateProfile(firstName: String, lastName: String, email: String, phone: String, countryCode: String? = nil) async {
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
                phone: values.phone,
                countryCode: countryCode
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

        guard validateVehicle(vehicle) else {
            return false
        }

        if savedVehicles.contains(where: { $0.id != vehicle.id && $0.duplicateKey == vehicle.duplicateKey }) {
            authError = "This vehicle is already saved."
            return false
        }

        isVehicleWorking = true
        authError = nil
        defer { isVehicleWorking = false }

        do {
            var vehicleToSave = vehicle
            if savedVehicles.isEmpty {
                vehicleToSave = vehicle.settingDefault(true)
            }
            try await vehicleService.save(vehicleToSave, uid: authUser.uid, idToken: authUser.idToken)
            if let index = savedVehicles.firstIndex(where: { $0.id == vehicle.id }) {
                savedVehicles[index] = vehicleToSave
            } else {
                savedVehicles.append(vehicleToSave)
            }
            sortSavedVehicles()
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func setDefaultVehicle(_ vehicle: SavedVehicle) async -> Bool {
        guard let authUser else {
            authError = "Please log in before changing your default vehicle."
            return false
        }

        guard savedVehicles.contains(where: { $0.id == vehicle.id }) else {
            authError = "This vehicle is no longer available."
            return false
        }

        isVehicleWorking = true
        authError = nil
        defer { isVehicleWorking = false }

        do {
            let updatedVehicles = savedVehicles.map { $0.settingDefault($0.id == vehicle.id) }
            for updatedVehicle in updatedVehicles {
                if updatedVehicle != savedVehicles.first(where: { $0.id == updatedVehicle.id }) {
                    try await vehicleService.save(updatedVehicle, uid: authUser.uid, idToken: authUser.idToken)
                }
            }
            savedVehicles = updatedVehicles
            sortSavedVehicles()
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func deleteVehicle(_ vehicle: SavedVehicle) async -> Bool {
        guard let authUser else {
            authError = "Please log in before deleting a vehicle."
            return false
        }

        isVehicleWorking = true
        authError = nil
        defer { isVehicleWorking = false }

        do {
            try await vehicleService.delete(vehicleID: vehicle.id, uid: authUser.uid, idToken: authUser.idToken)
            savedVehicles.removeAll { $0.id == vehicle.id }

            if vehicle.isDefault, let replacement = savedVehicles.first {
                let defaultVehicle = replacement.settingDefault(true)
                try await vehicleService.save(defaultVehicle, uid: authUser.uid, idToken: authUser.idToken)
                if let index = savedVehicles.firstIndex(where: { $0.id == defaultVehicle.id }) {
                    savedVehicles[index] = defaultVehicle
                }
            }

            sortSavedVehicles()
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
                if savedVehicles.contains(where: { $0.id != vehicleToSave.id && $0.duplicateKey == vehicleToSave.duplicateKey }) {
                    throw LocalAuthError.invalidInput("This vehicle is already saved. Choose it from your saved vehicles.")
                }
                let vehicleToSave = savedVehicles.isEmpty ? vehicleToSave.settingDefault(true) : vehicleToSave
                try await vehicleService.save(vehicleToSave, uid: authUser.uid, idToken: authUser.idToken)
                if let index = savedVehicles.firstIndex(where: { $0.id == vehicleToSave.id }) {
                    savedVehicles[index] = vehicleToSave
                } else {
                    savedVehicles.append(vehicleToSave)
                }
                sortSavedVehicles()
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
            try await syncPassengerTrips(for: ride, idToken: authUser.idToken)
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
            let trips = try await passengerTripService.fetchRideTrips(rideId: ride.id, idToken: authUser.idToken)
            for trip in trips where trip.status != .cancelled {
                try await passengerTripService.save(trip.updated(status: .cancelled), idToken: authUser.idToken)
            }
            try await rideService.deleteRide(id: ride.id, idToken: authUser.idToken)
            driverRides.removeAll { $0.id == ride.id }
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func submitRideRequest(
        for ride: Ride,
        seatsRequested: Int,
        pickupNote: String,
        dropoffNote: String,
        luggageNote: String,
        message: String
    ) async -> Bool {
        guard let authUser, let userProfile else {
            authError = "Please log in before requesting a ride."
            return false
        }

        guard seatsRequested > 0, seatsRequested <= ride.seats else {
            authError = "Choose a valid number of seats for this ride."
            return false
        }

        let existingRequests: [JoinRideRequest]
        isRideRequestWorking = true
        authError = nil
        defer { isRideRequestWorking = false }

        do {
            existingRequests = try await rideRequestService.fetchPassengerRequests(uid: authUser.uid, idToken: authUser.idToken)
            if existingRequests.contains(where: { $0.rideId == ride.id && [.pending, .accepted].contains($0.status) }) {
                authError = "You already have an active request for this ride."
                passengerRideRequests = existingRequests
                return false
            }

            let now = FirestoreTimestamp(date: Date())
            let displayName = "\(userProfile.firstName) \(userProfile.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            let request = JoinRideRequest(
                id: UUID().uuidString.lowercased(),
                rideId: ride.id,
                passengerUid: authUser.uid,
                passengerDisplayName: displayName.isEmpty ? authUser.email : displayName,
                passengerProfilePhotoPath: userProfile.profilePhotoPath,
                seatsRequested: seatsRequested,
                pickupNote: pickupNote.trimmingCharacters(in: .whitespacesAndNewlines),
                dropoffNote: dropoffNote.trimmingCharacters(in: .whitespacesAndNewlines),
                luggageNote: luggageNote.trimmingCharacters(in: .whitespacesAndNewlines),
                message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                pricePerSeatCents: ride.price * 100,
                status: .pending,
                createdAt: now,
                updatedAt: now,
                decidedAt: nil
            )

            try await rideRequestService.save(request, idToken: authUser.idToken)
            passengerRideRequests = ([request] + existingRequests).sorted { $0.createdAt.date > $1.createdAt.date }
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func loadPassengerRideRequests() async {
        guard let authUser else {
            authError = "Please log in before loading your requests."
            return
        }

        isRideRequestWorking = true
        authError = nil
        defer { isRideRequestWorking = false }

        do {
            passengerRideRequests = try await rideRequestService.fetchPassengerRequests(uid: authUser.uid, idToken: authUser.idToken)
        } catch {
            authError = error.localizedDescription
        }
    }

    func loadPassengerTrips() async {
        guard let authUser else {
            authError = "Please log in before loading your trips."
            return
        }

        isPassengerTripsLoading = true
        authError = nil
        defer { isPassengerTripsLoading = false }

        do {
            async let requests = rideRequestService.fetchPassengerRequests(uid: authUser.uid, idToken: authUser.idToken)
            async let trips = passengerTripService.fetchPassengerTrips(uid: authUser.uid, idToken: authUser.idToken)
            passengerRideRequests = try await requests
            passengerTrips = try await trips
        } catch {
            authError = error.localizedDescription
        }
    }

    func cancelPassengerRideRequest(_ request: JoinRideRequest) async -> Bool {
        guard let authUser else {
            authError = "Please log in before cancelling a request."
            return false
        }

        guard request.passengerUid == authUser.uid else {
            authError = "You can only cancel your own requests."
            return false
        }

        guard request.status == .pending else {
            authError = "Only pending requests can be cancelled."
            return false
        }

        isRideRequestWorking = true
        authError = nil
        defer { isRideRequestWorking = false }

        do {
            let updatedRequest = request.updated(status: .cancelled)
            try await rideRequestService.save(updatedRequest, idToken: authUser.idToken)
            replacePassengerRequest(updatedRequest)
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func loadDriverRideRequests() async {
        guard let authUser else {
            authError = "Please log in before loading passenger requests."
            return
        }

        isDriverRequestsLoading = true
        authError = nil
        defer { isDriverRequestsLoading = false }

        do {
            if driverRides.isEmpty {
                driverRides = try await rideService.fetchDriverRides(uid: authUser.uid, idToken: authUser.idToken)
            }
            let rideIds = Set(driverRides.map(\.id))
            driverRideRequests = try await rideRequestService.fetchDriverRequests(rideIds: rideIds, idToken: authUser.idToken)
        } catch {
            authError = error.localizedDescription
        }
    }

    func acceptRideRequest(_ request: JoinRideRequest) async -> Bool {
        guard let authUser else {
            authError = "Please log in before accepting requests."
            return false
        }

        guard let ride = driverRides.first(where: { $0.id == request.rideId }) else {
            authError = "Could not find the ride for this request."
            return false
        }

        isRideRequestWorking = true
        authError = nil
        defer { isRideRequestWorking = false }

        do {
            let decision = try RideAcceptancePolicy.accept(
                request: request,
                ride: ride,
                driverUid: authUser.uid
            )

            try await rideService.save(decision.updatedRide, idToken: authUser.idToken)
            try await rideRequestService.save(decision.updatedRequest, idToken: authUser.idToken)
            try await passengerTripService.save(decision.passengerTrip, idToken: authUser.idToken)
            try await messagingService.saveConversation(decision.conversation, idToken: authUser.idToken)
            replaceDriverRide(decision.updatedRide)
            replaceDriverRequest(decision.updatedRequest)
            replaceSearchableRide(decision.updatedRide)
            conversations = (try? await messagingService.fetchConversations(uid: authUser.uid, idToken: authUser.idToken)) ?? conversations
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func declineRideRequest(_ request: JoinRideRequest) async -> Bool {
        guard let authUser else {
            authError = "Please log in before declining requests."
            return false
        }

        guard request.status == .pending else {
            authError = "This request has already been decided."
            return false
        }

        isRideRequestWorking = true
        authError = nil
        defer { isRideRequestWorking = false }

        do {
            let updatedRequest = request.updated(status: .declined)
            try await rideRequestService.save(updatedRequest, idToken: authUser.idToken)
            replaceDriverRequest(updatedRequest)
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func loadConversations() async {
        guard let authUser else {
            authError = "Please log in before loading messages."
            return
        }

        isConversationsLoading = true
        authError = nil
        defer { isConversationsLoading = false }

        do {
            conversations = try await messagingService.fetchConversations(uid: authUser.uid, idToken: authUser.idToken)
            try await createMissingAcceptedRideConversations(idToken: authUser.idToken)
            conversations = try await messagingService.fetchConversations(uid: authUser.uid, idToken: authUser.idToken)
        } catch {
            authError = error.localizedDescription
        }
    }

    func refreshConversationsSilently() async {
        guard let authUser else { return }
        conversations = (try? await messagingService.fetchConversations(uid: authUser.uid, idToken: authUser.idToken)) ?? conversations
    }

    func loadMessages(for conversation: RideConversation, markRead: Bool = true) async {
        guard let authUser else {
            authError = "Please log in before loading messages."
            return
        }

        guard conversation.participantUids.contains(authUser.uid) else {
            authError = "You can only open conversations you are part of."
            return
        }

        isMessagesLoading = true
        authError = nil
        defer { isMessagesLoading = false }

        do {
            messagesByConversationId[conversation.id] = try await messagingService.fetchMessages(
                conversationId: conversation.id,
                idToken: authUser.idToken
            )

            if markRead {
                let updatedConversation = try await messagingService.markRead(
                    conversation: conversation,
                    uid: authUser.uid,
                    idToken: authUser.idToken
                )
                replaceConversation(updatedConversation)
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    func refreshMessagesSilently(for conversation: RideConversation) async {
        guard let authUser else { return }
        guard conversation.participantUids.contains(authUser.uid) else { return }

        if let messages = try? await messagingService.fetchMessages(conversationId: conversation.id, idToken: authUser.idToken) {
            messagesByConversationId[conversation.id] = messages
        }

        if let freshConversation = (try? await messagingService.fetchConversations(uid: authUser.uid, idToken: authUser.idToken))?
            .first(where: { $0.id == conversation.id }) {
            replaceConversation(freshConversation)
        }
    }

    func sendMessage(_ body: String, in conversation: RideConversation) async -> Bool {
        guard let authUser else {
            authError = "Please log in before sending messages."
            return false
        }

        guard conversation.participantUids.contains(authUser.uid) else {
            authError = "You can only message people connected to your ride."
            return false
        }

        isMessageSending = true
        authError = nil
        defer { isMessageSending = false }

        do {
            let message = try await messagingService.sendMessage(
                body: body,
                conversation: conversation,
                senderUid: authUser.uid,
                idToken: authUser.idToken
            )
            messagesByConversationId[conversation.id, default: []].append(message)
            conversations = try await messagingService.fetchConversations(uid: authUser.uid, idToken: authUser.idToken)
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
        passengerRideRequests = (try? await rideRequestService.fetchPassengerRequests(uid: authUser.uid, idToken: authUser.idToken)) ?? []
        passengerTrips = (try? await passengerTripService.fetchPassengerTrips(uid: authUser.uid, idToken: authUser.idToken)) ?? []
        driverRideRequests = (try? await rideRequestService.fetchDriverRequests(rideIds: Set(driverRides.map(\.id)), idToken: authUser.idToken)) ?? []
        conversations = (try? await messagingService.fetchConversations(uid: authUser.uid, idToken: authUser.idToken)) ?? []
        isAuthenticated = true
    }

    private func replacePassengerRequest(_ request: JoinRideRequest) {
        if let index = passengerRideRequests.firstIndex(where: { $0.id == request.id }) {
            passengerRideRequests[index] = request
        } else {
            passengerRideRequests.append(request)
        }
        passengerRideRequests.sort { $0.createdAt.date > $1.createdAt.date }
    }

    private func syncPassengerTrips(for ride: MarketplaceRide, idToken: String) async throws {
        guard let tripStatus = ride.status.passengerTripStatus else { return }
        let trips = try await passengerTripService.fetchRideTrips(rideId: ride.id, idToken: idToken)
        for trip in trips where trip.status != tripStatus {
            try await passengerTripService.save(trip.updated(status: tripStatus), idToken: idToken)
        }
    }

    private func replaceDriverRide(_ ride: MarketplaceRide) {
        if let index = driverRides.firstIndex(where: { $0.id == ride.id }) {
            driverRides[index] = ride
        } else {
            driverRides.append(ride)
        }
        driverRides.sort { $0.departureAt.date < $1.departureAt.date }
    }

    private func replaceDriverRequest(_ request: JoinRideRequest) {
        if let index = driverRideRequests.firstIndex(where: { $0.id == request.id }) {
            driverRideRequests[index] = request
        } else {
            driverRideRequests.append(request)
        }
        driverRideRequests.sort { $0.createdAt.date > $1.createdAt.date }
    }

    private func replaceSearchableRide(_ ride: MarketplaceRide) {
        if let index = searchableRides.firstIndex(where: { $0.id == ride.id }) {
            searchableRides[index] = ride
        }
        searchableRides.removeAll { $0.availableSeats <= 0 || ![.published, .active].contains($0.status) }
    }

    private func replaceConversation(_ conversation: RideConversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.append(conversation)
        }
        conversations.sort {
            ($0.lastMessageAt?.date ?? $0.updatedAt.date) > ($1.lastMessageAt?.date ?? $1.updatedAt.date)
        }
    }

    private func createMissingAcceptedRideConversations(idToken: String) async throws {
        let existingRequestIds = Set(conversations.compactMap(\.requestId))
        let acceptedDriverRequests = driverRideRequests.filter { $0.status == .accepted && !existingRequestIds.contains($0.id) }

        for request in acceptedDriverRequests {
            guard let ride = driverRides.first(where: { $0.id == request.rideId }) else { continue }
            try await messagingService.saveConversation(
                RideConversation.acceptedRideConversation(request: request, ride: ride),
                idToken: idToken
            )
        }

        let acceptedPassengerRequests = passengerRideRequests.filter { $0.status == .accepted && !existingRequestIds.contains($0.id) }
        for request in acceptedPassengerRequests {
            guard let trip = passengerTrips.first(where: { $0.requestId == request.id }) else { continue }
            try await messagingService.saveConversation(
                RideConversation.acceptedRideConversation(request: request, trip: trip),
                idToken: idToken
            )
        }
    }

    private func validateVehicle(_ vehicle: SavedVehicle) -> Bool {
        let make = vehicle.make.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = vehicle.model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !make.isEmpty, !model.isEmpty, vehicle.year.count == 4 else {
            authError = "Enter the vehicle make, model, and four-digit year."
            return false
        }

        let calendarYear = Calendar.current.component(.year, from: Date())
        guard let year = Int(vehicle.year), (1980...(calendarYear + 1)).contains(year) else {
            authError = "Enter a vehicle year between 1980 and \(calendarYear + 1)."
            return false
        }

        return true
    }

    private func sortSavedVehicles() {
        savedVehicles.sort {
            if $0.isDefault != $1.isDefault {
                return $0.isDefault
            }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
}

private extension SavedVehicle {
    func settingDefault(_ value: Bool) -> SavedVehicle {
        SavedVehicle(
            id: id,
            make: make,
            model: model,
            year: year,
            powerType: powerType,
            bodyType: bodyType,
            isDefault: value
        )
    }
}

private extension RideStatus {
    var passengerTripStatus: TripStatus? {
        switch self {
        case .active:
            return .active
        case .completed:
            return .completed
        case .cancelled:
            return .cancelled
        case .draft, .published, .full:
            return nil
        }
    }
}
