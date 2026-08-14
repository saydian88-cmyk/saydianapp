[CmdletBinding()]
param(
    [string]$DeviceId = '',
    [string]$WeatherApiKey = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Enter-SaidianAppDev.ps1') -Quiet

& adb start-server | Out-Null
$adbLines = @(& adb devices -l 2>&1)
if ($LASTEXITCODE -ne 0) { throw "ADB failed:`n$($adbLines -join "`n")" }

$devices = @(
    foreach ($line in $adbLines) {
        if ($line -match '^(?<id>\S+)\s+(?<state>device|unauthorized|offline)\b(?<details>.*)$') {
            [PSCustomObject]@{
                Id = $Matches.id
                State = $Matches.state
                Details = $Matches.details.Trim()
            }
        }
    }
)
$physicalDevices = @($devices | Where-Object { $_.Id -notmatch '^emulator-' })

if ($DeviceId) {
    $selected = $physicalDevices | Where-Object { $_.Id -eq $DeviceId } | Select-Object -First 1
    if (-not $selected) { throw "The requested physical Android device is not connected: $DeviceId" }
    if ($selected.State -ne 'device') { throw "Android device $DeviceId is $($selected.State). Unlock the phone and approve USB debugging." }
} else {
    $readyDevices = @($physicalDevices | Where-Object { $_.State -eq 'device' })
    if ($readyDevices.Count -eq 0) {
        $summary = if ($physicalDevices.Count) {
            ($physicalDevices | ForEach-Object { "$($_.Id): $($_.State) $($_.Details)" }) -join "`n"
        } else {
            'No physical Android device was reported by ADB.'
        }
        throw "No authorized physical Android device is ready.`n$summary`nUnlock the phone, enable USB debugging, select File Transfer, and approve the computer."
    }
    if ($readyDevices.Count -gt 1) {
        $summary = ($readyDevices | ForEach-Object { "$($_.Id) $($_.Details)" }) -join "`n"
        throw "Multiple physical Android devices are ready. Re-run with -DeviceId:`n$summary"
    }
    $selected = $readyDevices[0]
    $DeviceId = $selected.Id
}

$configPath = Join-Path $env:SAIDIAN_APP_ROOT 'config\dev.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    $examplePath = Join-Path $env:SAIDIAN_APP_ROOT 'config\dev.json.example'
    if (-not (Test-Path -LiteralPath $examplePath)) { throw "Missing runtime config: $configPath" }
    Copy-Item -LiteralPath $examplePath -Destination $configPath
}

$model = (& adb -s $DeviceId shell getprop ro.product.model 2>$null).Trim()
$androidVersion = (& adb -s $DeviceId shell getprop ro.build.version.release 2>$null).Trim()
Write-Host "Using physical Android device: $DeviceId ($model, Android $androidVersion)" -ForegroundColor Green

$arguments = @('run', '-d', $DeviceId, '--debug', '--dart-define-from-file=config/dev.json')
if ($WeatherApiKey) { $arguments += "--dart-define=QWEATHER_API_KEY=$WeatherApiKey" }
& flutter @arguments
exit $LASTEXITCODE
