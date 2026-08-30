# REPOSITORY STRUCTURE

local_ecosystem/
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── android/
├── ios/
│   ├── Runner/
│   ├── ShareExtension/
│   └── ...
├── linux/
├── windows/
├── lib/
│   ├── app/
│   ├── core/
│   ├── domain/
│   ├── application/
│   ├── data/
│   ├── features/
│   ├── platform/
│   └── main.dart
├── test/
├── integration_test/
├── docs/
│   ├── architecture.md
│   ├── protocol.md
│   ├── security.md
│   └── platform-limitations.md
└── assets/

## Suggested feature structure

lib/features/ecosystem/
  presentation/
  application/
  domain/

lib/features/devices/
  presentation/
  application/
  domain/

lib/features/pairing/
  presentation/
  application/
  domain/

lib/features/clipboard/
  presentation/
  application/
  domain/

lib/features/transfers/
  presentation/
  application/
  domain/

lib/features/links/
  presentation/
  application/
  domain/

Keep widgets small and composable.
Keep state management out of widgets where possible.
