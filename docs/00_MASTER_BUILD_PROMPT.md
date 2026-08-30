# LOCAL ECOSYSTEM — MASTER BUILD PROMPT

## Mission

Build a polished cross-platform local-device ecosystem application using Flutter and Dart.

Primary platforms for MVP:
1. Android
2. iPadOS/iOS
3. Linux

Secondary platform:
4. Windows

The application allows trusted devices on the same local Wi-Fi/LAN to form an ecosystem. Once devices are paired into an ecosystem, users can:
- synchronize clipboard text between trusted devices;
- send files to one device or all devices;
- send/open links on a selected device;
- see transfer status;
- discover and pair devices on the local network;
- avoid repeated acceptance prompts after a device is trusted.

The product must feel like a deliberately designed premium utility, not an AI-generated dashboard.

## Non-negotiable UX goals

- Fast, calm, minimal interface.
- Strong visual hierarchy.
- Smooth animations and transitions.
- Native-feeling touch interactions.
- Responsive layouts for phone, tablet and desktop.
- No excessive gradients, giant cards, random illustrations, excessive rounded rectangles, or decorative AI-style UI.
- Use whitespace, typography, subtle elevation, restrained color, clear status indicators.
- Support dark and light themes.
- Accessibility: readable text, sufficient contrast, semantic controls, keyboard navigation on desktop.
- Avoid unnecessary onboarding.
- Every important action should have immediate visual feedback.

## Core product model

Terminology:
- Ecosystem = a trusted group of devices.
- Device = an installed app instance participating in an ecosystem.
- Host = device that creates an ecosystem.
- Member = trusted device joined to an ecosystem.
- Pairing = explicit first-time trust approval.
- Transfer = a file/link payload sent between trusted devices.
- Clipboard event = synchronized clipboard text event.

Example:
Android phone + iPad + Linux laptop are members of one ecosystem.

If the user copies text on Android:
Android -> local ecosystem -> iPad + Linux receive the clipboard event.

If the user shares a video:
Android -> Share Sheet -> Local Ecosystem -> choose iPad -> transfer starts.
No repeated trust prompt is required after pairing.

## Important platform reality

Do not pretend all platforms have identical background capabilities.

### iOS/iPadOS
Use:
- Bonjour/mDNS for local discovery.
- NSLocalNetworkUsageDescription permission.
- Share Extension for receiving content from the iOS/iPadOS Share Sheet.
- App Groups where needed between the main app and Share Extension.
- User-approved clipboard APIs.
- Background transfer APIs where appropriate.
- APNs only if a future internet/cloud-assisted mode is added; MVP is LAN-first.

The iOS/iPadOS app cannot be assumed to run arbitrary continuous background code indefinitely. Design clipboard synchronization around OS-supported clipboard access and foreground/share-extension/background mechanisms. Clearly communicate platform limitations in the UI.

### Android
Use:
- Android Sharesheet integration.
- NSD/mDNS or equivalent LAN discovery.
- Foreground service only when justified by active transfers.
- Notifications for transfer progress.
- Runtime permissions appropriate to the Android version.
- Clipboard APIs subject to Android OS restrictions.

### Linux
Use:
- mDNS/Avahi when available.
- Local TCP/WebSocket transport.
- Desktop notifications.
- Clipboard integration through the Linux desktop environment.
- File picker integration.
- system tray/background process where practical.

### Windows
Use:
- mDNS/Bonjour-compatible discovery where available.
- Local TCP/WebSocket transport.
- Windows notifications.
- Clipboard integration.
- Share integration as a later enhancement if needed.

## Architecture

Use a clean layered architecture:

Presentation
  -> Application/Use Cases
    -> Domain
      -> Infrastructure

Recommended Flutter structure:

lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    errors/
    logging/
    networking/
    permissions/
    platform/
    utils/
  domain/
    entities/
    repositories/
    services/
  application/
    ecosystem/
    devices/
    pairing/
    clipboard/
    transfers/
    links/
  data/
    models/
    repositories/
    local/
    discovery/
    transport/
    security/
  features/
    home/
    ecosystem/
    devices/
    pairing/
    transfer/
    clipboard/
    settings/
  platform/
    android/
    ios/
    linux/
    windows/
  main.dart

Keep business logic platform-independent wherever possible. Isolate OS-specific behavior behind interfaces.

## Networking design

MVP transport should be LAN-only.

Discovery:
- Advertise a service over mDNS/Bonjour.
- Discover peers on the same LAN.
- Each device has a stable installation/device ID.
- Discovery data must not contain sensitive user content.

Recommended service:
_service._tcp

Each device advertises:
- deviceId
- displayName
- platform
- protocolVersion
- service port
- ecosystem membership hint
- capabilities

After discovery, establish a direct encrypted connection.

