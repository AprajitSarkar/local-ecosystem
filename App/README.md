# Local Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-blue)](#supported-platforms)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![100% Offline](https://img.shields.io/badge/Offline-100%25%20LAN%20P2P-brightgreen)](#security--privacy)

**Local Ecosystem** is a high-performance, 100% offline peer-to-peer (P2P) local network ecosystem. It connects **Android, Windows, Linux, and Web browsers** to share files at physical Wi-Fi/Ethernet speeds, synchronize clipboards, push links, and turn your mobile phone into a wireless trackpad and keyboard for your PC.

**100% Offline**: Operates entirely over your local Wi-Fi, Ethernet, or mobile hotspot. Zero internet connection required, zero cloud servers, zero telemetry.

---

## ⚡ Two Ways to Share

### 1. 📱 Native App-to-App (Full Features & Maximum Speed)
When both devices have the Local Ecosystem app installed (**Android, Windows, Linux**):
- **Full Transfer Speed (80–120+ MB/s)**: High-throughput TCP socket streaming over local Wi-Fi 5/6 and Gigabit LAN.
- **🖱️ Remote Trackpad & Keyboard**: Control your Windows or Linux PC mouse cursor from your phone (tap to click, two-finger scroll, right-click, remote typing).
- **📋 Real-Time Clipboard Sync**: Copy text on your phone, paste instantly on your PC (and vice versa).
- **🔗 Instant Link Dispatch**: Share links from your mobile browser and have them open automatically in your desktop browser.
- **🤫 Silent Windows Context Menu**: Right-click any file in Windows Explorer -> **"Send to Ecosystem"** (runs headlessly in the background with native Windows notifications).
- **Automatic Peer Discovery**: Devices automatically discover each other over UDP and subnet scanning.

### 2. 🌐 Built-In Web Portal (Zero-Install Receiver for Guests)
Need to send files to a friend's iPhone, iPad, Mac, or guest PC without installing the app?
- The host app spins up a local web server (e.g. `http://192.168.1.x:8080`).
- Any browser on the same Wi-Fi can open the page to download or upload files directly at **40–70 MB/s**.
- *Note*: Advanced features (remote trackpad, system clipboard sync, silent send) require the native app.

---

## 📊 Feature & Platform Matrix

| Feature | 📱 Native App (Android, Windows, Linux) | 🌐 Web Portal (Any Browser / Guest) |
|---|---|---|
| **High-Speed File Transfer** | ✅ **80 – 120+ MB/s** (TCP Stream) | ✅ **40 – 70 MB/s** (HTTP Stream) |
| **Zero App Install Required** | ❌ (Requires App) | ✅ (Open local IP in browser) |
| **Remote Trackpad & Mouse** | ✅ (Phone to PC) | ❌ (Browser sandbox limit) |
| **Wireless Keyboard Typing** | ✅ (Phone to PC) | ❌ (Browser sandbox limit) |
| **Real-Time Clipboard Sync** | ✅ (Bidirectional) | ❌ (Browser sandbox limit) |
| **Instant Link Dispatch** | ✅ (Opens in default browser) | ❌ |
| **Right-Click Context Menu** | ✅ (Windows Explorer) | ❌ |
| **Offline Hotspot Mode** | ✅ (Works with zero internet) | ✅ (Works with zero internet) |

---

## 🔒 Privacy & Local Security

- **100% Local & Offline**: Data flows directly between devices over physical LAN sockets.
- **Zero Cloud & Zero Telemetry**: No servers, no tracking, no external relays.
- **Ed25519 Cryptographic Pairing**: Explicit one-time device trust with asymmetric public key validation.
- **Path Traversal Protection**: Automatic filename sanitization prevents directory traversal attacks.

---

## 📦 Direct Downloads & Releases

Prebuilt, verified releases are available on the [**GitHub Releases**](https://github.com/AprajitSarkar/local-ecosystem/releases/latest) page:

- 📱 [**LocalEcosystem-v1.0.0.apk**](https://github.com/AprajitSarkar/local-ecosystem/releases/download/v1.0.0/LocalEcosystem-v1.0.0.apk) — Android phone & tablet release package (Android 8.0+)
- 🪟 [**LocalEcosystem-Windows-v1.0.0.zip**](https://github.com/AprajitSarkar/local-ecosystem/releases/download/v1.0.0/LocalEcosystem-Windows-v1.0.0.zip) — Portable Windows x64 release with Explorer context menu

---

## 📁 Repository Structure

```
local-ecosystem/
├── App/                      # Core Flutter multi-platform application
│   ├── android/              # Native Android host & DirectShareActivity
│   ├── windows/              # Native Windows runner & desktop hooks
│   ├── linux/                # Native Linux runner
│   ├── ios/                  # iOS runner & Share Sheet extension
│   ├── web/                  # Web portal, PWA manifest, and WASM runtime
│   └── lib/                  # Clean architecture Dart codebase
├── docs/                     # Technical specifications & architecture guides
│   ├── ARCHITECTURE.md       # High-throughput streaming & protocol design
│   ├── BENCHMARKS.md         # Wi-Fi 5/6 & LAN throughput test matrix
│   └── UI_SPEC.md            # Design system, themes & interaction specs
├── scripts/                  # Developer & automation scripts
│   ├── windows/              # Windows build scripts & context menu installer
│   │   ├── Build-Native-Windows.bat
│   │   └── Register-ContextMenu.bat
│   └── setup/                # Android SDK & C++ build tools setup
│       ├── install_android_sdk.bat
│       └── Install-VS-BuildTools.bat
├── LICENSE                   # MIT Open Source License
└── README.md                 # Master documentation
```

---

## 🛠️ Building from Source

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.22+ recommended)
- [Dart SDK](https://dart.dev/get-dart)
- Platform-specific build tools:
  - **Android**: Android SDK & NDK (`scripts/setup/install_android_sdk.bat`)
  - **Windows**: Visual Studio 2022 C++ Tools (`scripts/setup/Install-VS-BuildTools.bat`)
  - **Linux**: `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`
  - **iOS/macOS**: Xcode (macOS only)

### Build Commands

```bash
# Clone the repository
git clone https://github.com/AprajitSarkar/local-ecosystem.git
cd local-ecosystem/App

# Install Flutter dependencies
flutter pub get

# Generate Drift SQLite database and models
dart run build_runner build --delete-conflicting-outputs

# Build Android Release APK
flutter build apk --release

# Build Windows Native Release Executable
flutter build windows --release

# Build Linux Native Binary
flutter build linux --release

# Build Web Portal & PWA assets
flutter build web --release
```

---

## Architecture Overview

```
App/lib/
├── app/              # App routing, themes, and global lifecycle
├── core/             # Logging, error handling, throughput tuners, PWA services
├── domain/           # Pure entities (Device, Transfer, ClipboardEvent, Host platform heuristics)
├── data/             # Drift SQLite database, TCP socket client, UDP broadcast discovery, security
├── application/      # High-level services (TransferService, PairingService, WebPortalServer, SilentSender)
└── features/         # Clean UI screens
    ├── home/         # Status dashboard and quick actions
    ├── devices/      # Discovered and paired devices, remote trackpad trigger
    ├── transfers/    # Real-time transfer progress, speed graph, and history
    ├── activity/     # Audit log of transfers and security events
    └── settings/     # Port configuration, receive folders, web portal toggles
```

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
