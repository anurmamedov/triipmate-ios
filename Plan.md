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

## 4. Complete User Profiles `[x]`

- Persist personal information and profile photos through Firestore and Storage.
- Save passenger/driver mode changes to Firestore before updating the app mode.
- Load rating, completed-trip, savings, and verification values from profile data instead of samples.
- Store the user's country selection and use it for profile currency display.
- Connected passenger profile tools to real Saved trips, Ride history, and Travel preferences screens.
- Added loading, empty, retry, cached-profile, and offline/error states.
- Added a disposable-user emulator test for profile fields, role changes, photos, access rules, and cleanup.

**Done when:** no visible profile value is hard-coded and all user data reloads correctly after logout and login.

## 5. Complete Vehicle Management `[x]`

- Kept Firestore-backed vehicle creation and editing.
- Added vehicle deletion with confirmation.
- Added default vehicle selection and default-first sorting.
- Added duplicate and year validation for saved vehicles.
- Updated Post Ride to prefer the default vehicle and prevent saving duplicate vehicles.

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
- Added route-aware CAD/USD display for posted ride pricing.
- Prevented duplicate submissions with a publishing state.
- Added loading, success, and failure states.

**Done when:** publishing creates a real ride that survives an emulator restart.

## 8. Build Driver Ride Management `[x]`

- Loaded rides owned by the authenticated driver from Firestore.
- Supported viewing, editing, cancelling, and deleting eligible rides.
- Separated draft, active, full, completed, and cancelled rides with status filters.
- Preserved ride details in Firestore for completed and cancelled rides unless the driver explicitly deletes a ride.

**Done when:** drivers can manage the full lifecycle of their Firestore-backed rides.

## 9. Build Real Ride Search `[x]`

- Replaced sample rides with Firestore-backed ride loading.
- Added route, date, seat, and lowest-price filtering.
- Hid expired, cancelled, completed, full, and unavailable rides from passenger search.
- Added loading, empty-results, and retry states.
- Used normalized city text for route matching.
- Added route-aware CAD/USD price and savings display.

**Done when:** a ride published by one local user appears correctly in another user’s search results.

## 10. Implement Ride Requests `[x]`

- Let passengers request one or more seats.
- Prevent duplicate requests and overbooking.
- Save request details and status in Firestore.
- Added pickup, drop-off, luggage, and passenger message fields.
- Store passenger request history in session state after submission.

**Done when:** a passenger can submit a real request for a published ride.

## 11. Implement Driver Decisions `[x]`

- Load passenger requests for each owned ride.
- Support Accept and Decline actions.
- Update available seats after acceptance.
- Prevent accepting more passengers than available seats.
- Save accepted and declined request status changes to Firestore.
- Replace the sample driver request dashboard with Firestore-backed request cards.

**Done when:** driver decisions update both accounts consistently without seat-count errors.

## 12. Build Passenger Trip Management `[x]`

- Replaced sample My Trips content with Firestore-backed passenger requests and trips.
- Show pending, accepted, declined, active, completed, and cancelled trip states.
- Allow cancellation of eligible pending requests.
- Create passenger trip documents with preserved ride snapshots when drivers accept requests.
- Sync accepted passenger trips when driver rides become active, completed, cancelled, or deleted.
- Exposed focused passenger trip views from Profile through Saved trips and Ride history.

**Done when:** passengers see an accurate Firestore-backed history and current trip state.

## 13. Build Real-Time Messaging `[x]`

- Replaced sample conversations and messages with Firestore-backed ride conversations.
- Create chats only for involved passengers and drivers after accepted ride requests.
- Added automatic local refresh while the inbox or chat screen is open.
- Added timestamps, unread counts, read-on-open behavior, empty states, and send states.
- Backfilled missing conversations for already accepted local ride requests.

**Done when:** two local accounts can exchange messages and see updates without refreshing.

## 14. Security and Automated Testing `[~]`

- Restricted profile and vehicle reads/writes to their owners.
- Restricted ride, request, trip, conversation, and message writes to the owning or involved users.
- Restricted profile-photo uploads/downloads to `profilePhotos/{uid}.jpg`.
- Added `./scripts/test-security-rules.sh` for disposable-user Firestore and Storage rule checks.
- Updated profile emulator testing to use owner-scoped profile photo paths.
- Replaced authenticated collection scans for rides, ride requests, trips, and conversations with server-side filtered Firestore queries.
- Still need atomic seat-booking tests so two passengers cannot overbook the same ride at the same time.
- Still need Swift unit test and UI test targets in Xcode.
- Still need CI builds for pull requests, accessibility checks, offline behavior tests, and multiple iPhone size checks.

**Done when:** unauthorized operations fail and core local workflows pass automatically.

## 15. Complete Account Tools and Settings `[~]`

