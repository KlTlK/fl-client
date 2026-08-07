@echo off
title fl-client
echo Starting fl-client...
echo If the window closes immediately, there's an error - check below.
echo.
"%~dp0fl_client.exe"
if %errorlevel% neq 0 (
    echo.
    echo ERROR: fl_client.exe exited with code %errorlevel%
    echo Possible causes:
    echo   - Missing Visual C++ Runtime (download from https://aka.ms/vs/17/release/vc_redist.x64.exe)
    echo   - Windows SmartScreen blocked it (right-click - Properties - Unblock)
    echo.
    pause
)
