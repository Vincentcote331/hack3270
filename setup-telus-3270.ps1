<#
.SYNOPSIS
    Automated Setup for hack3270 + Claude Code + BlueZone at TELUS.

.DESCRIPTION
    Configures everything in one step:
    1. Installs Python dependencies (PySide6, mcp<2 pinned for FastMCP compatibility).
    2. Installs Claude Code skills (hack3270, hack3270-mcp-tutorial, tn3270-pentest) to ~/.claude/skills/.
    3. Registers the hack3270 MCP server in Claude Code (user scope).
    4. Configures BlueZone Session Manager with a 'hack3270' profile pointing to 127.0.0.1:3271.
    5. Tests TELUS mainframe network reachability (TQC1, sys2).
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  TELUS Mainframe (3270) + Claude Code Automation Setup" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

New-Item -ItemType Directory -Force -Path (Join-Path $ScriptDir "sessions") | Out-Null
# -------------------------------------------------------------
# 1. Check Python
# -------------------------------------------------------------
Write-Host "`n[1/5] Checking Python environment..." -ForegroundColor White
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Error "Python not found on PATH. Please install Python 3.10+ and re-run."
}
$pyVersion = & python --version 2>&1
Write-Host "  Found: $pyVersion" -ForegroundColor Green

# -------------------------------------------------------------
# 2. Install Dependencies
# -------------------------------------------------------------
Write-Host "`n[2/5] Installing Python packages (PySide6, mcp<2)..." -ForegroundColor White
$reqPath = Join-Path $ScriptDir "requirements.txt"
& python -m pip install -r $reqPath --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Pip install had warnings or errors. Retrying with verbose output..."
    & python -m pip install -r $reqPath
}
Write-Host "  Python packages installed successfully." -ForegroundColor Green

# -------------------------------------------------------------
# 3. Install Claude Code Skills
# -------------------------------------------------------------
Write-Host "`n[3/5] Installing Claude Code skills..." -ForegroundColor White
$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
New-Item -ItemType Directory -Force -Path $ClaudeSkillsDir | Out-Null

$SkillsConfig = @(
    @{
        Dir = "hack3270"
        File = "hack3270.md"
        Name = "hack3270"
        Desc = "Guardrailed mainframe application interaction and testing via hack3270 MCP tools. Use when working with CICS, TSO, or 3270 mainframe applications."
    },
    @{
        Dir = "hack3270-mcp-tutorial"
        File = "hack3270-mcp-tutorial.md"
        Name = "hack3270-mcp-tutorial"
        Desc = "Complete tutorial for AI assistants on using hack3270 MCP tools. Covers all 53 tools with screen geometry, AID keys, and 3270 protocol reference."
    },
    @{
        Dir = "tn3270-pentest"
        File = "tn3270-pentest.md"
        Name = "tn3270-pentest"
        Desc = "Comprehensive mainframe technical knowledge base covering TN3270 protocol, CICS system transactions, TSO, JCL, and abend codes."
    }
)

foreach ($cfg in $SkillsConfig) {
    $targetDir = Join-Path $ClaudeSkillsDir $cfg.Dir
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    $srcFile = Join-Path $ScriptDir "skills\$($cfg.File)"
    if (Test-Path $srcFile) {
        $body = Get-Content $srcFile -Raw -Encoding UTF8
        $frontmatter = @"
---
name: $($cfg.Name)
description: $($cfg.Desc)
user-invocable: true
---

"@
        Set-Content -Path (Join-Path $targetDir "SKILL.md") -Value ($frontmatter + $body) -Encoding UTF8
        Write-Host "  Installed skill: $($cfg.Name)" -ForegroundColor Green
    }
}

# -------------------------------------------------------------
# 4. Register MCP Server in Claude Code
# -------------------------------------------------------------
Write-Host "`n[4/5] Registering hack3270 MCP server in Claude Code..." -ForegroundColor White
$claude = Get-Command claude -ErrorAction SilentlyContinue
if ($claude) {
    $mcpScript = Join-Path $ScriptDir "MCPs\hack3270_mcp\hack3270_mcp.py"
    & claude mcp add -s user hack3270 python $mcpScript | Out-Null
    Write-Host "  MCP Server 'hack3270' registered in user scope." -ForegroundColor Green
} else {
    Write-Warning "Claude CLI not found on PATH. If using Cursor or VS Code, .mcp.json is already configured."
}

# -------------------------------------------------------------
# 5. Configure BlueZone Profile
# -------------------------------------------------------------
Write-Host "`n[5/5] Configuring BlueZone Session Manager..." -ForegroundColor White
$BzConfigDir = "C:\ProgramData\BlueZone\6.2\Config"

if (Test-Path $BzConfigDir) {
    $bundledZmd = Join-Path $ScriptDir "bluezone\hack3270.zmd"
    $destBz = Join-Path $BzConfigDir "hack3270.zmd"
    if (Test-Path $bundledZmd) {
        Copy-Item -Path $bundledZmd -Destination $destBz -Force
        Write-Host "  Installed bundled BlueZone profile to: $destBz" -ForegroundColor Green
    } else {
        $template = Join-Path $BzConfigDir "TQC1.zmd"
        if (-not (Test-Path $template)) {
            $template = Join-Path $BzConfigDir "cics2.zmd"
        }
        if (Test-Path $template) {
            $content = Get-Content $template -Raw -Encoding Default
            $content = $content -replace 'Connection Name=".*?"', 'Connection Name="hack3270"'
            $content = $content -replace 'Host Address=".*?"', 'Host Address="127.0.0.1"'
            $content = $content -replace 'TCP Port=0x[0-9A-Fa-f]+', 'TCP Port=0x0CC7'
            Set-Content -Path $destBz -Value $content -Encoding Default
            Write-Host "  Configured BlueZone profile at: $destBz" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  BlueZone ProgramData not found, skipping BlueZone profile registration." -ForegroundColor Yellow
}

# -------------------------------------------------------------
# Network Check
# -------------------------------------------------------------
Write-Host "`nTesting connectivity to TELUS mainframe gateways..." -ForegroundColor White
foreach ($h in @("TQC1.TSL.TELUS.COM", "sys2tcp.tsl.telus.com")) {
    $tcp = Test-NetConnection -ComputerName $h -Port 23 -WarningAction SilentlyContinue
    if ($tcp.TcpTestSucceeded) {
        Write-Host "  [OK] Reachable: $h : 23" -ForegroundColor Green
    } else {
        Write-Warning "  [FAIL] Cannot reach $h:23. Verify VPN or TELUS network connection."
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  Setup Complete! How to use:" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "1. Start the proxy:" -ForegroundColor Yellow
Write-Host "   .\launch-hack3270.ps1 -Target tqc1 -Session my_session"
Write-Host "   (or use -Target sys2 / bct1 / bct2 / sys1)"
Write-Host "`n2. Open BlueZone Session Manager:" -ForegroundColor Yellow
Write-Host "   Double-click 'hack3270' -> click 'Continue' on the hack3270 dialog."
Write-Host "`n3. In Claude Code:" -ForegroundColor Yellow
Write-Host "   Ask: 'Show me my mainframe screen' or 'Select option 16'."
Write-Host "============================================================`n" -ForegroundColor Cyan
