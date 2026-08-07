# fl-client

Sing-box VPN client in FlClash style. **Windows-only** for now (Android -> separate repo later).

## What you get from Actions
Every push builds a ready-to-run setup package in **Artifacts**:
- **`fl-client-windows-setup`** — zip with `fl_client.exe` + `sing-box.exe` + Flutter dlls + launcher. Download, unpack, run.
- `windows-exe-raw` — raw build output.

The workflow (`build.yml`) does everything in one job:
1. Builds `sing-box.exe` from SagerNet/sing-box source (Go 1.23).
2. Builds the Flutter Windows app.
3. Packs both into `fl-client-windows.zip` and uploads as artifact.

## How to run
1. Download `fl-client-windows-setup` from the latest green Actions run.
2. Unpack, double-click `fl_client.exe` (or `install.bat`).
3. Import -> paste subscription URL/link -> Fetch -> pick node -> power button.
> `sing-box.exe` must stay next to `fl_client.exe` (launched as a process).

## Features
- Subscription parser: vless/vmess/trojan/ss/hysteria2, base64 subs, multi-line (unit-tested).
- Persistent nodes (survive restarts).
- Real ping: TCP connect or HTTP GET, per-node, switchable.
- Process-mode core on Windows (sing-box.exe), graceful stop.
- FlClash-style animated UI (power button pulse, traffic chart, stat cards).

## Structure
- `lib/core/` — proxy_parser, singbox_outbound_builder, singbox_ffi, pinger
- `lib/services/` — singbox_service (+ process service for Windows), subscription_service, config_importer, node_storage
- `lib/screens/` — home_screen, import_screen
- `scripts/` — install.bat, README-WINDOWS.txt (packed into the setup zip)
- `test/` — proxy_parser_test, pinger_test (run in CI)

## Build locally
    flutter pub get
    flutter test
    flutter build windows --release
    # put sing-box.exe next to the produced fl_client.exe

## TODO
- Real traffic bytes from core (speed chart still simulates; latency is real).
- Auto-update check.
- Android in a separate repo.
