# TriipMate iOS

iOS app for the TriipMate travel companion platform — a 2-person build.

This README is the **execution plan** for getting from zero to a working auth + profiles demo. Check items off as you go. Don't add scope until Phase 1 is fully green.

---

## 👥 Team Split

Pick one role each. Do not both try to do everything — you will step on commits and ship nothing.

| Role | Owns | Tools |
|---|---|---|
| **iOS / Frontend** | Xcode project, all SwiftUI screens, design system | Xcode, Figma, Swift |
| **Backend / Infra** | Firebase setup, API endpoints, database, payments | VS Code, Node.js, Firebase, Stripe |

If you both want iOS: one takes **iOS + Design**, the other takes **Backend + Product/Growth**.

- [ ] Anar owns: _____________
- [ ] Partner owns: _____________

---

## 🪜 Phase 0 — Foundation (Days 1–5)

The part most teams skip and then regret. Do this **before** writing feature code.

### Day 1 — Lock the Foundation (2–3h together)

- [ ] **Launch route** picked (Toronto ↔ Montreal? Toronto ↔ Ottawa? Pick ONE): _______________
- [ ] **Platform fee** picked (8% / 10% / 12%): _______________
- [ ] Role ownership confirmed (table above)
- [ ] Meeting cadence agreed: daily 15-min standup + weekly 1-hour review
- [ ] Shared Notion or Linear workspace created for tasks

### Day 2 — Accounts & Repos

- [ ] Apple Developer account registered ($99/year — **do this first**, approval takes 24–48h)
- [ ] GitHub organization created
- [ ] Private repo: `triipmate-ios` (this one exists at `anurmamedov/triipmate-ios`)
- [ ] Private repo: `triipmate-api` (backend)
- [ ] Domain purchased: `tripmate.app` (or backup): _______________
- [ ] Google Workspace set up for `team@tripmate.app`

### Day 3 — Tooling Setup

**iOS person:**
- [ ] Xcode 16 installed
- [ ] Empty SwiftUI project created and pushed to `triipmate-ios`

**Backend person:**
- [ ] Node.js 20 installed
- [ ] Docker installed
- [ ] Firebase CLI installed (`npm i -g firebase-tools`)
- [ ] Empty Express + TypeScript project pushed to `triipmate-api`

**Both:**
- [ ] Figma (free tier) installed
- [ ] Brand identity colors and fonts imported into Figma

### Day 4 — Firebase Project (backend person)

- [ ] Firebase project created: `tripmate-dev`
- [ ] **Auth** enabled
- [ ] **Firestore** enabled
- [ ] **Storage** enabled
- [ ] **Cloud Messaging** enabled
- [ ] `GoogleService-Info.plist` downloaded and sent to iOS person (**do not commit this file** — it's in `.gitignore`)
- [ ] Both read Firebase docs together (1h)

### Day 5 — Wireframe 5 Core Screens (in Figma, low-fi)

Don't design 12 screens. Just these five:

- [ ] Welcome / Sign Up
- [ ] Home (search trips)
- [ ] Trip Detail
- [ ] Create Trip (driver)
- [ ] Profile

This is your shared map for the next 8 weeks.

---

## 🧪 Local Development Environment

Everything runs against local emulators and test keys. **No production credentials ever touch a dev machine.**

```
        ┌──────────────────────────┐
        │ iPhone Simulator (Xcode) │
        │      SwiftUI App         │
        └────────────┬─────────────┘
                     │
            ┌────────┴────────┐
            ▼                 ▼
   ┌──────────────────┐   ┌──────────────────┐
   │ Firebase Emulator│   │ Local Mock API   │
   │  Auth + Firestore│   │ (payment flows)  │
   │                  │   │ Stripe Test Mode │
   └──────────────────┘   └──────────────────┘
```

**Tooling:**

- **Firebase Emulator Suite** — Auth + Firestore run locally. No traffic hits prod.
- **Stripe Test Mode** — use `sk_test_…` / `pk_test_…` keys only. Never put live keys on a dev machine.
- **Xcode Simulated GPS** — Product → Scheme → Edit Scheme → Run → Options → Default Location. Set a Toronto pin for testing.
- **Postman** — collection lives in the `triipmate-api` repo for hitting REST endpoints directly.

**Setup checklist (do before Phase 1 Week 2 coding):**

- [ ] Backend: `firebase init emulators` → enable Auth + Firestore emulators (`triipmate-api` repo)
- [ ] Backend: `firebase emulators:start` runs cleanly on `localhost`
- [ ] iOS: `FirebaseConfig.swift` already wires emulators for DEBUG builds
- [ ] Backend: `.env.local` populated with Stripe **test** keys (never commit — `.env*` is gitignored)
- [ ] Postman collection imported and one auth-protected endpoint tested end-to-end

**Golden rule:** if you ever see a `pk_live_…` or `sk_live_…` Stripe key on your laptop, stop and rotate it. Production keys belong in Railway/Firebase environment config, not in source or local env files.

---

## 🚀 Phase 1 — First Real Sprint (Weeks 2–3)

**Definition of done:** open the app on your iPhone → sign up with email → log in → set name + photo → log out → log back in. That is the entire goal. No trips. No chat. No payments.

### iOS Person

**Week 2 — Auth flow on screen**

- [ ] Project structure set up (folders in `TriipMate/` — see `INTEGRATION.md`)
- [ ] Firebase SDK added via Swift Package Manager
- [ ] Welcome screen built (orbit logo from brand file)
- [ ] Sign Up screen built (email + password)
- [ ] Login screen built
- [ ] Firebase Auth wired up — real sign-up works end to end

**Week 3 — Profile**

- [ ] Role Selection screen (Driver vs Passenger)
- [ ] Profile screen (avatar, name, bio)
- [ ] Edit Profile screen
- [ ] Profile read/write hooked to Firestore
- [ ] Sign Out button works

### Backend Person

**Week 2 — API skeleton**

- [ ] Express + TypeScript project set up (use `triipmate-api-scaffold/`)
- [ ] PostgreSQL running via Docker Compose
- [ ] `users` table created (migration `001_users.sql`)
- [ ] `POST /api/v1/auth/verify-token` endpoint
- [ ] `GET /api/v1/users/me` endpoint
- [ ] `PATCH /api/v1/users/me` endpoint

**Week 3 — Hardening**

- [ ] Firebase Admin SDK verifying ID tokens
- [ ] Input validation with Zod
- [ ] Firebase Storage configured for avatar uploads
- [ ] 5–10 basic tests written
- [ ] Staging deployed to Railway

---

## ✅ End of Phase 1 — Working Demo

Stop here. Resist scope creep. This is the hardest psychological part of the project.

The next phase (trips, chat, payments) only starts after the demo above works on both your phones.

---

## Appendix — Xcode ↔ GitHub setup

This repo is already connected to `git@github.com:anurmamedov/triipmate-ios.git`.

**Add your GitHub account to Xcode:** Xcode → Settings → Accounts → **+** → GitHub. Authenticate with a Personal Access Token (scopes: `repo`, `workflow`) or SSH key.

**Daily flow inside Xcode:**
- Commit: `⌥⌘C` (Source Control → Commit)
- Push: Source Control → Push
- History: `⌘2` → Source Control navigator

**Feature branches (Terminal):**
```bash
git checkout -b feature/short-name
# ...work...
git push -u origin feature/short-name
```

## Requirements

- Xcode 16
- iOS 16.0+ deployment target
- Swift 5.9+
