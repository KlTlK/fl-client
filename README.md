# fl-client

Xray-based VPN client built with Flutter, UI/animation style inspired by FlClash.

## Platforms
- **Android**: full VPN mode via `flutter_v2ray_client` (real xray-core) [[2]][[3]].
- **Windows**: native desktop runner added (`windows/`), builds to `.exe` via GitHub Actions. UI works out of the box; system-wide TUN needs the `flutter_v2ray_client_desktop` package wired in `lib/services/desktop_xray_service.dart` [[13]].

## Core
- Android Xray service: `lib/services/xray_service.dart`
- Desktop Xray service (stub/contract): `lib/services/desktop_xray_service.dart`
- Replace the demo VLESS config in `lib/state/vpn_state.dart` (`_configUrl`) with your own uuid/host/port.

## Features
- Animated power/connect toggle (FlClash-style pulse & glow)
- Live traffic chart + real latency ping via Xray core
- VLESS / Reality config builder
- Dark neon theme

## Build locally
    flutter pub get
    flutter run                  # mobile
    flutter run -d windows       # desktop

## CI
`.github/workflows/build.yml` -> artifacts `android-apk` and `windows-exe` on every push to `main`.
