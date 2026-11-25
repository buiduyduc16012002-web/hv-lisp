# HVLisp updater: download <Repo> branch main from GitHub and copy it over <Dest>.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File update.ps1 -Repo owner/name -Dest C:\HVLisp
# Exit code: 0 = success, 1 = error. ASCII only.
# SPDX-License-Identifier: GPL-3.0-or-later

param(
    [Parameter(Mandatory = $true)][string]$Repo,
    [Parameter(Mandatory = $true)][string]$Dest
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $stamp = Get-Random
    $url = "https://github.com/$Repo/archive/refs/heads/main.zip?t=$stamp"
    $zip = Join-Path $env:TEMP 'hvlisp-update.zip'
    $tmp = Join-Path $env:TEMP 'hvlisp-update'

    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }

    Write-Output "Downloading $url"
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

    if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
        Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
    } else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $tmp)
    }

    $dirs = @(Get-ChildItem -LiteralPath $tmp -Directory -Force)
    if ($dirs.Count -ne 1) {
        throw "Expected exactly 1 folder inside the ZIP, found $($dirs.Count)."
    }

    if (-not (Test-Path -LiteralPath $Dest)) {
        New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    }

    Get-ChildItem -LiteralPath $dirs[0].FullName -Force |
        Copy-Item -Destination $Dest -Recurse -Force

    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue

    Write-Output "Updated $Dest from $Repo"
    exit 0
}
catch {
    Write-Output "Update failed: $($_.Exception.Message)"
    exit 1
}
