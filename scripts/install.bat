@echo off
title fl-client debug
echo Working dir: %~dp0
echo.

REM Automatically unblock all files (bypass SmartScreen "from internet" flag)
echo Unblocking files (SmartScreen bypass)...
powershell -Command "Get-ChildItem -Path '%~dp0' -Recurse | Unblock-File" 2>nul
echo Done.
echo.

echo Starting fl_client.exe...
echo If no window appears within 10 seconds, the app is stuck.
echo.

start "" /wait "%~dp0fl_client.exe"

echo.
echo Exit code: %errorlevel%
echo.

if exist "%~dp0crash.log" (
    echo === crash.log ===
    type "%~dp0crash.log"
    echo ===================
) else (
    echo No crash.log found.
    echo If the process hung without a window, try:
    echo   1. Right-click fl_client.exe - Properties - check Unblock
    echo   2. Run this bat as Administrator
    echo   3. Temporarily disable antivirus
)

echo.
pause
