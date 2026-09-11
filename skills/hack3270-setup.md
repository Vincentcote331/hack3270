# hack3270 Automated Setup Skill

Automatically installs, configures, and verifies the hack3270 mainframe environment for TELUS engineers.

## Workflow

When the user asks to setup, install, or repair hack3270 (e.g. `/hack3270:setup`, `/skill:hack3270:setup`, `"setup hack3270"`, `"install mainframe tools"`):

### Phase 1: Check / Clone Repository
1. Check if `C:\dev\tools\hack3270` exists.
2. If it does NOT exist:
   ```powershell
   New-Item -ItemType Directory -Force -Path "C:\dev\tools" | Out-Null
   git clone https://github.com/Vincentcote331/hack3270.git "C:\dev\tools\hack3270"
   ```
3. If it already exists:
   ```powershell
   git -C "C:\dev\tools\hack3270" pull
   ```

### Phase 2: Run Setup Script
Execute the 1-click installer:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\dev\tools\hack3270\setup-telus-3270.ps1"
```

This automatically:
- Installs Python dependencies (`PySide6`, `mcp<2`).
- Installs Claude Code skills (`hack3270`, `hack3270-mcp-tutorial`, `tn3270-pentest`, `hack3270-setup`).
- Registers the `hack3270` MCP server globally (`claude mcp add -s user`).
- Installs the BlueZone profile `hack3270.zmd` into `C:\ProgramData\BlueZone\6.2\Config\`.
- Verifies TELUS mainframe network reachability (`TQC1`, `sys2`).

### Phase 3: Verify & Report Status
1. Check `claude mcp list` to ensure `hack3270` is connected.
2. Confirm BlueZone profile exists at `C:\ProgramData\BlueZone\6.2\Config\hack3270.zmd`.
3. Report to the user:
   - Setup status (green checkmarks).
   - How to connect: `"Ask me 'Can you use TQC1?' to start the proxy, then open 'hack3270' in BlueZone Session Manager."`
