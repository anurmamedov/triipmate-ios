# TriipMate iOS

TriipMate is an iOS app for matching long-distance travelers who are heading in the same direction and want to share travel costs.

## Current Frontend

The project now includes a SwiftUI prototype with:

- Authentication flow with welcome, login, register, forgot password, verification, profile setup, and trust setup screens
- Ride search by origin, destination, date, and seat count
- Recommended rides with driver ratings, verification state, open seats, and shared cost
- Ride detail screen with vehicle, seat price, trip note, message action, and request-to-join action
- Post-a-ride form for drivers
- Messages list for traveler communication
- Profile screen with trust, savings, settings, support, and logout

## Open in Xcode

1. Open `TriipMate.xcodeproj`
2. Select the `TriipMate` scheme
3. Choose an iPhone simulator
4. Run the app

---

## Team Split

Pick one role each. Do not both try to do everything.

| Role | Owns | Tools |
|---|---|---|
| iOS / Frontend | Xcode project, all SwiftUI screens, design system | Xcode, Figma, Swift |
| Backend / Infra | Firebase setup, API endpoints, database, payments | VS Code, Node.js, Firebase, Stripe |

- [ ] Anar owns: _____________
- [ ] Partner owns: _____________

---

## Phase 0 - Foundation

### Day 1 - Lock the Foundation

- [ ] Launch route picked: _______________
- [ ] Platform fee picked: _______________
- [ ] Role ownership confirmed
- [ ] Meeting cadence agreed
- [ ] Shared Notion or Linear workspace created for tasks

### Day 2 - Accounts & Repos

- [ ] Apple Developer account registered
- [ ] GitHub organization created
- [ ] Private repo: `triipmate-ios`
- [ ] Private repo: `triipmate-api`
- [ ] Domain purchased: _______________
- [ ] Google Workspace set up

### Day 3 - Tooling Setup

**iOS person:**
- [ ] Xcode 16 installed
- [ ] SwiftUI project created and pushed to `triipmate-ios`

**Backend person:**
- [ ] Node.js 20 installed
- [ ] Docker installed
- [ ] Firebase CLI installed
- [ ] Express + TypeScript project pushed to `triipmate-api`

**Both:**
- [ ] Figma installed
- [ ] Brand colors and fonts imported into Figma

### Day 4 - Firebase Project

- [ ] Firebase project created
- [ ] Auth enabled
- [ ] Firestore enabled
- [ ] Storage enabled
- [ ] Cloud Messaging enabled
- [ ] `GoogleService-Info.plist` downloaded and kept out of git

### Day 5 - Wireframe Core Screens

- [ ] Welcome / Sign Up
- [ ] Home search
- [ ] Trip Detail
- [ ] Create Trip
- [ ] Profile

---

## Local Development Environment

Everything should run against local emulators and test keys. No production credentials should be committed.

- Firebase Emulator Suite for Auth and Firestore
- Stripe Test Mode for payment flows
- Xcode Simulated GPS for route testing
- Postman collection in the backend repo for API checks

## Phase 1 - First Real Sprint

Definition of done: open the app, sign up with email, log in, set name and photo, log out, and log back in.

### iOS

- [ ] Project structure set up
- [ ] Firebase SDK added via Swift Package Manager
- [ ] Welcome screen built
- [ ] Sign Up screen built
- [ ] Login screen built
- [ ] Firebase Auth wired up
- [ ] Profile screen built
- [ ] Edit Profile screen built
- [ ] Profile read/write hooked to Firestore
- [ ] Sign Out button works

### Backend

- [ ] Express + TypeScript project set up
- [ ] PostgreSQL running via Docker Compose
- [ ] `users` table created
- [ ] Auth token verification endpoint
- [ ] Current user endpoint
- [ ] Profile update endpoint
- [ ] Firebase Admin SDK verifying ID tokens
- [ ] Input validation with Zod
- [ ] Avatar uploads configured
- [ ] Basic tests written
- [ ] Staging deployed

---

## Xcode and GitHub

This repo is connected to `https://github.com/anurmamedov/triipmate-ios.git`.

Daily flow inside Xcode:

- Pull before starting work
- Commit local changes
- Pull again if Xcode says the repository is out of date
- Push after your branch is up to date

## Requirements

- Xcode 16
- iOS 16.0+
- Swift 5.9+
