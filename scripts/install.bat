@echo off
title fl-client debug
echo ============================================
echo  fl-client launcher (debug mode)
echo ============================================
echo.
echo Working dir: %~dp0
echo.

REM Проверяем что файлы на месте
if not exist "%~dp0fl_client.exe" (
    echo ERROR: fl_client.exe not found in %~dp0
    pause
    exit /b 1
)
if not exist "%~dp0flutter_windows.dll" (
    echo ERROR: flutter_windows.dll not found!
    pause
    exit /b 1
)

echo Starting fl_client.exe...
echo If a window appears - great, it works!
echo If nothing happens - check crash.log in this folder after closing.
echo.

start "" /wait "%~dp0fl_client.exe"

echo.
echo Process exited with code: %errorlevel%
echo.

if exist "%~dp0crash.log" (
    echo === crash.log contents ===
    type "%~dp0crash.log"
    echo ==========================
) else (
    echo No crash.log found - app may have crashed before Dart initialized.
    echo Try: right-click fl_client.exe - Properties - Unblock
    echo Or: run as Administrator
)

echo.
pause
