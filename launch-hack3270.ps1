<#
.SYNOPSIS
    Convenience launcher for hack3270 proxy with TELUS mainframe targets.

.DESCRIPTION
    Switches and starts the hack3270 proxy in the background for a specific TELUS mainframe.
    Handles stopping any previous proxy and creating isolated session databases.

.PARAMETER Target
    Target shortcut: tqc1 (default), ismmf2, cris, cris_bc, tops, cics2, tpx_ab, tpx_bc, etc.

.PARAMETER BlueZone
    Optionally launches BlueZone Mainframe Display with the 'hack3270' profile automatically.
#>
param(
    [string]$Target = "tqc1",
    [switch]$BlueZone
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SwitchPy = Join-Path $ScriptDir "switch-target.py"

if ($BlueZone) {
    python $SwitchPy $Target --bluezone
} else {
    python $SwitchPy $Target
}
