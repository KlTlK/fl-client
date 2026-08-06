# fl-client

Xray-based VPN client built with Flutter, UI/animation style inspired by FlClash.

## Core
Uses `flutter_v2ray_client` which wraps the real **xray-core** engine (the same one powering v2rayNG / FlClash) [[2]][[3]].
- Android: full VPN mode via the core.
- The Xray service lives in `lib/services/xray_service.dart`.
- Replace the demo VLESS config in `lib/state/vpn_state.dart` (`_configUrl`) with your own uuid/host/port to actually route traffic.

## Features
- Animated power/connect toggle (FlClash-style pulse & glow)
- Live traffic chart (upload/download) with smooth animations
- Real latency ping via Xray core (falls back to demo if core cannot start)
- Config builder for VLESS / Reality
- Dark neon theme

## Build
    flutter pub get
    flutter run

## GitHub Actions
`.github/workflows/build.yml` produces Android APK and Windows EXE as artifacts on every push to `main`.

> Note: desktop (Windows) VPN/TUN needs an extra native binding; the shipped plugin covers Android VPN out of the box. Windows build compiles the UI + core lib.
