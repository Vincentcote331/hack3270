<#
.SYNOPSIS
    Convenience launcher for hack3270 proxy with TELUS mainframe targets.

.DESCRIPTION
    Starts the hack3270 TN3270 proxy listening on 127.0.0.1:3271 and API on 127.0.0.1:31337.
    Then you can open BlueZone using the 'hack3270' profile.

.PARAMETER Target
    Shortcut or hostname: sys2 (default), bct1, bct2, sys1, tqc1, or any custom IP/host.

.PARAMETER Port
    Target port (default 23).

.PARAMETER Session
    Session project name (default 'sas_decom').
#>
param(
    [string]$Target = "sys2",
    [int]$Port = 23,
    [string]$Session = "sas_decom"
)

$HostMap = @{
    "sys2"  = "sys2tcp.tsl.telus.com"
    "bct1"  = "bct1tcp.tsl.telus.com"
    "bct2"  = "bct1tcp2.tsl.telus.com"
    "sys1"  = "sys1tcp.tsl.telus.com"
    "tqc1"  = "TQC1.TSL.TELUS.COM"
    "drp"   = "drptpx.tsl.telus.com"
}

if ($HostMap.ContainsKey($Target.ToLower())) {
    $TargetHost = $HostMap[$Target.ToLower()]
} else {
    $TargetHost = $Target
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Hack3270Py = Join-Path $ScriptDir "hack3270.py"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Starting hack3270 Mainframe Proxy" -ForegroundColor Yellow
Write-Host " Target Mainframe: $TargetHost : $Port" -ForegroundColor Green
Write-Host " Local Proxy Port: 127.0.0.1:3271 (for BlueZone)" -ForegroundColor Green
Write-Host " MCP API Server:   127.0.0.1:31337 (for Claude/AI)" -ForegroundColor Green
Write-Host " Session Name:     $Session" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Once the hack3270 GUI appears:"
Write-Host "1. In BlueZone, open the 'hack3270' session profile (connects to 127.0.0.1:3271)"
Write-Host "2. In hack3270 GUI, click 'Continue' when connection is detected"
Write-Host "3. In Claude, ask to read the screen, analyze fields, or send commands!"
Write-Host "----------------------------------------------------------"

python $Hack3270Py $TargetHost $Port -n $Session
