# TriipMate iOS

TriipMate is a SwiftUI application for matching long-distance travelers who want to share a ride and travel costs.

## Current Status

The active app currently supports:

- Passenger and driver modes
- Local Firebase registration, login, password reset, email updates, persisted sessions, and logout
- Firestore-backed user profiles and vehicle management
- Storage-backed profile photos
- Firestore-backed ride publishing from the driver Post Ride form
- Firestore-backed driver ride management for viewing, editing, cancelling, and deleting posted rides
- Firestore-backed passenger ride search with route, date, seat, and price filters
- Ride requests, trips, and messages as prototype/sample-data interfaces
- Driver Post Ride form with saved-vehicle selection and optional new-vehicle saving

Ride requests, trip history, and messaging are not yet connected end to end to Firestore. See [Plan.md](Plan.md) for the implementation order.

## Requirements

- macOS with Xcode 16 or newer
- iOS 16 or newer simulator runtime
- Firebase CLI 15 or newer
- JDK 21 for the Firestore and Storage emulators

Verify the local dependencies and committed emulator configuration:

```bash
./scripts/start-emulators.sh --check
```

The check reports a clear error when Firebase CLI, JDK 21, configuration, rules, or imported data are missing.

## Active Project Structure

The app uses one feature-based source tree. Shared models, services, session state, and design tokens live under `Core`; screens are grouped under `Features`:

```text
TriipMate/
├── App/
│   └── TriipMateApp.swift
├── Core/
│   ├── DesignSystem/Theme.swift
│   ├── Models/
│   │   ├── AuthModels.swift
│   │   ├── MarketplaceModels.swift
│   │   └── RideModels.swift
│   ├── Services/LocalFirebaseServices.swift
│   └── Session/AppSession.swift
└── Features/
    ├── Auth/AuthViews.swift
    ├── Messages/MessagesView.swift
    ├── Navigation/RootView.swift
    ├── Profile/ProfileView.swift
    └── Rides/
        ├── PublishTripView.swift
        ├── RideCard.swift
        ├── RideDetailView.swift
        └── SearchView.swift
```

There is one active implementation of each screen and service. Add new shared infrastructure under `Core`, and keep feature-specific views and behavior inside the matching `Features` folder.

## Run Locally

### 1. Start Firebase emulators

From the repository root:

```bash
./scripts/start-emulators.sh
```

This single command checks dependencies, starts Auth, Firestore, Storage, and the Emulator UI, imports `firebase-dataok/`, and exports updated local data back to the same folder when stopped with `Control-C`.

Local services:

| Service | Address |
|---|---|
| Emulator UI | http://127.0.0.1:4000 |
| Authentication | 127.0.0.1:9099 |
| Firestore | 127.0.0.1:8080 |
| Storage | 127.0.0.1:9199 |

The app is configured for the demo project `demo-triipmate-local`. Production Firebase is not used by the active local implementation.

### Fresh-clone check

After cloning the repository on another Mac:

1. Install Xcode, Firebase CLI 15 or newer, and JDK 21.
2. Run `./scripts/start-emulators.sh --check` from the repository root.
3. Run `./scripts/start-emulators.sh` and confirm all four services appear in the Emulator UI.
4. Stop with `Control-C`, restart, and confirm the local Auth and Firestore data is still present.
5. Open `TriipMate.xcodeproj` and run the app in an iPhone simulator.

No production Firebase account or credentials are required for this local workflow.

### Test local authentication

With the emulators running, execute:

```bash
./scripts/test-auth-emulator.sh
```

The script uses a disposable account to verify registration, duplicate-email and invalid-password errors, token refresh, email updates, password reset, login, and cleanup. The iOS app stores only the Firebase refresh token in Keychain, restores the session at launch, and clears it on logout.

Profile persistence can be verified separately with:

```bash
./scripts/test-profile-emulator.sh
```

This disposable-user test covers personal information, role changes, persisted statistics and verification fields, profile-photo upload/download, access rules, and cleanup.

### 2. Run the iOS app

1. Open `TriipMate.xcodeproj`.
2. Select the `TriipMate` scheme.
3. Select an iPhone simulator.
4. Run the app with `Command-R`.

## Structural Change Checklist

When moving, renaming, adding, or removing Swift files:

1. Confirm the file belongs to the `TriipMate` target in Xcode.
2. Build immediately after each small group of changes.
3. Launch the app and test registration/login, passenger mode, driver mode, Profile, and Post Ride.
4. Run `git status` and inspect the diff before committing.

Command-line build example:

```bash
xcodebuild \
  -project TriipMate.xcodeproj \
  -scheme TriipMate \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

The project does not currently contain an automated test target. Adding unit and UI test targets is tracked in `Plan.md`; until then, a successful build plus the manual smoke test above is required after structural changes.

## Firebase Data and Rules

- `firebase.json` defines local emulator ports and rule files.
- `firestore.rules` controls local Firestore access.
- `storage.rules` controls local Storage access.
- `firebase-dataok/` contains the current local emulator export.
- `Docs/FirestoreDataModel.md` defines the Firestore collections, ownership rules, statuses, and marketplace model relationships.
- `GoogleService-Info.plist` is ignored and must not be committed.

Current emulator rules are development-oriented and must be tightened before staging or production use.

## Git Workflow

1. Pull before starting work.
2. Make a focused change.
3. Build and smoke-test it.
4. Review `git status` and `git diff`.
5. Commit with a descriptive message.
6. Push through Xcode if terminal GitHub credentials are unavailable.

Repository: `https://github.com/anurmamedov/triipmate-ios.git`
