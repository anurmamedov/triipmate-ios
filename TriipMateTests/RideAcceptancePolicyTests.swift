import XCTest
@testable import TriipMate

final class RideAcceptancePolicyTests: XCTestCase {
    func testAcceptingRequestReducesOpenSeatsAndCreatesTrip() throws {
        let ride = makeRide(availableSeats: 2, totalSeats: 3)
        let request = makeRequest(seatsRequested: 1)
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let decision = try RideAcceptancePolicy.accept(
            request: request,
            ride: ride,
            driverUid: ride.driverUid,
            now: now
        )

        XCTAssertEqual(decision.updatedRide.availableSeats, 1)
        XCTAssertEqual(decision.updatedRide.status, .published)
        XCTAssertEqual(decision.updatedRequest.status, .accepted)
        XCTAssertEqual(decision.updatedRequest.decidedAt, FirestoreTimestamp(date: now))
        XCTAssertEqual(decision.passengerTrip.seats, request.seatsRequested)
        XCTAssertEqual(decision.passengerTrip.rideSnapshot.rideId, ride.id)
        XCTAssertEqual(decision.conversation.participantUids.sorted(), [ride.driverUid, request.passengerUid].sorted())
    }

    func testAcceptingLastSeatMarksRideFull() throws {
        let ride = makeRide(availableSeats: 1)
        let request = makeRequest(seatsRequested: 1)

        let decision = try RideAcceptancePolicy.accept(
            request: request,
            ride: ride,
            driverUid: ride.driverUid
        )

        XCTAssertEqual(decision.updatedRide.availableSeats, 0)
        XCTAssertEqual(decision.updatedRide.status, .full)
    }

    func testRejectsRequestWhenNotEnoughSeatsRemain() {
        let ride = makeRide(availableSeats: 1)
        let request = makeRequest(seatsRequested: 2)

        XCTAssertThrowsError(
            try RideAcceptancePolicy.accept(request: request, ride: ride, driverUid: ride.driverUid)
        ) { error in
            XCTAssertEqual(error as? RideAcceptanceError, .notEnoughSeats)
        }
    }

    func testSequentialAcceptancesCannotOverbookRide() throws {
        let ride = makeRide(availableSeats: 2)
        let firstRequest = makeRequest(id: "request-1", passengerUid: "passenger-1", seatsRequested: 2)
        let secondRequest = makeRequest(id: "request-2", passengerUid: "passenger-2", seatsRequested: 1)

        let firstDecision = try RideAcceptancePolicy.accept(
            request: firstRequest,
            ride: ride,
            driverUid: ride.driverUid
        )

        XCTAssertThrowsError(
            try RideAcceptancePolicy.accept(
                request: secondRequest,
                ride: firstDecision.updatedRide,
                driverUid: ride.driverUid
            )
        ) { error in
            XCTAssertEqual(error as? RideAcceptanceError, .notEnoughSeats)
        }
    }

    func testRejectsAlreadyDecidedRequest() {
        let ride = makeRide()
        let request = makeRequest(status: .accepted)

        XCTAssertThrowsError(
            try RideAcceptancePolicy.accept(request: request, ride: ride, driverUid: ride.driverUid)
        ) { error in
            XCTAssertEqual(error as? RideAcceptanceError, .requestAlreadyDecided)
        }
    }

    func testRejectsWrongDriver() {
        let ride = makeRide()
        let request = makeRequest()

        XCTAssertThrowsError(
            try RideAcceptancePolicy.accept(request: request, ride: ride, driverUid: "other-driver")
        ) { error in
            XCTAssertEqual(error as? RideAcceptanceError, .wrongDriver)
        }
    }
}

private func makeRide(
    availableSeats: Int = 3,
    totalSeats: Int = 3,
    status: RideStatus = .published
) -> MarketplaceRide {
    MarketplaceRide(
        id: "ride-1",
        driverUid: "driver-1",
        driverDisplayName: "Driver One",
        driverProfilePhotoPath: nil,
        from: RouteEndpoint(city: "Columbus", state: "OH", displayName: "Columbus, OH", normalizedName: "columbus oh"),
        to: RouteEndpoint(city: "Chicago", state: "IL", displayName: "Chicago, IL", normalizedName: "chicago il"),
        departureAt: FirestoreTimestamp(date: Date(timeIntervalSince1970: 1_800_100_000)),
        expectedArrivalAt: FirestoreTimestamp(date: Date(timeIntervalSince1970: 1_800_130_000)),
        estimatedDurationMinutes: 300,
        availableSeats: availableSeats,
        totalSeats: totalSeats,
        pricePerSeatCents: 4500,
        vehicle: VehicleSnapshot(vehicleId: "vehicle-1", make: "Honda", model: "Civic", year: "2020", powerType: "Fuel", bodyType: "Sedan"),
        status: status,
        notes: "Test ride",
        createdAt: FirestoreTimestamp(date: Date(timeIntervalSince1970: 1_800_000_000)),
        updatedAt: FirestoreTimestamp(date: Date(timeIntervalSince1970: 1_800_000_000))
    )
}

private func makeRequest(
    id: String = "request-1",
    passengerUid: String = "passenger-1",
    seatsRequested: Int = 1,
    status: RideRequestStatus = .pending
) -> JoinRideRequest {
    JoinRideRequest(
        id: id,
        rideId: "ride-1",
        passengerUid: passengerUid,
        passengerDisplayName: "Passenger One",
        passengerProfilePhotoPath: nil,
        seatsRequested: seatsRequested,
        pickupNote: "Pickup",
        dropoffNote: "Dropoff",
        luggageNote: "One bag",
        message: "Can I join?",
        pricePerSeatCents: 4500,
        status: status,
        createdAt: FirestoreTimestamp(date: Date(timeIntervalSince1970: 1_800_000_000)),
        updatedAt: FirestoreTimestamp(date: Date(timeIntervalSince1970: 1_800_000_000)),
        decidedAt: status == .pending ? nil : FirestoreTimestamp(date: Date(timeIntervalSince1970: 1_800_000_000))
    )
}
