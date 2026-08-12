[CmdletBinding()]
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$flutterRoot = if (Test-Path 'D:\Dev\Flutter\3.44.9') { 'D:\Dev\Flutter\3.44.9' } elseif ($env:FLUTTER_ROOT) { $env:FLUTTER_ROOT } else { '' }
$javaRoot = if (Test-Path 'F:\Codex\home\tools\jdk17') { 'F:\Codex\home\tools\jdk17' } elseif ($env:JAVA_HOME) { $env:JAVA_HOME } else { '' }
$androidSdk = if (Test-Path 'F:\Codex\home\tools\android-sdk') { 'F:\Codex\home\tools\android-sdk' } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { '' }

if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "Project path is missing: $ProjectRoot" }
if (-not $flutterRoot -or -not (Test-Path (Join-Path $flutterRoot 'bin\flutter.bat'))) { throw 'Set FLUTTER_ROOT to a Flutter 3.44.9 installation.' }
if (-not $javaRoot -or -not (Test-Path (Join-Path $javaRoot 'bin\java.exe'))) { throw 'Set JAVA_HOME to a JDK 17 installation.' }
if (-not $androidSdk -or -not (Test-Path (Join-Path $androidSdk 'platform-tools\adb.exe'))) { throw 'Set ANDROID_SDK_ROOT to an Android SDK installation.' }

$env:SAIDIAN_APP_ROOT = $ProjectRoot
$env:FLUTTER_ROOT = $flutterRoot
$env:JAVA_HOME = $javaRoot
$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk
$env:Path = (@(
    (Join-Path $flutterRoot 'bin'),
    (Join-Path $javaRoot 'bin'),
    (Join-Path $androidSdk 'platform-tools'),
    (Join-Path $androidSdk 'cmdline-tools\latest\bin')
) + @($env:Path -split ';' | Where-Object { $_ }) | Select-Object -Unique) -join ';'

Set-Location -LiteralPath $ProjectRoot
if (-not $Quiet) {
    Write-Host 'Saidian App development environment is ready.' -ForegroundColor Green
    Write-Host "Project : $ProjectRoot"
    Write-Host "Flutter : $flutterRoot"
    Write-Host "JDK     : $javaRoot"
    Write-Host "SDK     : $androidSdk"
}