- Identity and license, payment methods, trip alerts, support, passenger requests, and payout setup now open from Profile with usable local UI.
- Passenger requests are connected to Firestore-backed driver request decisions.
- Identity/license, payment methods, trip alerts, support forms, and payout setup are still stored locally or shown as prototype flows.
- Add Firestore schemas for account settings, notification preferences, support tickets, payout setup status, and verification status.
- Persist account-tool changes per authenticated user instead of using device-only `AppStorage`.
- Add loading, validation, save, error, and success states for each tool page.
- Decide which fields are local-only, which are user-editable, and which must be controlled by an admin/provider.

**Done when:** every Profile tool opens, saves the correct data for the logged-in user, reloads after logout/login, and clearly avoids fake production payment or verification promises.

## 16. Trust, Safety, Verification, and Ratings `[ ]`

- Build a real identity and driver verification workflow.
- Choose a KYC/license provider or define an admin-review process for local/staging.
- Add ratings and reviews after completed trips.
- Update persisted `ratingAverage`, `ratingCount`, `completedTripCount`, and verification fields from real workflows.
- Add report, block, and unsafe-ride flows for passengers and drivers.
- Add cancellation rules, late-cancellation states, and visible policy text.
- Add moderation/admin review requirements before production.

**Done when:** trust badges, ratings, verification, and safety actions are based on real state instead of manually seeded profile fields.

## 17. Payments, Payouts, and Receipts `[ ]`

- Choose the payment approach: cash-only MVP, Stripe, Stripe Connect, Apple Pay, or another provider.
- Add payment authorization or collection only after a driver accepts a passenger request.
- Add driver payout onboarding and payout status.
- Store only provider tokens/statuses, never raw card or bank data.
- Add receipts, refunds, cancellation fees, and disputed-payment states.
- Add currency handling for USD/CAD across ride price, saved amount, payment, payout, and receipts.

**Done when:** passengers can pay safely, drivers can receive payouts safely, and no sensitive payment data is stored directly in Firestore.

## 18. Notifications and Background Updates `[ ]`

- Add local notification permission flow and in-app alert preferences.
- Add APNs/Firebase Cloud Messaging for accepted/declined requests, new messages, ride reminders, cancellations, and payout/payment updates.
- Add badge counts for unread messages and pending driver requests.
- Replace polling-only message refresh with a production-ready listener or push-triggered refresh.
- Add notification deep links to the relevant ride, request, trip, or chat.

**Done when:** users receive timely updates without keeping the app open.

## 19. Backend/API and Cloud Functions `[ ]`

- Decide which operations should move from the iOS client to trusted backend code.
- Add Cloud Functions or an API for privileged actions such as accepting requests, seat count updates, payment webhooks, payouts, verification callbacks, support tickets, and notification sending.
- Make ride acceptance transactional so request status, trip creation, conversation creation, and seat count update succeed or fail together.
- Add server-side validation for statuses, ownership, timestamps, price, seats, and payment/payout state.
- Add admin-only operations for support, moderation, verification, refunds, and account review.

**Done when:** sensitive marketplace operations are no longer trusted only to the iOS client.

## 20. Production Firebase and Environment Configuration `[ ]`

- Separate local, staging, and production configurations.
- Add production Firebase configuration securely.
- Ensure Release builds cannot connect to local emulators.
- Add build configuration guards for emulator hosts, project IDs, bundle IDs, and feature flags.
- Add staging data rules and seed data for teammate testing.
- Keep local emulator exports out of accidental production workflows.

**Done when:** the app is ready for controlled staging distribution without exposing local configuration or test data.

## 21. Observability, Privacy, and Account Lifecycle `[ ]`

- Add crash reporting and basic analytics for key funnels: register, publish ride, search, request, accept, message, cancel.
- Add privacy controls for profile photo, phone, email, and ride/contact visibility.
- Add account deletion, data export, and session revocation.
- Add log redaction so tokens, phone numbers, and payment/identity details are not exposed.
- Add clear privacy policy and terms links in Profile/Support.

**Done when:** the app can be operated and debugged responsibly without exposing user data.

## 22. App Store and Release QA `[~]`

- Added the TriipMate app icon to the Xcode asset catalog.
- Still need launch screen polish, App Store screenshots, app description, privacy nutrition labels, and permission copy.
- Test all main flows on small, standard, and large iPhone simulators.
- Test fresh install, logout/login, emulator restart, poor network/offline, dark mode if supported, dynamic type, and VoiceOver basics.
- Add a final manual release checklist for passenger and driver flows.

**Done when:** a staging/TestFlight build can be handed to real testers with a clear checklist and known limitations.

## Recommended Next Work

Continue stage **14** first. The highest-impact next change is replacing collection scans with filtered Firestore queries and adding automated Swift tests. After that, stage **15** should persist Profile tools to Firestore, and stage **19** should move seat booking and driver decisions into a transactional backend/API path.
