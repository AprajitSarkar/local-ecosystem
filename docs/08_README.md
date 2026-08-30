# Local Ecosystem MVP

This folder is a product/engineering specification intended to be handed to an AI coding agent such as Cursor, an agentic IDE, or another coding environment.

Read `00_MASTER_BUILD_PROMPT.md` first.

Then use:
- `01_MVP.md` for acceptance criteria
- `02_ARCHITECTURE.md` for technical architecture
- `03_UI_SPEC.md` for visual/UX requirements
- `04_PLATFORM_MATRIX.md` for platform constraints
- `05_AGENT_CHECKLIST.md` for implementation rules
- `06_REPO_STRUCTURE.md` for project structure
- `07_FIRST_RUN_COPY.md` for initial UX copy

## Important

This is a real LAN application specification, not a mockup specification.

The application should use direct local-network communication between trusted devices.

No cloud backend is required for the MVP.

## Platform target

Primary:
- Android
- iPadOS/iOS
- Linux

Secondary:
- Windows

## Apple packaging

The Flutter project can target iOS/iPadOS, but producing a normally signed IPA requires the Apple build/signing environment (macOS + Xcode + appropriate signing credentials).

The iPad sideloading method determines the final signing/install workflow.

## First milestone

The first demonstrable milestone is:

Android + iPad/Linux on the same Wi-Fi
-> discover
-> pair
-> trust
-> show online status
-> send a text event
-> send a small file
-> show progress
-> receive successfully
