import Foundation

enum RideAcceptanceError: LocalizedError, Equatable {
    case requestAlreadyDecided
    case wrongDriver
    case notEnoughSeats

    var errorDescription: String? {
        switch self {
        case .requestAlreadyDecided:
            return "This request has already been decided."
        case .wrongDriver:
            return "You can only manage requests for your own rides."
        case .notEnoughSeats:
            return "This ride does not have enough open seats anymore."
        }
    }
}

struct RideAcceptanceDecision: Equatable {
    let updatedRide: MarketplaceRide
    let updatedRequest: JoinRideRequest
    let passengerTrip: PassengerTrip
    let conversation: RideConversation
}

enum RideAcceptancePolicy {
    static func accept(
        request: JoinRideRequest,
        ride: MarketplaceRide,
        driverUid: String,
        now: Date = Date()
    ) throws -> RideAcceptanceDecision {
        guard request.status == .pending else {
            throw RideAcceptanceError.requestAlreadyDecided
        }

        guard ride.driverUid == driverUid else {
            throw RideAcceptanceError.wrongDriver
        }

        guard ride.availableSeats >= request.seatsRequested else {
            throw RideAcceptanceError.notEnoughSeats
        }

        let remainingSeats = ride.availableSeats - request.seatsRequested
        let updatedRide = ride.updated(
            status: remainingSeats == 0 ? .full : ride.status,
            availableSeats: remainingSeats
        )
        let decidedAt = FirestoreTimestamp(date: now)
        let updatedRequest = request.updated(status: .accepted, decidedAt: decidedAt)
        let trip = PassengerTrip(
            id: request.id,
            requestId: request.id,
            rideId: ride.id,
            passengerUid: request.passengerUid,
            driverUid: ride.driverUid,
            seats: request.seatsRequested,
            status: .accepted,
            rideSnapshot: ride.snapshot,
            createdAt: decidedAt,
            updatedAt: updatedRequest.updatedAt
        )
        let conversation = RideConversation.acceptedRideConversation(
            request: updatedRequest,
            ride: ride
        )

        return RideAcceptanceDecision(
            updatedRide: updatedRide,
            updatedRequest: updatedRequest,
            passengerTrip: trip,
            conversation: conversation
        )
    }
}
