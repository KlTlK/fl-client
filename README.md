# fl-client

Sing-box VPN client in FlClash style. Architecture copied from **Hiddify**: Flutter UI + sing-box core embedded via **dart:ffi** — one core for all platforms, no pub.dev VPN plugins [[4]][[26]].

## How the core is wired
- `lib/core/singbox_ffi.dart` — `dart:ffi` bindings to the compiled sing-box library (`box_start` / `box_stop` / `box_validate`) [[16]].
- `lib/services/singbox_service.dart` — high-level service over FFI: builds sing-box JSON (tun inbound + vless/reality outbound), validates, starts/stops.
- The native library is **built by CI**, not committed:
  - `.github/workflows/build-core.yml` clones sing-box and compiles `libbox.aar` (Android arm64 via gomobile) and `libsingbox.dll` (Windows x64 via cgo) [[3]][[5]].
  - Artifacts: `libbox-android-aar`, `libsingbox-windows-dll`. Drop them into `libs/android/` and `libs/windows/`.
- On Windows this produces the native `sing-tun` TUN adapter (same as your screenshot); on Android it runs as a VPN service.

## Why not a plugin
Hiddify embeds the core directly through FFI instead of using a third-party VPN plugin — that way the same sing-box binary powers Android, Windows, macOS and Linux, with native TUN everywhere [[4]][[26]]. This repo follows the same approach.

## Build
    # 1. build the core (or grab artifacts from Actions)
    gh run watch  # after pushing, download libbox.aar + libsingbox.dll into libs/
    # 2. app
    flutter pub get
    flutter run -d <device>

## App CI
`.github/workflows/build.yml` -> `android-apk` + `windows-exe` artifacts.

## Notes
- Replace the demo node in `lib/state/vpn_state.dart` with your own uuid/host/port/publicKey/shortId.
- The FFI symbol names (`box_start` etc.) must match the exported symbols of your libbox build — adjust in `singbox_ffi.dart` if your sing-box fork exports differently.
