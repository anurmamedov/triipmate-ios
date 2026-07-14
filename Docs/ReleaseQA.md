# TriipMate Release QA Checklist

Use this checklist before sharing a staging/TestFlight build.

## Device Sizes

- Test passenger search, ride detail, join request, messages, profile, and driver requests on a small iPhone simulator.
- Test the same flows on a standard iPhone simulator.
- Test the same flows on a large iPhone simulator.
- Confirm labels, values, cards, buttons, and tab items do not overlap or truncate important content.

## Accessibility

- Increase Dynamic Type and confirm primary flows remain readable.
- Turn on VoiceOver and confirm key buttons, tabs, text fields, and request actions have understandable labels.
- Confirm color is not the only signal for important states such as pending, accepted, declined, unread, and errors.
- Confirm buttons remain tappable and visually clear with larger text.

## Offline And Poor Network

- Launch while offline and confirm the app does not crash.
- Try login, search, publish, request, accept/decline, and message flows with network disabled.
- Confirm errors are readable and tell the user what happened.
- Re-enable network and confirm the app can recover after refreshing or reopening.

## Security And Data

- Run `./scripts/test-auth-emulator.sh` with local Firebase emulators running.
- Run `./scripts/test-profile-emulator.sh` with local Firebase emulators running.
- Run `./scripts/test-security-rules.sh` with local Firebase emulators running.
- Confirm users cannot view or edit another user's profile, vehicles, private requests, trips, or conversations.

## Final Smoke Test

- Build the app with the `TriipMate Local` scheme.
- Build the app with the `TriipMate Staging` scheme.
- Run `xcodebuild -project TriipMate.xcodeproj -scheme "TriipMate Local" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" build-for-testing`.
- Run Xcode unit and UI tests from the `TriipMate Local` scheme.
