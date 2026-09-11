# Using Claude Code with TELUS Mainframe (3270) via BlueZone & hack3270

A guide for TELUS engineers to connect Claude Code (or Cursor / VS Code) directly to TELUS mainframes (TQC1, CRIS, TOPS, CICS, TSO) using Rocket BlueZone and the `hack3270` MCP bridge.

---

## 1. What This Gives You

With this setup, your AI assistant can:
- **Read your live 3270 screen** in real time (`get_screen`).
- **Scrape multi-page mainframe tables** (e.g. from TSO, Dataquery, CICS) into clean CSV, JSON, or Markdown tables.
- **Navigate and send keys programmatically** (Enter, PF keys, PA keys, Clear).
- **Find text, fields, and labels** (`find_text`, `find_field_value`).
- **Inspect hidden or protected fields** on screen.
- **Log every packet** locally into a SQLite database for audit, session replay, and offline review.

---

## 2. Architecture

```
[Claude Code / AI] <---stdio/JSON-RPC---> [hack3270_mcp.py]
                                                |
                                            TCP:31337
                                                v
[BlueZone Mainframe Display] <---TN3270---> [hack3270 Proxy] <---TN3270---> [TELUS Mainframe]
       (Client UI)                        (localhost:3271)                  (TQC1 / sys2 / bct1)
```

- **You** keep your standard BlueZone terminal open and see the screens normally.
- **Claude** sees the same screen data programmatically via 53 MCP tools.
- **hack3270** acts as the local bridge between BlueZone and the TELUS mainframe gateway.

---

## 3. Quick Setup (1-Step)

Clone this repo into `C:\dev\tools\hack3270` and run the setup script:

```powershell
cd C:\dev\tools\hack3270
powershell -ExecutionPolicy Bypass -File .\setup-telus-3270.ps1
```

The script automatically:
1. Installs Python packages (`PySide6`, and pins `mcp<2` for FastMCP compatibility).
2. Installs 3 mainframe skills (`hack3270`, `hack3270-mcp-tutorial`, `tn3270-pentest`) into `~/.claude/skills/`.
3. Registers the `hack3270` MCP server globally in Claude Code (`claude mcp add -s user ...`).
4. Configures a **`hack3270`** session profile in **BlueZone Session Manager** pre-configured for `127.0.0.1:3271`.
5. Verifies network connectivity to TELUS mainframe gateways.

---

## 4. How to Connect

### Step 1: Start the Proxy
In your terminal, start the proxy targeting your desired mainframe:

```powershell
# For TQC1 (default for TELUS Quebec):
.\launch-hack3270.ps1 -Target tqc1 -Session my_session

# For CRIS / sys2:
.\launch-hack3270.ps1 -Target sys2 -Session my_session

# For CRIS BC / TOPS (bct1tcp2):
.\launch-hack3270.ps1 -Target bct2 -Session my_session

# For TPX AB (sys1tcp):
.\launch-hack3270.ps1 -Target sys1 -Session my_session
```

A small hack3270 dialog will pop up stating: `Waiting for TN3270 connection on 127.0.0.1:3271`.

### Step 2: Open BlueZone
1. Open **BlueZone Session Manager**.
2. Double-click the **`hack3270`** profile in your session list.
3. On the hack3270 pop-up window, click **Continue**.
4. Your mainframe screen appears in BlueZone!

### Step 3: Ask Claude!
In Claude Code, you can now interact directly:
- *"Show me my current mainframe screen."*
- *"What options are displayed on the menu?"*
- *"Type 16 into the selection field and press Enter."*
- *"Extract this entire report into a CSV file."*

---

## 5. Example Prompts

| What you want | What to say to Claude |
|---|---|
| **View screen** | *"Read the mainframe screen and show me what's currently displayed."* |
| **Inspect fields** | *"Analyze all input and protected fields on this screen."* |
| **Navigate** | *"Select option 1 and send Enter."* or *"Press PF3 to exit."* |
| **Scrape data** | *"Page down through this report using PF8, grab each page, and save all rows to a CSV file."* |
| **Find values** | *"Search the screen for any occurrence of account 12345678."* |
| **Check abends** | *"Did that last transaction cause any abend or error code?"* |

---

## 6. Troubleshooting

### 1. `Error: IP address mismatch with existing project '...'`
Each session name records the target IP/host in `<session_name>.db`. If you previously ran against `sys2` and now run against `tqc1` with the same session name:
* Either use a new session name: `-Session tqc1_test`
* Or delete the old database file: `Remove-Item sas_decom*.db`

### 2. BlueZone doesn't show `hack3270` in Session Manager
BlueZone Session Manager reads profiles from `C:\ProgramData\BlueZone\6.2\Config\`.
Re-run `setup-telus-3270.ps1` or press **F5** in Session Manager to refresh the list.

### 3. MCP server shows broken pipe or disconnected
In Claude Code, you can ask:
*"Reconnect to the hack3270 API using reconnect_api."*
Or verify that hack3270 is running and the proxy dialog has been clicked with **Continue**.

---

## 7. Available Tools Reference (53 Tools)

* **Screen**: `get_screen`, `get_screen_raw`, `find_text`, `find_field_value`, `get_text_at`
* **Fields**: `analyze_screen_fields`, `get_input_fields`, `get_hidden_fields`, `check_abend`
* **Input / Keys**: `send_enter`, `send_aid_key`, `send_pf_key`, `send_clear`, `send_field_data`, `send_command`
* **Synchronization**: `wait_for_text`, `wait_for_screen_change`
* **Database & Logs**: `get_logs`, `get_log_entry`, `replay_sequence`
* **Wordlists & Fuzzing**: `load_wordlist`, `fuzz_field`, `fuzz_transaction_codes`
