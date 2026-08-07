# fl-client

Sing-box VPN client in FlClash style. Flutter UI + core via **dart:ffi**, full subscription parser, persistent nodes, real ping.

## Done
- **Subscription parser** (`lib/core/proxy_parser.dart`): vless/vmess/trojan/ss/hysteria2, base64 subs, multi-line bundles. Unit-tested.
- **Persistent storage** (`lib/services/node_storage.dart`): imported nodes, selected node, and ping method survive app restarts (shared_preferences).
- **Real ping** (`lib/core/pinger.dart`): two methods — **TCP connect** (raw latency) and **HTTP GET**. Switchable in the Import screen, per-node latency shown, 'Ping all' button. Tested.
- **Graceful core shutdown** (`lib/core/singbox_ffi.dart` + `singbox_service.dart`): soft `box_shutdown(handle, timeoutMs)` then hard stop; desktop core stop failures are propagated (OneXray-style lifecycle). FFI loads softly and reports `coreAvailable`/`coreError` instead of crashing.
- **Import flows**: from string / clipboard / HTTPS subscription URL, with node selection.
- **CI**: parser + pinger tests on every push, plus `android-apk` and `windows-exe` artifacts.

## Architecture
- `lib/core/` — proxy_parser, singbox_outbound_builder, singbox_ffi, pinger
- `lib/services/` — singbox_service, subscription_service, config_importer, node_storage
- `lib/screens/` — home_screen, import_screen
- `lib/state/vpn_state.dart` — bootstrap (load saved), import+persist, ping (tcp/http), connect/disconnect lifecycle
- `c_include/libbox.h` + `ffigen.yaml` — generate typed FFI via `dart run ffigen`
- `.github/workflows/build-core.yml` — compiles libsingbox (.aar / .dll)

## Build
    # core -> libs/ (from Actions artifacts or local build)
    # optional: dart run ffigen --config ffigen.yaml
    flutter pub get
    flutter test
    flutter run -d <device>

## Remaining
- Real traffic bytes from core callbacks (the speed chart still simulates; latency is now real).
- QR/image scan import (deferred).
