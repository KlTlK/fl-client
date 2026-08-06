# fl-client

Sing-box VPN client in FlClash style with animations.

## Why sing-box
Switched the core from Xray to **sing-box** because it eats ANY subscription out of the box: VLESS / VMess / Trojan / Shadowsocks / Hysteria2 / TUIC / WireGuard [[1]]. Its TUN is mature, auto-routes properly, and on Windows shows up as `sing-tun Tunnel` (exactly like your screenshot).

## How it works
- `flutter_singbox_vpn` embeds the sing-box core (Android VPN mode out of the box) [[1]].
- `lib/services/singbox_service.dart` builds the sing-box JSON config (tun inbound + vless/reality outbound).
- Replace the demo node in `lib/state/vpn_state.dart` (`_config`) with your own uuid/host/port/publicKey/shortId — or wire subscription import.

## Features
- Animated power/connect toggle (FlClash-style pulse & glow)
- Live traffic chart + latency card
- Eats all sub formats via sing-box
- Dark neon theme

## Build
    flutter pub get
    flutter run                  # Android
    flutter run -d windows       # desktop (see note)

## CI
`.github/workflows/build.yml` -> artifacts `android-apk` and `windows-exe` on push to `main`.

> Desktop TUN via this plugin covers Android fully; Windows sing-tun needs the desktop variant of the plugin wired in. APK is the primary target right now.
