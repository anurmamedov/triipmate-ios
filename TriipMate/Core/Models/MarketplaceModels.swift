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
