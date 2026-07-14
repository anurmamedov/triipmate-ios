import Foundation

enum FirestoreCollection {
    static let users = "users"
    static let vehicles = "vehicles"
    static let rides = "rides"
    static let rideRequests = "rideRequests"
    static let trips = "trips"
    static let conversations = "conversations"
    static let messages = "messages"

    static func userPath(uid: String) -> String {
        "\(users)/\(uid)"
    }

    static func userVehiclesPath(uid: String) -> String {
        "\(userPath(uid: uid))/\(vehicles)"
    }

    static func ridePath(id: String) -> String {
        "\(rides)/\(id)"
    }

    static func rideRequestPath(id: String) -> String {
        "\(rideRequests)/\(id)"
    }

    static func tripPath(id: String) -> String {
        "\(trips)/\(id)"
    }

    static func conversationPath(id: String) -> String {
        "\(conversations)/\(id)"
    }

    static func conversationMessagesPath(conversationId: String) -> String {
        "\(conversationPath(id: conversationId))/\(messages)"
    }
}

struct FirestoreTimestamp: Codable, Hashable {
    let seconds: Int64
    let nanoseconds: Int

    init(date: Date) {
        seconds = Int64(date.timeIntervalSince1970)
        nanoseconds = 0
    }

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(nanoseconds) / 1_000_000_000)
    }
}

enum RideStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case published
    case active
    case full
    case completed
    case cancelled

    var id: Self { self }
}

enum RideRequestStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case accepted
    case declined
    case cancelled
    case expired

    var id: Self { self }
}

enum TripStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case accepted
    case active
    case completed
    case declined
    case cancelled

    var id: Self { self }
}

enum ConversationStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case archived
    case blocked
    case reported

    var id: Self { self }
}

enum MessageStatus: String, Codable, CaseIterable, Identifiable {
    case sent
    case read

    var id: Self { self }
}

struct RouteEndpoint: Codable, Hashable {
    let city: String
    let state: String
    let displayName: String
    let normalizedName: String
}

struct VehicleSnapshot: Codable, Hashable {
    let vehicleId: String?
    let make: String
    let model: String
    let year: String
    let powerType: String
    let bodyType: String
}

struct RideSnapshot: Codable, Hashable {
    let rideId: String
    let driverUid: String
    let driverDisplayName: String
    let from: RouteEndpoint
    let to: RouteEndpoint
    let departureAt: FirestoreTimestamp
    let expectedArrivalAt: FirestoreTimestamp?
    let pricePerSeatCents: Int
    let vehicle: VehicleSnapshot
}

struct MarketplaceRide: Identifiable, Codable, Hashable {
    let id: String
    let driverUid: String
    let driverDisplayName: String
    let driverProfilePhotoPath: String?
    let from: RouteEndpoint
    let to: RouteEndpoint
    let departureAt: FirestoreTimestamp
    let expectedArrivalAt: FirestoreTimestamp?
    let estimatedDurationMinutes: Int
    let availableSeats: Int
    let totalSeats: Int
    let pricePerSeatCents: Int
    let vehicle: VehicleSnapshot
    let status: RideStatus
    let notes: String
    let createdAt: FirestoreTimestamp
    let updatedAt: FirestoreTimestamp
}

struct JoinRideRequest: Identifiable, Codable, Hashable {
    let id: String
    let rideId: String
    let passengerUid: String
    let passengerDisplayName: String
    let passengerProfilePhotoPath: String?
    let seatsRequested: Int
    let pickupNote: String
    let dropoffNote: String
    let luggageNote: String
    let message: String
    let pricePerSeatCents: Int
    let status: RideRequestStatus
    let createdAt: FirestoreTimestamp
    let updatedAt: FirestoreTimestamp
    let decidedAt: FirestoreTimestamp?
}

struct PassengerTrip: Identifiable, Codable, Hashable {
    let id: String
    let requestId: String
    let rideId: String
    let passengerUid: String
    let driverUid: String
    let seats: Int
    let status: TripStatus
    let rideSnapshot: RideSnapshot
    let createdAt: FirestoreTimestamp
    let updatedAt: FirestoreTimestamp
}

struct RideConversation: Identifiable, Codable, Hashable {
    let id: String
    let rideId: String?
    let requestId: String?
    let participantUids: [String]
    let driverUid: String
    let passengerUid: String
    let driverDisplayName: String
    let passengerDisplayName: String
    let routeTitle: String
    let lastMessagePreview: String?
    let lastMessageAt: FirestoreTimestamp?
    let unreadCountsByUid: [String: Int]
    let status: ConversationStatus
    let createdAt: FirestoreTimestamp
    let updatedAt: FirestoreTimestamp
}

struct RideMessage: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let senderUid: String
    let body: String
    let status: MessageStatus
    let readByUids: [String]
    let createdAt: FirestoreTimestamp
}

extension MarketplaceRide {
    var snapshot: RideSnapshot {
        RideSnapshot(
            rideId: id,
            driverUid: driverUid,
            driverDisplayName: driverDisplayName,
            from: from,
            to: to,
            departureAt: departureAt,
            expectedArrivalAt: expectedArrivalAt,
            pricePerSeatCents: pricePerSeatCents,
            vehicle: vehicle
        )
    }

