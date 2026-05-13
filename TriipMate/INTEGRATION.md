# Integrating these files into Xcode

The `TriipMate/` folder contains the Phase 1 source tree. Files on disk are **not** automatically part of an Xcode project — you have to add them.

## One-time setup (iOS person)

1. Open Xcode → **File → New → Project** → **iOS → App** → name it `TriipMate`. Save it at the repo root (`triipmate-ios/`). Let Xcode create its own `TriipMate/` folder.
2. Quit Xcode. In Finder, replace the Xcode-generated `TriipMate/` folder with the one in this repo (the one containing `App/`, `Models/`, `Services/`, etc.).
3. Reopen Xcode. In the Project Navigator, delete the old default group, then **right-click the project → Add Files to "TriipMate"** → select every subfolder under `TriipMate/`. Make sure **Create groups** is chosen (not folder references).
4. Add Firebase via **File → Add Package Dependencies** → `https://github.com/firebase/firebase-ios-sdk` → check: `FirebaseAuth`, `FirebaseFirestore`, `FirebaseFirestoreSwift`, `FirebaseStorage`.
5. Drop `GoogleService-Info.plist` from the backend person into the project root group. **Never commit it** — it's covered by `.gitignore`.
6. Build (`⌘B`). It should compile clean against an empty Firebase project.

## Day-to-day

- New SwiftUI screens go under `Views/` in the matching feature subfolder.
- Anything that talks to Firebase belongs in `Services/`.
- `@Published` state and intent methods live in `ViewModels/`.
- Don't import `Firebase*` directly from a View — always go through a Service or ViewModel.

## When to delete this file

Once everyone on the team has the project building locally, this file is dead weight. Delete it.
