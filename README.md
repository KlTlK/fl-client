# fl-client

Sing-box VPN client in FlClash style. **Windows-only** (Android -> separate repo later).

## How the core is bundled (flux-vpn approach)
We do NOT build sing-box from source. `scripts/fetch_sing_box.ps1` downloads the **official prebuilt** `sing-box.exe` from SagerNet/sing-box GitHub Releases and drops it into `libs/windows/`. The app launches it as a process. sing-box embeds wintun itself, so no extra driver files needed.

## What you get from Actions
Every push builds a ready-to-run setup package in **Artifacts**:
- **`fl-client-windows-setup`** — zip with `fl_client.exe` + `sing-box.exe` + Flutter dlls + launcher. Download, unpack, run.
- `windows-exe-raw` — raw build output.

The workflow (`build.yml`) does:
1. Fetches prebuilt `sing-box.exe` (no Go/cgo/gomobile compile).
2. Builds the Flutter Windows app.
3. Packs both into `fl-client-windows.zip` and uploads as artifact.

## How to run
1. Download `fl-client-windows-setup` from the latest green Actions run.
2. Unpack, double-click `fl_client.exe` (or `install.bat`).
3. Import -> paste subscription URL/link -> Fetch -> pick node -> power button.
> `sing-box.exe` must stay next to `fl_client.exe`.

## Features
- Subscription parser: vless/vmess/trojan/ss/hysteria2, base64 subs, multi-line (unit-tested).
- Persistent nodes (survive restarts).
- Real ping: TCP connect or HTTP GET, per-node, switchable.
- Process-mode core (sing-box.exe), graceful stop.
- FlClash-style animated UI.

## Build locally
    .\scripts\fetch_sing_box.ps1   # grabs sing-box.exe into libs/windows/
    flutter pub get
    flutter test
    flutter build windows --release
    # copy libs/windows/sing-box.exe next to the produced fl_client.exe

## Credits
Build/packaging approach borrowed from flux-vpn-client (prebuilt core fetch + portable zip).

## TODO
- Real traffic bytes from core (speed chart still simulates; latency is real).
- Auto-update check.
- Android in a separate repo.
