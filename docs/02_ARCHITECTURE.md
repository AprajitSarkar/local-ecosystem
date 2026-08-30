# ARCHITECTURE

## Stack

Frontend:
- Flutter
- Dart

Local persistence:
- SQLite/Drift or another mature Flutter-compatible local database.

Discovery:
- mDNS/Bonjour-compatible local service discovery.

Transport:
- TLS-secured TCP/WebSocket control channel.
- Streaming file transfer over authenticated encrypted connection.

Security:
- Per-installation public/private key pair.
- Secure platform key storage.
- Mutual authentication after pairing.

Platform bridges:
- Android native Kotlin where required.
- iOS/iPadOS native Swift where required.
- Linux native integration where required.
- Windows native integration where required.

## Logical services

DeviceIdentityService
- creates/loads device identity
- returns device ID/public key

DiscoveryService
- advertises service
- discovers peers
- tracks online/offline

PairingService
- creates pairing request
- validates approval
- stores trusted peer

ConnectionService
- establishes secure channel
- authenticates peer
- reconnects

EcosystemService
- manages membership
- broadcasts membership changes

ClipboardService
- detects permitted clipboard changes
- publishes events
- applies remote events
- prevents loops

TransferService
- queues
- streams
- verifies
- completes/cancels/retries

LinkService
- validates URLs
- transfers URL
- requests/open browser action

NotificationService
- local notifications
- transfer progress

ActivityService
- records user-visible events

## Protocol

Use versioned messages.

Example envelope:

{
  "version": 1,
  "type": "pairing_request",
  "messageId": "...",
  "sourceDeviceId": "...",
  "timestamp": "...",
  "payload": {}
}

Message types:
- hello
- pairing_request
- pairing_response
- ecosystem_state
- clipboard_event
- transfer_offer
- transfer_accept
- transfer_progress
- transfer_complete
- transfer_cancel
- link_offer
- device_presence
- error

All messages must be validated against schemas.

## File transfer

Do not load entire files into memory.

Use:
- chunked streaming
- checksum/hash
- resumable design
- cancellation
- progress reporting

MVP can use sequential chunks. Keep protocol extensible for resume and parallelism.

## Trust model

Trusted device record:

- deviceId
- displayName
- platform
- publicKey
- capabilities
- addedAt
- lastSeen
- trustStatus

Never trust a device only because it is visible through discovery.

Discovery means "potential peer", not "trusted peer."

## Threat model

Protect against:
- random LAN device attempting to pair without approval
- unauthorized file transfer
- message tampering
- replayed messages
- device impersonation
- clipboard event loops
- malicious URLs
- path traversal during file save

Do not expose files through an unauthenticated HTTP server.

Do not accept arbitrary destination paths from peers.

Sanitize filenames.

Keep downloads inside controlled app/user-selected directories.

## Conflict policy

Clipboard:
- attach monotonically sortable event metadata.
- reject duplicate event IDs.
- reject events older than a known superseding event when appropriate.
- never cause an event loop.

Device:
- local display-name changes are local metadata unless synchronized explicitly.

## Future scalability

The architecture must permit:
- multiple ecosystems
- QR pairing
- larger transfer queues
- resumable transfers
- LAN-only mode
- optional cloud relay
- remote transfer
- selective clipboard sync
- clipboard history
- folder sync

These are not MVP requirements.