    func updated(
        status: RideStatus? = nil,
        availableSeats: Int? = nil,
        totalSeats: Int? = nil,
        pricePerSeatCents: Int? = nil,
        notes: String? = nil,
        updatedAt: FirestoreTimestamp = FirestoreTimestamp(date: Date())
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
            updatedAt: updatedAt
        )
    }
}

extension JoinRideRequest {
    func updated(
        status: RideRequestStatus,
        decidedAt: FirestoreTimestamp = FirestoreTimestamp(date: Date())
    ) -> JoinRideRequest {
        JoinRideRequest(
            id: id,
            rideId: rideId,
            passengerUid: passengerUid,
            passengerDisplayName: passengerDisplayName,
            passengerProfilePhotoPath: passengerProfilePhotoPath,
            seatsRequested: seatsRequested,
            pickupNote: pickupNote,
            dropoffNote: dropoffNote,
            luggageNote: luggageNote,
            message: message,
            pricePerSeatCents: pricePerSeatCents,
            status: status,
            createdAt: createdAt,
            updatedAt: decidedAt,
            decidedAt: decidedAt
        )
    }
}

extension PassengerTrip {
    func updated(status: TripStatus) -> PassengerTrip {
        PassengerTrip(
            id: id,
            requestId: requestId,
            rideId: rideId,
            passengerUid: passengerUid,
            driverUid: driverUid,
            seats: seats,
            status: status,
            rideSnapshot: rideSnapshot,
            createdAt: createdAt,
            updatedAt: FirestoreTimestamp(date: Date())
        )
    }
}

extension RideConversation {
    static func acceptedRideConversation(request: JoinRideRequest, ride: MarketplaceRide) -> RideConversation {
        let now = FirestoreTimestamp(date: Date())
        let participantUids = [ride.driverUid, request.passengerUid].uniqued()
        return RideConversation(
            id: "\(ride.id)_\(request.id)",
            rideId: ride.id,
            requestId: request.id,
            participantUids: participantUids,
            driverUid: ride.driverUid,
            passengerUid: request.passengerUid,
            driverDisplayName: ride.driverDisplayName,
            passengerDisplayName: request.passengerDisplayName,
            routeTitle: "\(ride.from.displayName) -> \(ride.to.displayName)",
            lastMessagePreview: "Ride request accepted. You can chat here.",
            lastMessageAt: now,
            unreadCountsByUid: Self.unreadCounts(driverUid: ride.driverUid, passengerUid: request.passengerUid),
            status: .active,
            createdAt: now,
            updatedAt: now
        )
    }

    static func acceptedRideConversation(request: JoinRideRequest, trip: PassengerTrip) -> RideConversation {
        let now = FirestoreTimestamp(date: Date())
        let participantUids = [trip.driverUid, trip.passengerUid].uniqued()
        return RideConversation(
            id: "\(trip.rideId)_\(request.id)",
            rideId: trip.rideId,
            requestId: request.id,
            participantUids: participantUids,
            driverUid: trip.driverUid,
            passengerUid: trip.passengerUid,
            driverDisplayName: trip.rideSnapshot.driverDisplayName,
            passengerDisplayName: request.passengerDisplayName,
            routeTitle: "\(trip.rideSnapshot.from.displayName) -> \(trip.rideSnapshot.to.displayName)",
            lastMessagePreview: "Ride request accepted. You can chat here.",
            lastMessageAt: now,
            unreadCountsByUid: Self.unreadCounts(driverUid: trip.driverUid, passengerUid: trip.passengerUid),
            status: .active,
            createdAt: now,
            updatedAt: now
        )
    }

    private static func unreadCounts(driverUid: String, passengerUid: String) -> [String: Int] {
        guard driverUid != passengerUid else {
            return [driverUid: 0]
        }
        return [
            driverUid: 0,
            passengerUid: 1
        ]
    }

    func updated(
        lastMessagePreview: String? = nil,
        lastMessageAt: FirestoreTimestamp? = nil,
        unreadCountsByUid: [String: Int]? = nil,
        status: ConversationStatus? = nil
    ) -> RideConversation {
        RideConversation(
            id: id,
            rideId: rideId,
            requestId: requestId,
            participantUids: participantUids,
            driverUid: driverUid,
            passengerUid: passengerUid,
            driverDisplayName: driverDisplayName,
            passengerDisplayName: passengerDisplayName,
            routeTitle: routeTitle,
            lastMessagePreview: lastMessagePreview ?? self.lastMessagePreview,
            lastMessageAt: lastMessageAt ?? self.lastMessageAt,
            unreadCountsByUid: unreadCountsByUid ?? self.unreadCountsByUid,
            status: status ?? self.status,
            createdAt: createdAt,
            updatedAt: FirestoreTimestamp(date: Date())
        )
    }

    func otherParticipantName(for uid: String) -> String {
        uid == driverUid ? passengerDisplayName : driverDisplayName
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
