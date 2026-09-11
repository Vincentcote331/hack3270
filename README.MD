# hack3270 — TELUS Edition

> **AI-Assisted Mainframe (3270) Interaction for Claude Code & Rocket BlueZone**  
> Connect Claude Code directly to TELUS mainframes (TQC1, CRIS, TOPS, CICS, TSO, ISMMF2) to read screens, extract reports to CSV, inspect fields, navigate menus, and automate batch workflows.

---

## ⚡ Quickstart Setup

### 🚀 First-Time Setup (1-Liner in PowerShell)
A brand-new user does **not** need git installed, does **not** need to download skills manually, and does **not** need to clone beforehand. Just paste this into PowerShell:

```powershell
irm https://raw.githubusercontent.com/Vincentcote331/hack3270/main/setup.ps1 | iex
```

*This script bootstraps everything: clones the repository into `C:\dev\tools\hack3270`, installs Python packages, registers the MCP server in Claude Code, installs the Claude skills, and configures BlueZone.*

---

### 🔄 After Setup: Re-verification & Updates from Claude
Once the setup script has run once on the machine, the skills are permanently active in Claude Code. You can then:
* **Update / Re-verify**: Ask Claude `"/hack3270-setup"` to pull latest changes and verify dependencies.
* **Connect**: Simply ask Claude *"Can you use TQC1?"* or *"Can you use ISMMF2?"*.

---

### What the setup script does automatically:
1. Installs Python dependencies (with `mcp<2` pinned for FastMCP compatibility).
2. Installs 3 mainframe skills (`hack3270`, `hack3270-mcp-tutorial`, `tn3270-pentest`) into your `~/.claude/skills/`.
3. Registers the `hack3270` MCP server globally in Claude Code (`claude mcp list` will show `hack3270: √ Connected`).
4. Injects a pre-configured **`hack3270`** profile into **BlueZone Session Manager** (`C:\ProgramData\BlueZone\6.2\Config\hack3270.zmd`).
5. Tests network connectivity to TELUS mainframe gateways.

---

## 🔌 How to Connect

### Option A: Just Ask Claude!
Once set up, open Claude Code in any directory and type:
> *"Can you use TQC1?"*  
> *(or "Can you use ISMMF2?", "Switch to CRIS", "Connect to TOPS")*

Claude will automatically start the proxy for that target environment.

### Option B: From PowerShell
```powershell
# For TQC1:
.\launch-hack3270.ps1 -Target tqc1

# For CRIS / ISMMF2:
.\launch-hack3270.ps1 -Target ismmf2

# For TOPS / CRIS BC:
.\launch-hack3270.ps1 -Target tops
```

### Then in BlueZone:
1. Open **BlueZone Session Manager**.
2. Double-click the **`hack3270`** session (it connects to `127.0.0.1:3271`).
3. On the hack3270 GUI pop-up, click **Continue**.
4. Your mainframe screen appears in BlueZone!

---

## 🏢 Supported TELUS Mainframe Environments

All target shortcuts are built-in and automatically map to their respective host and port:

| Shortcut | Target Environment | Host Gateway | Port |
|---|---|---|---|
| **`tqc1`** | **TQC1** (TELUS Quebec Mainframe) | `TQC1.TSL.TELUS.COM` | 23 |
| **`ismmf2`** | **ISMMF2** (Corporate / Alberta Sys2) | `sys2tcp.tsl.telus.com` | 23 |
| **`cris`** / **`cris_ab`** | **CRIS Alberta** | `sys2tcp.tsl.telus.com` | 23 |
| **`cris_bc`** | **CRIS British Columbia** | `bct1tcp2.tsl.telus.com` | 23 |
| **`tops`** | **TOPS** | `bct1tcp2.tsl.telus.com` | 23 |
| **`cics`** / **`cics2`** | **CICS 2** | `sys2tcp.tsl.telus.com` | 23 |
| **`tpx_ab`** | **TPX Alberta** | `sys1tcp.tsl.telus.com` | 23 |
| **`tpx_bc`** | **TPX British Columbia** | `bct1tcp.tsl.telus.com` | 23 |
| **`tpxism`** | **TPX ISM** | `ism1tcpm.tsl.telus.com` | 23 |
| **`dsr`** | **DSR** | `sys2tcp.tsl.telus.com` | 23 |
| **`ects`** | **ECTS** | `sys2tcp.tsl.telus.com` | 23 |
| **`fms`** | **FMS** | `bct1tcp2.tsl.telus.com` | 23 |
| **`tas`** | **Tas** | `bct1tcp2.tsl.telus.com` | 23 |
| **`trihs`** | **Trihs** | `bct1tcp2.tsl.telus.com` | 23 |
| **`drptpx`** | **DRP TPX** | `drptpx.tsl.telus.com` | 23 |