Transport:
- TCP + TLS for files and control messages, OR
- WebSocket over TLS for control channel + HTTPS/TLS for file transfer.

Do not transmit clipboard/file content in plaintext.

## Pairing/security

First-time pairing requires explicit approval on the receiving device.

Suggested flow:
1. Device A discovers Device B.
2. A sends a pairing request.
3. B displays:
   "Android Phone wants to join your ecosystem."
4. B chooses Approve or Decline.
5. Both devices exchange public keys.
6. Establish mutual trust.
7. Persist the trust relationship locally.
8. Future transfers from trusted members do not require confirmation.

Use public-key cryptography with a well-maintained platform-supported library.

Do not invent cryptographic primitives.

Recommended security model:
- Each installation generates a device key pair.
- Pairing authenticates both public keys.
- Store private key in secure platform storage where available.
- Use authenticated encrypted channels.
- Use capability-scoped permissions.
- Revoke/remove devices from ecosystem at any time.
- Rotate session keys as appropriate.

## Ecosystem model

One ecosystem has:
- ecosystemId
- name
- owner/creator device
- protocolVersion
- members
- creation timestamp
- security metadata

A device can:
- create ecosystem
- discover ecosystem
- request membership
- approve/deny request
- leave ecosystem
- remove another trusted device
- rename itself
- rename ecosystem

MVP can support one active ecosystem per installation to keep UX simple.

## Clipboard synchronization

MVP:
- Text clipboard only.
- Preserve text exactly.
- Include source device ID and event ID.
- Prevent echo loops.

Example:
A copies "hello".
A creates event E1.
B receives E1 and marks E1 as remote.
B updates clipboard.
B must not broadcast E1 again.

Use:
eventId + sourceDeviceId + timestamp + payloadHash.

De-duplicate events.

Important:
Clipboard synchronization must respect each platform's privacy/background rules. Do not implement hidden surveillance-style clipboard scraping.

UI:
- Show latest synchronized clipboard event.
- Show source device.
- Show timestamp.
- Optional "Copy again" action.
- Settings toggle: Clipboard Sync ON/OFF.

## File sharing

Supported:
- images
- video
- audio
- documents
- arbitrary files

Flow:
1. User invokes Android/iOS share sheet or in-app file picker.
2. User selects Local Ecosystem.
3. App shows ecosystem members.
4. User selects:
   - one device
   - multiple devices
   - all devices
5. Transfer begins.
6. The originating app/share extension should return to the previous app as quickly as platform rules permit.
7. Transfer continues through an OS-supported background mechanism where possible.
8. Sender gets progress.
9. Receiver gets notification/progress.
10. Completed files are saved to an appropriate user-accessible location.
11. Open/share action is offered after completion.

Do not require confirmation for already trusted devices unless the user has enabled a security setting requiring it.

Transfer states:
- queued
- discovering
- connecting
- preparing
- transferring
- paused
- completed
- failed
- cancelled

Support:
- progress percentage
- bytes transferred
- transfer speed
- ETA
- retry
- cancel

MVP should initially implement one active transfer per destination and a small queue. Architect the code so parallel transfers can be added later.

## Link sharing

A link is a special lightweight transfer.

User chooses:
Share -> Local Ecosystem -> iPad.

The target device receives:
- URL
- source device
- timestamp

If the user has enabled "Open links automatically", open the URL in the target device's default browser.

Otherwise show a notification/action:
"Open link".

Never execute arbitrary non-HTTP(S) schemes without explicit policy.

## Device discovery screen

When ecosystem is empty:
- Explain that devices on the same Wi-Fi can be added.
- Primary action: Add Device.

When Add Device is pressed:
- scan local network
- show discovered compatible devices
- show device icon/platform
- show device name
- show online status
- show "Request to Join"

When a pairing request arrives:
- modal/bottom sheet
- device name
- platform
- approximate local-network identity
- Approve
- Decline

Do not show raw IP addresses by default.

## Main navigation

Mobile:
- Home
- Devices
- Activity
- Settings

Desktop:
- Left sidebar
- Main content area
- Optional details panel

Home should show:
- Ecosystem name
- connection status
- member count
- recent clipboard
- recent transfers
- quick actions

Quick actions:
- Add Device
- Send File
- Send Link
- Clipboard Sync status

## Device details

Show:
- device name
- platform
- online/offline
- last seen
- capabilities
- trusted status
- transfer history
- Remove Device

## Activity

Timeline:
- Clipboard synced
- File sent
- File received
- Link opened
- Device joined
- Device left
- Transfer failed

Use compact rows rather than giant cards.

## Settings

Sections:
- Ecosystem
- Device
- Clipboard
- Transfers
- Notifications
- Appearance
- Privacy & Security
- About

Important controls:
- Ecosystem name
- Device name
- Clipboard Sync toggle
- Auto-open links toggle
- Notifications toggle
- Auto-accept trusted devices policy
- Remove ecosystem
- Leave ecosystem
- Remove trusted device

