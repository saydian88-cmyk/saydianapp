[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DeviceId,
    [string]$WeatherApiKey = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Enter-SaidianAppDev.ps1') -Quiet

$deviceState = (& adb -s $DeviceId get-state 2>$null).Trim()
if ($deviceState -ne 'device') { throw "Android device is not ready: $DeviceId" }

$arguments = @('run', '-d', $DeviceId, '--debug', '--dart-define-from-file=config/dev.json')
if ($WeatherApiKey) { $arguments += "--dart-define=QWEATHER_API_KEY=$WeatherApiKey" }
& flutter @arguments
