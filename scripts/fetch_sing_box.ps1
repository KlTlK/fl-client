#Requires -Version 5
<#
Downloads the latest stable sing-box Windows release into libs/windows/.
Copied approach from flux-vpn-client: we DO NOT build from source —
we grab the official prebuilt binary from GitHub Releases.
sing-box embeds wintun itself, so no separate wintun.dll needed.
#>
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$destDir = Join-Path $repoRoot "libs\windows"
$zipPath = Join-Path $env:TEMP "sing-box-windows-amd64.zip"

$release = Invoke-RestMethod -Uri "https://api.github.com/repos/SagerNet/sing-box/releases/latest"
$asset = $release.assets | Where-Object {
    $_.name -like "sing-box-*-windows-amd64.zip" -and $_.name -notlike "*legacy-windows-7*"
}
if (-not $asset) {
    throw "sing-box-*-windows-amd64.zip not found in latest release $($release.tag_name)"
}

Write-Output "Downloading sing-box $($release.tag_name)..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

New-Item -ItemType Directory -Path $destDir -Force | Out-Null

$sbExtractDir = Join-Path $env:TEMP "sing-box-extract"
if (Test-Path $sbExtractDir) { Remove-Item $sbExtractDir -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $sbExtractDir -Force
$innerDir = Get-ChildItem $sbExtractDir -Directory | Select-Object -First 1
Copy-Item (Join-Path $innerDir.FullName "sing-box.exe") $destDir -Force
Remove-Item $zipPath, $sbExtractDir -Recurse -Force

Write-Output "sing-box $($release.tag_name) -> $destDir\sing-box.exe"
