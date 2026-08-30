# MVP REQUIREMENTS

## Product

Local Ecosystem

## Objective

Create a trusted local network of personal devices that behaves as one ecosystem.

## Primary user story

"I have an Android phone, iPad, and Linux laptop. I want them to automatically discover one another on my Wi-Fi after I pair them once, synchronize text clipboard content, and let me send files or links between them without repeatedly approving each transfer."

## MVP user journeys

### Journey A — Create ecosystem

1. Install app.
2. Launch.
3. Choose "Create Ecosystem".
4. Enter ecosystem name.
5. Device becomes ecosystem host.
6. Home screen appears.

### Journey B — Add device

1. Open Devices.
2. Press Add Device.
3. App discovers compatible local devices.
4. Select a device.
5. Receiving device displays pairing request.
6. Receiving user approves.
7. Both devices exchange identity/public-key information.
8. Both show each other as trusted.
9. Future transfers do not require pairing again.

### Journey C — Clipboard

1. Device A copies text.
2. App receives an allowed clipboard event.
3. Event is authenticated and encrypted.
4. Other trusted devices receive it.
5. Their clipboard is updated where OS rules allow.
6. Event is not echoed back to the origin.

### Journey D — File

1. User selects a file.
2. Android/iOS Share Sheet or in-app Send File.
3. Choose Local Ecosystem.
4. Choose target device(s).
5. Transfer starts.
6. Sender sees progress.
7. Receiver sees notification/progress.
8. File is saved.
9. Activity records completion.

### Journey E — Link

1. User shares URL.
2. Choose Local Ecosystem.
3. Select iPad.
4. URL is sent.
5. Target receives it.
6. If auto-open is enabled and OS permits, default browser opens it.

## Acceptance criteria

- Two devices can discover each other on the same LAN.
- Pairing requires explicit first-time approval.
- Trusted state survives app restart.
- Device removal invalidates trust.
- File transfer is encrypted.
- Clipboard events cannot loop indefinitely.
- Transfer failures are recoverable.
- Activity accurately reflects state.
- UI works on phone, tablet and desktop.
- No mock networking in production paths.
