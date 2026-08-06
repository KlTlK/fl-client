# fl-client

Xray-based VPN client built with Flutter, UI/animation style inspired by FlClash.

## Status
Scaffold + animated UI shell. Xray core binding is a TODO (requires platform channels / FFI to libXray).

## Features
- Animated power/connect toggle (FlClash-style pulse & glow)
- Live traffic chart (upload/download) with smooth animations
- Latency ping card with ripple effect
- Config import placeholder (VLESS / VMess / Reality)
- Dark neon theme

## Build
    flutter pub get
    flutter run

## GitHub Actions
See `.github/workflows/build.yml` - produces Android APK and Windows EXE as artifacts on every push to `main`.

> Note: actual packet forwarding needs the Xray core wired via platform channels. This repo ships the full animated UI and the CI pipeline.
