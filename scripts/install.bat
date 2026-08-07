@echo off
title fl-client debug
set DIR=%~dp0

REM Write file listing
echo === FILES IN FOLDER === > "%DIR%diag.txt"
dir /s /b "%DIR%" >> "%DIR%diag.txt" 2>&1
echo. >> "%DIR%diag.txt"

REM Check critical files
echo === CRITICAL CHECKS === >> "%DIR%diag.txt"
if exist "%DIR%fl_client.exe" (echo fl_client.exe: EXISTS >> "%DIR%diag.txt") else (echo fl_client.exe: MISSING! >> "%DIR%diag.txt")
if exist "%DIR%flutter_windows.dll" (echo flutter_windows.dll: EXISTS >> "%DIR%diag.txt") else (echo flutter_windows.dll: MISSING! >> "%DIR%diag.txt")
if exist "%DIR%data\flutter_assets\AssetManifest.bin" (echo AssetManifest.bin: EXISTS >> "%DIR%diag.txt") else (echo AssetManifest.bin: MISSING! >> "%DIR%diag.txt")
if exist "%DIR%data\flutter_assets\AssetManifest.json" (echo AssetManifest.json: EXISTS >> "%DIR%diag.txt") else (echo AssetManifest.json: MISSING! >> "%DIR%diag.txt")
if exist "%DIR%data\icudtl.dat" (echo icudtl.dat: EXISTS >> "%DIR%diag.txt") else (echo icudtl.dat: MISSING! >> "%DIR%diag.txt")
if exist "%DIR%data\flutter_assets\NOTICES" (echo NOTICES: EXISTS >> "%DIR%diag.txt") else (echo NOTICES: MISSING! >> "%DIR%diag.txt")
echo. >> "%DIR%diag.txt"

REM Unblock
powershell -Command "Get-ChildItem -Path '%DIR%' -Recurse | Unblock-File" 2>nul

REM Run exe
echo Starting fl_client.exe...
"%DIR%fl_client.exe"
echo Exit code: %errorlevel% >> "%DIR%diag.txt"

REM Check results
if exist "%DIR%dart_alive.txt" (echo dart_alive.txt: EXISTS >> "%DIR%diag.txt") else (echo dart_alive.txt: NOT FOUND >> "%DIR%diag.txt")
if exist "%DIR%crash.log" (echo crash.log: EXISTS >> "%DIR%diag.txt" & type "%DIR%crash.log" >> "%DIR%diag.txt") else (echo crash.log: NOT FOUND >> "%DIR%diag.txt")

echo.
echo Done! Please send the file diag.txt from this folder.
echo.
type "%DIR%diag.txt"
echo.
pause
