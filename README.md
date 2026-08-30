# Local Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20iOS%20%7C%20Web-blue)](#supported-platforms)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Offline](https://img.shields.io/badge/Offline-100%25%20LAN%20P2P-brightgreen)](#security--privacy)

**Local Ecosystem** is a high-performance, private, and 100% offline local area network (LAN) device ecosystem. It seamlessly bridges **Android, Windows, Linux, iOS/iPadOS, and Web browsers** to share files at physical network speeds, synchronize clipboards, push links, and turn your mobile phone into a wireless trackpad and keyboard for your PC — with **zero cloud dependencies** and **no internet required**.

---

## Key Features

### 🌐 Zero-Install Web Portal & PWA (Share to Any Device)
- **No App Installation Required**: Need to send a file to a friend's iPhone, iPad, Mac, or guest PC? Simply open the built-in **Web Portal** on your local network.
- **Progressive Web App (PWA)**: Recipients can install the Web Portal directly from Safari/Chrome with full offline caching and two-way upload/download capabilities.
- **Cross-Browser Compatible**: Works out-of-the-box on iOS Safari, macOS Safari, Chrome, Edge, and Firefox.

### 🖱️ Remote Trackpad & Wireless Keyboard
- **Phone as a PC Mouse**: Control your Windows or Linux desktop mouse pointer wirelessly with low-latency touch gestures (tap to click, two-finger scroll, right-click).
- **Remote Typing**: Send keystrokes and text directly to active desktop input fields from your phone.
- **Smart OS Detection**: Automatically recognizes desktop hosts (Windows / Linux) and unlocks remote control controls.

### ⚡ Ultra-Fast Local File Streaming
- **Native App-to-App Transfer**: Transfers files using high-throughput TCP socket streaming with adaptive chunking, reaching speeds of **80–120+ MB/s** on Wi-Fi 5/6 and Gigabit LAN.
- **App-to-Web Portal Streaming**: Stream directly to web browsers at **40–70 MB/s** via HTTP chunked streaming.
- **Zero Compression Loss & SHA-256 Integrity**: Complete end-to-end checksum verification ensures files are transferred bit-for-bit with 100% integrity.
- **Multi-Device Broadcast**: Send files simultaneously to all paired devices in your ecosystem with a single tap.

### 🤫 Silent Windows Explorer Context Menu ("Send to Ecosystem")
- **Right-Click & Send**: Select any file or folder in Windows File Explorer, right-click, and click **"Send to Ecosystem"**.
- **100% Headless Background Execution**: Transfers files silently in the background without opening the app window or navigating through menus.
- **Native Action Center Notifications**: Displays Windows balloon toasts for discovery status, streaming progress, and completion chimes.

### 📋 Real-Time Clipboard Synchronization
- Copy text on your Android phone and paste it instantly on your Windows/Linux PC or iPad.
- Cryptographically signed and loop-safe to prevent echo loops across the network.

### 🔗 Instant Remote Link Dispatch
- Push URLs from your phone to open automatically in your desktop browser, or vice versa.

### 📡 Offline Hotspot & Direct Wi-Fi Mode (No Router Needed)
- **No Wi-Fi Router? No Problem**: Simply turn on Mobile Hotspot or Wi-Fi Direct on one device and connect the other.
- Local Ecosystem automatically negotiates discovery and maintains full high-speed file transfer and remote control offline.

### 🔒 Privacy & Cryptographic Security
- **100% Offline & Local**: Zero telemetry, zero tracking, and zero cloud relays. Your data never leaves your local physical network.
- **Ed25519 Cryptographic Pairing**: Explicit one-time device trust with asymmetric public key validation.
- **Path Traversal Protection**: Automatic filename sanitization prevents malicious directory traversal attacks.

---

## Transfer Speed Benchmarks

| Transfer Mode | Typical Speeds (Wi-Fi 5 / 6 / Gigabit) | Protocol | Recipient Requirements |
|---|---|---|---|
| **Native App ➔ Native App** | **80 – 120+ MB/s** | P2P TCP Socket Stream | Local Ecosystem Installed |
| **App ➔ Web Portal (iOS/Mac/PC)** | **40 – 70 MB/s** | HTTP Chunked Stream | Web Browser (Safari, Chrome, Edge) |
| **App ➔ PWA (Offline Web)** | **40 – 70 MB/s** | HTTP REST & ServiceWorker | Installed PWA from browser |
| **Cloud-based Sharing (AirDrop alternatives)** | *Limited by Internet Bandwidth* | Cloud Relay | Internet Connection |

---

## Supported Platforms

| Platform | Discovery | File Transfer | Trackpad & Keyboard | Clipboard Sync | Silent CLI / Context Menu |
|---|---|---|---|---|---|
| **Android** | UDP + mDNS | ✅ (Send & Receive) | ✅ (Remote Client) | ✅ (Foreground/Service) | ✅ (Share Sheet) |
| **Windows** | UDP + Subnet Probe | ✅ (Send & Receive) | ✅ (Host Server) | ✅ (System Clipboard) | ✅ (Right-Click Explorer) |
| **Linux** | UDP + mDNS | ✅ (Send & Receive) | ✅ (Host Server) | ✅ (System Clipboard) | ✅ (CLI `--send`) |
| **iOS / iPadOS** | Bonjour / Web | ✅ (App & Web Portal) | ✅ (Remote Client) | ✅ (Foreground) | ✅ (Share Sheet) |
| **Web / PWA** | HTTP Subnet API | ✅ (Web Portal UI) | ❌ | ❌ | ❌ |

---

## Receive Folder Management

Each device configures its own default receive folder (**Settings → Transfers → Receive Folder**). Incoming files are saved automatically without interrupting your workflow.

- **Android**: `/sdcard/Download/LocalEcosystem/<Sender Name>/`
- **Windows**: `C:\Users\<User>\Downloads\LocalEcosystem\<Sender Name>\`
- **Linux**: `~/Downloads/LocalEcosystem/<Sender Name>/`
- **iOS/iPadOS**: `Files App → Local Ecosystem / Received`

---

## 📦 Direct Downloads & Releases

Prebuilt, verified binaries are available on the [**GitHub Releases**](https://github.com/AprajitSarkar/local-ecosystem/releases/latest) page:

- 📱 [**LocalEcosystem-v1.0.0.apk**](https://github.com/AprajitSarkar/local-ecosystem/releases/download/v1.0.0/LocalEcosystem-v1.0.0.apk) — Android phone & tablet release package (Android 8.0+)
- 🪟 [**LocalEcosystem-Windows-v1.0.0.zip**](https://github.com/AprajitSarkar/local-ecosystem/releases/download/v1.0.0/LocalEcosystem-Windows-v1.0.0.zip) — Portable Windows x64 release with Explorer context menu
- 🌐 [**LocalEcosystem-Web-PWA-v1.0.0.zip**](https://github.com/AprajitSarkar/local-ecosystem/releases/download/v1.0.0/LocalEcosystem-Web-PWA-v1.0.0.zip) — Zero-install Web Portal & Offline PWA bundle

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
