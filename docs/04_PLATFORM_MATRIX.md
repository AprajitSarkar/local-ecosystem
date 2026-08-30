# PLATFORM MATRIX

| Capability | Android | iPadOS/iOS | Linux | Windows |
|---|---|---|---|---|
| Flutter UI | Yes | Yes | Yes | Yes |
| LAN discovery | Yes | Yes, Bonjour/local-network permission | Yes | Yes |
| Pairing | Yes | Yes | Yes | Yes |
| Encrypted LAN transfer | Yes | Yes | Yes | Yes |
| File receiving | Yes | Yes, OS-specific storage/share APIs | Yes | Yes |
| Share Sheet sender | Yes | Yes, Share Extension | Later/native integration | Later/native integration |
| Clipboard sync | Yes, subject to Android restrictions | Restricted by iOS background/privacy rules | Yes | Yes |
| Notifications | Yes | Yes | Desktop notification | Windows notification |
| Background transfer | OS-dependent | Strongly OS-managed | Yes | Yes |
| IPA build | N/A | Requires Apple/macOS signing environment | N/A | N/A |
| APK/AAB build | Yes | N/A | N/A | N/A |
| Linux package | N/A | N/A | Yes | N/A |
| Windows package | N/A | N/A | N/A | Yes |

## Apple build requirement

Flutter source code can contain the iOS/iPadOS application.

A signed IPA cannot be produced and installed as a normal final release artifact purely from Linux.

For a normal signed iOS/iPadOS build, use:
- macOS
- Xcode
- Apple Developer signing credentials/profiles

If the user uses a sideloading workflow, the generated app still needs to be signed according to that workflow.

The project should therefore be prepared for:
flutter build ipa

on a supported macOS/Xcode environment.

Android:
flutter build apk
flutter build appbundle

Linux:
flutter build linux

Windows:
flutter build windows
