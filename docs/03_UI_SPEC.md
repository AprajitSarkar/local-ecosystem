# UI SPECIFICATION

## Visual direction

Premium cross-platform utility.

Reference feeling:
- modern operating system utility
- calm
- precise
- responsive
- information-dense without clutter

Avoid:
- generic AI dashboard
- excessive glassmorphism
- neon gradients
- oversized hero cards
- random decorative blobs
- unnecessary illustrations
- excessive shadows
- excessive rounded containers

## Home

Header:
- Ecosystem name
- connection indicator
- device count

Main:
- "Connected" state
- latest clipboard
- quick actions

Quick actions:
- Add Device
- Send File
- Send Link

Recent activity:
- compact timeline

Empty ecosystem:
- concise explanation
- Add Device button

## Devices

Toolbar:
- Devices
- Add Device

Rows:
- platform icon
- device name
- online/offline
- last seen
- trusted badge

Tap:
- details

## Pairing

Use modal/bottom sheet.

Title:
"New device wants to join"

Content:
- device name
- platform
- concise trust explanation

Actions:
- Approve
- Decline

## File picker / destination

After choosing Local Ecosystem:
- "Send to"
- ecosystem-wide option
- individual device rows
- selection state
- Send button

## Transfer UI

Compact transfer row:
- file icon/type
- filename
- destination
- progress
- speed
- ETA
- pause/cancel/retry

Completed:
- check indicator
- Open
- Show in folder where supported

## Clipboard UI

Latest clipboard:
- content preview
- source device
- time
- Copy button

Never display extremely long clipboard text without truncation.

## Activity

Chronological list:
- icon
- action
- source/destination
- timestamp
- status

## Settings

Use grouped settings rather than cards everywhere.

Sections:
Ecosystem
Device
Clipboard
Transfers
Notifications
Appearance
Privacy & Security
About

## Responsive behavior

Phone:
- bottom navigation

Tablet:
- navigation rail or compact sidebar

Desktop:
- sidebar
- content
- optional detail pane

Use breakpoints based on available width, not device names.

## Motion

Use subtle motion for:
- device connection
- pairing success
- transfer progress
- navigation
- list insertion/removal

Respect reduced-motion accessibility settings.