*(You can also pass any custom IP/host: `.\launch-hack3270.ps1 -Target myhost.telus.com`)*

---

## 💬 What You Can Tell Claude To Do

Once connected, you can interact naturally from Claude Code:

### 1. View & Inspect Screens
* *"Show me what is on the mainframe screen right now."*
* *"Analyze all fields on this screen — are there any hidden or editable fields?"*
* *"Find the account number starting with 8734 on the screen."*

### 2. Scrape Multi-Page Data into CSV / Markdown
* *"Page down through this report using PF8, scrape all pages, and write them into a CSV file."*
* *"Extract the table on this screen into a Markdown table."*

### 3. Navigate & Send Keystrokes
* *"Type 16 into the selection field and press Enter."*
* *"Press PF3 to exit back to the previous menu."*
* *"Send the CLEAR key, then type transaction MCGM."*

### 4. Job & Batch Workflows (SAS Decom, TSO, JCL)
* *"Read the JCL member in this PDS and download it to my local folder."*
* *"Submit this job with SUB, switch to SDSF, and tell me if it finished with RC=0000 or abended."*
* *"Analyze this SAS macro and help me translate it into Python / PySpark."*

---

## 🏗️ Architecture

```
                                [hack3270_mcp.py] <--TCP:31337--> [hack3270 Proxy] <--TN3270--> [TELUS Mainframe]
                                    (53 tools)                     (localhost:3271)              (TQC1 / sys2 / bct1)
                                        ^                                ^
[Claude Code] <---stdio/JSON-RPC--------|                                |
                                                                [BlueZone Terminal]
                                                              (Session: hack3270)
```

- **You** keep your familiar BlueZone emulator open and view the screens as you normally do.
- **Claude** sees the same screen data programmatically via the MCP tools.
- **hack3270** acts as the local MITM proxy between BlueZone and the mainframe gateway.
- Every packet exchanged is logged locally in `sessions/telus_<target>.db` for full audit and replay.

---

## 🔧 Troubleshooting

### 1. `hack3270` doesn't show up in BlueZone Session Manager
BlueZone Session Manager reads profiles from `C:\ProgramData\BlueZone\6.2\Config\`.
- Press **F5** or go to **View > Refresh** in Session Manager.
- If still missing, re-run `powershell -ExecutionPolicy Bypass -File .\setup-telus-3270.ps1`.

### 2. `Error: IP address mismatch with existing project '...'`
hack3270 ensures session databases aren't mixed between different mainframes.
The new `switch-target.py` launcher prevents this automatically by isolating databases into `sessions/telus_<target>.db`.

### 3. MCP server disconnected in Claude
In Claude Code, type:
> *"Reconnect to the hack3270 API using reconnect_api."*
Make sure hack3270 is running and you have clicked **Continue** on the connection pop-up.

---

## 📚 Repository Structure

* `setup-telus-3270.ps1` — 1-click installer for TELUS workstations.
* `launch-hack3270.ps1` — Convenience launcher wrapping `switch-target.py`.
* `switch-target.py` — Target switcher managing background proxy processes and isolated session databases.
* `TELUS_TUTORIAL.md` — Detailed step-by-step tutorial and reference guide.
* `bluezone/hack3270.zmd` — Bundled BlueZone 3270 profile configured for `127.0.0.1:3271`.
* `MCPs/hack3270_mcp/` — FastMCP server exposing 53 tools over stdio.
* `hack3270.py` — The core TN3270 MITM proxy application.
* `hackterm-core/` — Headless proxy daemon and EBCDIC codecs.
* `skills/` — Mainframe knowledge base skills (`hack3270`, `hack3270-mcp-tutorial`, `tn3270-pentest`).

---

## 📄 License & Upstream

Forked from [gglessner/hack3270](https://github.com/gglessner/hack3270) under the GNU General Public License v3.0.
Upstream Authors: Garland Glessner, Phil Young (Soldier of FORTRAN).
TELUS Edition additions: Automated 1-click BlueZone installer, TELUS gateway target switcher, and Claude Code skill integration.
