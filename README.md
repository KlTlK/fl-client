# fl-client

Sing-box VPN client in FlClash style. Architecture inspired by **Hiddify** and **OneXray**: Flutter UI + core embedded via **dart:ffi**, one core for all platforms.

## Subscription parser (the important part)
`lib/core/proxy_parser.dart` is a pure-Dart parser that eats everything:
- share links: `vless://` `vmess://` `trojan://` `ss://` `hysteria2://` / `hy2://`
- **base64 subscriptions** (auto-decodes a bundle of links)
- multi-line bundles
- Output: normalized `ParsedNode` list.

`lib/core/singbox_outbound_builder.dart` turns any `ParsedNode` into a sing-box outbound (vless+reality/xtls, vmess, trojan, shadowsocks, hysteria2) and assembles a full tun config.

`lib/services/singbox_service.dart` ties it together: `importConfig(rawString)` -> `startNode(node)` -> FFI core.

## Core wiring
- `lib/core/singbox_ffi.dart` - `dart:ffi` bindings to the compiled sing-box library.
- Native lib is built by CI: `.github/workflows/build-core.yml` (gomobile .aar for Android, cgo .dll for Windows).
- Windows -> native `sing-tun` TUN; Android -> VPN service.

## Build
    # build core (or grab artifacts from Actions) into libs/
    flutter pub get
    flutter run -d <device>

## App CI
`.github/workflows/build.yml` -> `android-apk` + `windows-exe`.

## TODO
- Wire subscription fetch over HTTPS + QR/image import into the UI.
- Generate FFI bindings from C headers via `ffigen` (OneXray-style) instead of manual lookups.
- Desktop core lifecycle hardening (stop/cleanup) like OneXray.
