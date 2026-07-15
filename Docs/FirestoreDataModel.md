# TriipMate Firestore Data Model

This document defines the local Firestore schema for the marketplace features. The Swift model source is `TriipMate/Core/Models/MarketplaceModels.swift`.

## Collections

| Collection | Purpose |
|---|---|
| `users/{uid}` | One profile document for each Firebase Auth user. |
| `users/{uid}/vehicles/{vehicleId}` | Vehicles owned by one driver. |
| `users/{uid}/accountTools/settings` | Account tool preferences for Profile settings. |
| `users/{uid}/supportRequests/{supportRequestId}` | Support requests created by the user. |
| `rides/{rideId}` | Published or draft rides created by drivers. |
| `rideRequests/{requestId}` | Passenger requests to join a ride. |
| `trips/{tripId}` | Passenger trip records created from accepted requests. |
| `conversations/{conversationId}` | Driver/passenger chat metadata. |
| `conversations/{conversationId}/messages/{messageId}` | Messages inside one conversation. |

## Users

Already implemented by `UserProfile`.

Required fields:

- `firstName`
- `lastName`
- `email`
- `phone`
- `role`
- `profilePhotoPath`
- `ratingAverage` (optional until the first rating)
- `ratingCount`
- `completedTripCount`
- `totalSavingsCents`
- `isIdentityVerified`
- `isDriverVerified`
- `updatedAt`

Rating and trip/savings counters default to an unrated zero state. Later rating and completed-trip workflows are responsible for updating these persisted aggregate fields.

Document ID:

- Firebase Auth `uid`

## Vehicles

Already implemented by `SavedVehicle`.

Path:

- `users/{uid}/vehicles/{vehicleId}`

Required fields:

- `make`
- `model`
- `year`
- `powerType`
- `bodyType`

Document ID:

- Stable app-generated `vehicleId`

## Account Tools

Swift model:

- `AccountToolSettings`

Path:

- `users/{uid}/accountTools/settings`

Required maps:

- `identity`
- `payment`
- `alerts`
- `payout`
- `updatedAt`

Rules:

- Only the owner can read or update account tool settings.
- Sensitive production payment, bank, and identity data must not be stored directly. The current local model stores safe test summaries such as document last four digits, card last four digits, preferences, and setup status fields.

## Support Requests

Swift model:

- `SupportRequestTicket`

Path:

- `users/{uid}/supportRequests/{supportRequestId}`

Required fields:

- `topic`
- `message`
- `status`
- `createdAt`

Rules:

- Only the owner can create and read local support requests.
- Production support should later add admin/provider review workflows before support tickets are useful outside local testing.

## Rides

Swift model:

- `MarketplaceRide`

Path:

- `rides/{rideId}`

Required fields:

- `driverUid`
- `driverDisplayName`
- `driverProfilePhotoPath`
- `from`
- `to`
- `departureAt`
- `expectedArrivalAt`
- `estimatedDurationMinutes`
- `availableSeats`
- `totalSeats`
- `pricePerSeatCents`
- `vehicle`
- `status`
- `notes`
- `createdAt`
- `updatedAt`

Allowed statuses:

- `draft`
- `published`
- `active`
- `full`
- `completed`
- `cancelled`

Ownership:

- Only `driverUid` can create, edit, cancel, or delete the ride.

Search behavior:

- Passenger search should only show `published` or `active` rides with `availableSeats > 0`.
- Search should hide `draft`, `full`, `completed`, and `cancelled` rides.

## Ride Requests

Swift model:

- `JoinRideRequest`

Path:

- `rideRequests/{requestId}`

Required fields:

- `rideId`
- `passengerUid`
- `passengerDisplayName`
- `passengerProfilePhotoPath`
- `seatsRequested`
- `pickupNote`
- `dropoffNote`
- `luggageNote`
- `message`
- `pricePerSeatCents`
- `status`
- `createdAt`
- `updatedAt`
- `decidedAt`

Allowed statuses:

- `pending`
- `accepted`
- `declined`
- `cancelled`
- `expired`

Rules:

- One passenger should not have two active requests for the same ride.
- Accepting a request must reduce `rides/{rideId}.availableSeats`.
- A driver cannot accept more seats than remain available.

## Trips

Swift model:

- `PassengerTrip`

Path:

- `trips/{tripId}`

Required fields:

- `requestId`
- `rideId`
- `passengerUid`
- `driverUid`
- `seats`
- `status`
- `rideSnapshot`
- `createdAt`
- `updatedAt`

Allowed statuses:

- `pending`
- `accepted`
- `active`
- `completed`
- `declined`
- `cancelled`

Rules:

- A trip keeps a `rideSnapshot` so past trip history does not change when the original ride is edited later.

## Conversations

Swift model:

- `RideConversation`

Path:

- `conversations/{conversationId}`

Required fields:

- `rideId`
- `requestId`
- `participantUids`
- `driverUid`
- `passengerUid`
- `lastMessagePreview`
- `lastMessageAt`
- `unreadCountsByUid`
- `status`
- `createdAt`
- `updatedAt`

Allowed statuses:

- `active`
- `archived`
- `blocked`
- `reported`

Rules:

- Only users inside `participantUids` can read the conversation.
- A conversation should usually connect one driver and one passenger for one ride or request.

## Messages

Swift model:

- `RideMessage`

Path:

- `conversations/{conversationId}/messages/{messageId}`

Required fields:

- `conversationId`
- `senderUid`
- `body`
- `status`
- `readByUids`
- `createdAt`

Allowed statuses:

- `sent`
- `read`

Rules:

- Only conversation participants can create or read messages.
- `senderUid` must be one of the parent conversation participants.

## Timestamps

Local Swift models use `FirestoreTimestamp`.

Required timestamp fields should be set when the document is created and updated:

- `createdAt`
- `updatedAt`
- `departureAt`
- `expectedArrivalAt`
- `decidedAt`
- `lastMessageAt`

## Security Notes

Local emulator rules now enforce ownership for profile, vehicle, ride, ride-request, trip, conversation, message, and profile-photo writes. The remaining security hardening item is to replace authenticated collection scans with server-side filtered Firestore queries so reads can be fully limited to public rides or involved users before staging.

Run the disposable security checks with:

```bash
./scripts/test-security-rules.sh
```
