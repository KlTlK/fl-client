fl-client for Windows
=====================

What's in this folder:
  fl_client.exe      - the app
  sing-box.exe       - the VPN core
  flutter_windows.dll - Flutter engine
  data/              - app assets
  install.bat        - launcher with error output

How to run:
  1. Double-click install.bat (NOT fl_client.exe directly - bat shows errors).
  2. In the app: Import -> paste subscription URL or link -> Fetch.
  3. Pick a node -> press the power button.

If nothing happens / window closes immediately:
  - Run install.bat instead of fl_client.exe - it will show the error.
  - Install Visual C++ Redistributable: https://aka.ms/vs/17/release/vc_redist.x64.exe
  - Right-click fl_client.exe -> Properties -> check "Unblock" at the bottom.
  - Try running as Administrator (right-click -> Run as administrator).

Notes:
  - sing-box.exe must stay NEXT TO fl_client.exe.
  - First launch may ask for admin / firewall permission (TUN needs it).
