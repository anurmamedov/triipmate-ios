# TriipMate Development Plan

This plan reflects the active Xcode target as of July 2026. The project now uses one feature-based source tree, with shared models, services, session state, and design tokens under `Core`.

## Status Legend

- `[x]` Complete locally
- `[~]` Partially complete
- `[ ]` Not started

## 1. Clean Project Architecture `[x]`

- Chose one active `App` / `Core` / `Features` folder structure.
- Removed duplicate inactive Swift files and stale Xcode references.
- Separated models, Firebase services, app session state, design tokens, and feature views.
- Updated `README.md` to document the active source tree and local workflow.

**Done when:** the Xcode target contains one implementation of each screen and service, and every source file has a clear purpose.

## 2. Standardize Local Setup `[x]`

- Added `./scripts/start-emulators.sh` as the single emulator command.
- Automatically import and export local emulator data through `firebase-dataok/`.
- Check and document Firebase CLI, JDK 21, ports, configuration, and simulator setup.
- Added and verified a fresh-clone readiness workflow for teammates.

**Done when:** one documented command starts Auth, Firestore, Storage, and the Emulator UI without losing local data.

## 3. Stabilize Authentication `[x]`

- Kept real registration, login, logout, and email updates against the Auth emulator.
- Persisted the Firebase refresh token in Keychain and restore sessions when the app reopens.
- Added consistent name, email, phone, password, and confirmation validation with user-friendly errors.
- Replaced placeholder reset and verification screens with a real local Firebase password-reset flow.
- Added a disposable-user emulator test for duplicate email, invalid password, token refresh, email changes, reset, login, and cleanup.

**Done when:** the complete authentication lifecycle behaves predictably against the local Auth emulator.

## 4. Complete User Profiles `[~]`

- Persist personal information and profile photos.
- Save passenger/driver mode changes to Firestore.
- Replace hard-coded rating, trip, and savings values.
- Add loading, empty, retry, and offline states.

**Done when:** no visible profile value is hard-coded and all user data reloads correctly after logout and login.

## 5. Complete Vehicle Management `[~]`

- Keep Firestore-backed vehicle creation and editing.
- Add vehicle deletion with confirmation.
- Allow selection of a default vehicle.
- Prevent duplicate or invalid vehicles.
- Refresh Post Ride options immediately after changes.

**Done when:** drivers can add, edit, delete, and select vehicles reliably from Profile and Post Ride.

## 6. Define Firestore Data Models `[x]`

- Finalized schemas for rides, requests, trips, conversations, and messages.
- Added stable document IDs and Firestore timestamp model conventions.
- Defined ownership fields and allowed status values.
- Documented relationships between users, vehicles, rides, and requests in `Docs/FirestoreDataModel.md`.

**Done when:** every marketplace entity has one documented schema that can round-trip through the Firestore emulator.

## 7. Build Ride Publishing `[x]`

- Connected Post Ride to Firestore.
- Added validation for route, seats, and vehicle details.
- Supported saved vehicles and newly entered vehicles.
- Added an explicit choice before saving a new vehicle to the driver's profile.
- Prevented duplicate submissions with a publishing state.
- Added loading, success, and failure states.

**Done when:** publishing creates a real ride that survives an emulator restart.

## 8. Build Driver Ride Management `[x]`

- Loaded rides owned by the authenticated driver from Firestore.
- Supported viewing, editing, cancelling, and deleting eligible rides.
- Separated draft, active, full, completed, and cancelled rides with status filters.
- Preserved ride details in Firestore for completed and cancelled rides unless the driver explicitly deletes a ride.

**Done when:** drivers can manage the full lifecycle of their Firestore-backed rides.

## 9. Build Real Ride Search `[ ]`

- Replace sample rides with Firestore queries.
- Filter by route, date, seats, verification, and price.
- Hide expired, cancelled, full, or inappropriate results.
- Add loading, empty-results, retry, and pagination states.
- Decide whether route matching uses normalized city names or coordinates.

**Done when:** a ride published by one local user appears correctly in another user’s search results.

## 10. Implement Ride Requests `[~]`

- Let passengers request one or more seats.
- Prevent duplicate requests and overbooking.
- Save request details and status in Firestore.
- Keep the existing request-detail interface.
- Show current request status to passengers.

**Done when:** a passenger can submit a real request for a published ride.

## 11. Implement Driver Decisions `[~]`

- Load passenger requests for each owned ride.
- Support Accept and Decline actions.
- Update available seats transactionally after acceptance.
- Prevent accepting more passengers than available seats.
- Expose status changes to the passenger.

**Done when:** driver decisions update both accounts consistently without seat-count errors.

## 12. Build Passenger Trip Management `[~]`

- Show pending, accepted, declined, active, completed, and cancelled trips.
- Allow cancellation of eligible pending requests.
- Preserve trip history and ride snapshots.
- Replace all remaining sample trip data.

**Done when:** passengers see an accurate Firestore-backed history and current trip state.

## 13. Build Real-Time Messaging `[~]`

- Replace sample conversations and messages.
- Create chats only for involved passengers and drivers.
- Add real-time Firestore listeners.
- Add timestamps, unread counts, and read status.
- Decide message retention, blocking, and reporting behavior.

**Done when:** two local accounts can exchange messages and see updates without refreshing.

## 14. Security and Automated Testing `[ ]`

- Restrict profiles and vehicles to their owners.
- Restrict ride editing to the driver.
- Restrict requests and conversations to involved users.
- Restrict profile-photo paths to their owners.
- Add Firestore and Storage emulator rule tests.
- Add unit tests, UI tests, and CI builds for pull requests.
- Test accessibility, offline behavior, and multiple iPhone sizes.

**Done when:** unauthorized operations fail and core local workflows pass automatically.

## 15. Production Preparation `[ ]`

- Separate local, staging, and production configurations.
- Add production Firebase configuration securely.
- Ensure Release builds cannot connect to local emulators.
- Decide whether a separate API is needed for payments and privileged operations.
- Add analytics, crash reporting, privacy controls, and account deletion.
- Prepare App Store assets, permissions, policies, and release testing.

**Done when:** the app is ready for controlled staging distribution without exposing local configuration or test data.

## Recommended Next Work

Complete stage **9** next. Drivers can now manage Firestore-backed rides; passengers should be able to search real Firestore rides published by drivers.
