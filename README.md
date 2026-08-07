# fl-client

Sing-box VPN client in FlClash style. Architecture inspired by **Hiddify** and **OneXray**: Flutter UI + core via **dart:ffi**, one core for all platforms, full subscription parser.

## Subscription parser (core feature)
- `lib/core/proxy_parser.dart` — pure Dart, eats: `vless://` `vmess://` `trojan://` `ss://` `hysteria2://`/`hy2://`, **base64 subscriptions**, multi-line bundles.
- `lib/core/singbox_outbound_builder.dart` — any `ParsedNode` -> sing-box outbound (vless+reality/xtls, vmess, trojan, ss, hysteria2) + full tun config.
- `test/proxy_parser_test.dart` — unit tests, run in CI on every push.

## Import flows (UI wired)
- `lib/services/subscription_service.dart` — fetch subscription over HTTPS.
- `lib/services/config_importer.dart` — from string / clipboard / URL facade.
- `lib/screens/import_screen.dart` — paste link, fetch URL, from clipboard, node list with selection.
- Home screen shows selected node + node count; Import button opens the import screen.

## Core wiring
- `lib/core/singbox_ffi.dart` — `dart:ffi` bindings to compiled sing-box lib.
- `c_include/libbox.h` + `ffigen.yaml` — generate typed bindings via `dart run ffigen` (OneXray-style) instead of manual lookups.
- Native lib built by CI: `.github/workflows/build-core.yml` (gomobile .aar Android, cgo .dll Windows).
- Windows -> native `sing-tun` TUN; Android -> VPN service.

## State & lifecycle
`lib/state/vpn_state.dart` — import (string/clipboard/URL), node selection, connect/disconnect with error handling and cleanup.

## Build
    # 1. core -> libs/ (from Actions artifacts or local build)
    # 2. (optional) regenerate FFI: dart run ffigen --config ffigen.yaml
    flutter pub get
    flutter test                 # parser tests
    flutter run -d <device>

## CI
- `build.yml` — parser tests + `android-apk` + `windows-exe` artifacts.
- `build-core.yml` — compiles libsingbox (.aar / .dll).

## Remaining TODO
- QR code + image scan import (parser ready, needs scanner widget).
- Persist subscriptions/nodes locally (shared_preferences).
- Real traffic stats from core callbacks (currently simulated in the loop).
- Desktop core lifecycle hardening (stop/cleanup) like OneXray.
