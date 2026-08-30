# AI CODING AGENT CHECKLIST

## Before coding

- Inspect repository.
- Confirm Flutter/Dart versions.
- Confirm target platforms.
- Establish architecture.
- Establish design tokens.
- Select maintained dependencies.
- Verify licenses and platform support.

## Never

- Do not use mock devices in production code.
- Do not fake LAN discovery.
- Do not use a central cloud server for MVP.
- Do not send files in plaintext.
- Do not store private keys in normal preferences.
- Do not silently accept first-time pairing.
- Do not promise unrestricted iOS background clipboard monitoring.
- Do not create a UI-only prototype and call it complete.

## Implement in vertical slices

Slice 1:
Create ecosystem -> persist -> reopen.

Slice 2:
Discover -> request pairing -> approve -> trusted device.

Slice 3:
Secure connection -> heartbeat -> online/offline.

Slice 4:
Clipboard event -> encrypted delivery -> de-duplication.

Slice 5:
File selection -> offer -> accept -> stream -> verify -> save.

Slice 6:
URL share -> receive -> open.

Slice 7:
Android Share Sheet.

Slice 8:
iOS/iPadOS Share Extension.

Slice 9:
Linux integration.

Slice 10:
Windows integration.

## Verification

For each slice:
- build
- unit tests
- physical-device test where applicable
- failure test
- permission-denied test
- offline test
- restart test

## Deliverables

The final repository must include:
- source code
- README
- setup instructions
- platform setup instructions
- environment requirements
- architecture documentation
- test suite
- build commands
- known platform limitations
- security notes

## Build commands

Android:
flutter build apk
flutter build appbundle

Linux:
flutter build linux

Windows:
flutter build windows

Apple:
flutter build ipa

Apple build command requires supported macOS/Xcode tooling and valid signing configuration.

## Final quality bar

The result must look like a real commercial utility.

Do not stop at a generated scaffold.

Do not leave core flows as TODOs.

If a requested platform capability is impossible under OS rules, implement the closest compliant workflow and clearly document it.