## Data persistence

Use a local database.

Persist:
- installation/device ID
- device key material references
- ecosystem metadata
- trusted device public keys
- settings
- transfer history metadata
- clipboard event IDs/hashes
- pending/recent pairing state

Do not store large file payloads in the database.

Store files in platform-appropriate app storage/download directories.

## Offline behavior

If a target is offline:
- show offline status.
- For files, offer queue-for-later only if explicitly enabled.
- For clipboard, do not assume stale clipboard content should overwrite a newer local clipboard.
- Use event timestamps/versioning.
- Provide deterministic conflict behavior.

MVP clipboard conflict policy:
- latest valid local-originated event wins only when the user/device is actively participating.
- Never blindly overwrite a newly changed clipboard with an old delayed event.

## Performance

Target:
- device discovery feels immediate.
- small text/clipboard events propagate within roughly 1 second on a normal LAN.
- transfer speed should approach practical LAN throughput after protocol overhead.
- UI must remain responsive during large transfers.

Never perform large file reads/writes on the Flutter UI isolate.

Use isolates/background platform mechanisms as appropriate.

## UI design system

Create a custom design system:
- typography scale
- spacing scale
- corner radius scale
- elevation rules
- icon rules
- motion rules
- component states

Motion:
- 150–250 ms micro-interactions
- 250–400 ms page transitions
- subtle spring motion where useful
- no excessive bouncing

Components:
- AppBar
- NavigationRail/NavigationBar
- DeviceRow
- StatusBadge
- TransferRow
- ProgressIndicator
- EmptyState
- PairingRequestSheet
- DevicePicker
- EcosystemHeader
- ClipboardCard
- ActivityRow
- SettingsSection

## Error handling

Errors must be human-readable.

Examples:
- "No compatible devices found."
- "This device is offline."
- "The pairing request expired."
- "The transfer was interrupted."
- "Local network access is disabled. Enable it in system settings."
- "Clipboard synchronization is unavailable while the app is restricted by the operating system."

Never show stack traces to users.

Log technical details locally for debugging.

## Testing

Unit tests:
- pairing state machine
- device repository
- clipboard event de-duplication
- transfer state machine
- link validation
- ecosystem membership
- conflict resolution

Integration tests:
- discovery
- pairing
- encrypted connection
- clipboard propagation
- file transfer
- link transfer

Platform tests:
- Android Sharesheet
- iOS/iPadOS Share Extension
- iOS local network permission
- Android notifications
- Linux clipboard
- Linux notifications

## MVP scope

Must work end-to-end:
1. Create ecosystem.
2. Discover another device on same LAN.
3. Send pairing request.
4. Approve pairing.
5. Persist trust.
6. Show devices.
7. Sync text clipboard where platform APIs permit.
8. Share a file to a selected trusted device.
9. Receive file with progress.
10. Share a URL to a selected trusted device.
11. Open URL on target device.
12. Show activity.
13. Remove device.
14. Handle offline/failed states.
15. Android/iPadOS/Linux builds.

Do NOT add:
- cloud accounts
- remote internet transfer
- user registration
- social features
- advertisements
- AI assistant
- unnecessary media gallery
- complicated chat system
- cryptocurrency
- VPN
- centralized server requirement

## Build order

Phase 1:
- Flutter project
- architecture
- design system
- local database
- device identity

Phase 2:
- LAN discovery
- connection layer
- pairing/security

Phase 3:
- ecosystem/device management

Phase 4:
- clipboard sync

Phase 5:
- file transfer

Phase 6:
- URL transfer/opening

Phase 7:
- Android Share Intent integration

Phase 8:
- iOS/iPadOS Share Extension

Phase 9:
- Linux integration

Phase 10:
- Windows support

Phase 11:
- polish, testing, performance, packaging

## Definition of Done

A feature is not done until:
- it works on at least two physical devices;
- it handles offline/failure states;
- it has loading/empty/success/error UI;
- it is tested;
- it does not block the UI;
- it respects platform permissions;
- it has no plaintext sensitive payloads on the LAN;
- it follows the design system;
- it does not require repeated approval for already trusted devices.

## Agent instructions

Do not create a fake demo.

Do not replace networking with mocked devices.

Do not claim clipboard/background support that the target OS does not permit.

Build the actual working LAN architecture.

When a platform limitation exists, implement the strongest OS-compliant behavior and document the limitation.

Keep all platform-specific code isolated.

Use established, maintained packages and verify package compatibility before adding dependencies.

Before declaring success, build/test Android, iPadOS/iOS where the build environment supports Apple tooling, and Linux.

For iOS/iPadOS release packaging, signing must be performed with Apple's required certificates/profiles on a supported macOS/Xcode environment. The project must be configured so an authorized developer can produce the signed IPA.
