fl-client for Windows
=====================

What's in this folder:
  fl_client.exe      - the app (Flutter Windows build)
  sing-box.exe       - the VPN core (sing-box, built from source)
  *.dll              - Flutter runtime libraries

How to run:
  1. Just double-click fl_client.exe (or install.bat).
  2. In the app: Import -> paste your subscription URL or link -> Fetch.
  3. Pick a node -> press the power button.

Notes:
  - sing-box.exe must stay NEXT TO fl_client.exe (the app launches it as a process).
  - First launch may ask for admin / firewall permission (TUN needs it).
  - This is a Windows-only build. Android is a separate repo.

Subscription parser supports: vless / vmess / trojan / ss / hysteria2,
base64 subscriptions, and multi-line bundles.
