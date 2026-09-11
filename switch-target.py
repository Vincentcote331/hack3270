#!/usr/bin/env python3
"""
TELUS Mainframe Target Switcher for hack3270

Allows instant switching between TELUS mainframe environments (TQC1, ISMMF2, CRIS, TOPS, etc.)
Handles process termination, isolated session database management, and proxy launch.
"""

import sys
import os
import time
import subprocess
import argparse
import json

TELUS_TARGETS = {
    "tqc1": {"host": "TQC1.TSL.TELUS.COM", "port": 23, "desc": "TQC1 - TELUS Quebec Mainframe"},
    "ismmf2": {"host": "sys2tcp.tsl.telus.com", "port": 23, "desc": "ISMMF2 - Alberta/Corporate Sys2"},
    "cris_ab": {"host": "sys2tcp.tsl.telus.com", "port": 23, "desc": "CRIS Alberta (sys2)"},
    "cris": {"host": "sys2tcp.tsl.telus.com", "port": 23, "desc": "CRIS Alberta (sys2)"},
    "cris_bc": {"host": "bct1tcp2.tsl.telus.com", "port": 23, "desc": "CRIS BC (bct1tcp2)"},
    "cics": {"host": "sys2tcp.tsl.telus.com", "port": 23, "desc": "CICS 2 (sys2)"},
    "cics2": {"host": "sys2tcp.tsl.telus.com", "port": 23, "desc": "CICS 2 (sys2)"},
    "tops": {"host": "bct1tcp2.tsl.telus.com", "port": 23, "desc": "TOPS (bct1tcp2)"},
    "tpx_ab": {"host": "sys1tcp.tsl.telus.com", "port": 23, "desc": "TPX Alberta (sys1)"},
    "tpx_bc": {"host": "bct1tcp.tsl.telus.com", "port": 23, "desc": "TPX BC (bct1)"},
    "tpxism": {"host": "ism1tcpm.tsl.telus.com", "port": 23, "desc": "TPX ISM"},
    "dsr": {"host": "sys2tcp.tsl.telus.com", "port": 23, "desc": "DSR (sys2)"},
    "ects": {"host": "sys2tcp.tsl.telus.com", "port": 23, "desc": "ECTS (sys2)"},
    "fms": {"host": "bct1tcp2.tsl.telus.com", "port": 23, "desc": "FMS (bct1tcp2)"},
    "tas": {"host": "bct1tcp2.tsl.telus.com", "port": 23, "desc": "Tas (bct1tcp2)"},
    "trihs": {"host": "bct1tcp2.tsl.telus.com", "port": 23, "desc": "Trihs (bct1tcp2)"},
    "drptpx": {"host": "drptpx.tsl.telus.com", "port": 23, "desc": "DRP TPX"},
    "drptpxism": {"host": "drptpxism.tsl.telus.com", "port": 23, "desc": "DRP TPX ISM"},
    "drptpxpass": {"host": "drptpxpass.tsl.telus.com", "port": 23, "desc": "DRP TPX PASS"}
}

REPO_DIR = os.path.dirname(os.path.abspath(__file__))
SESSIONS_DIR = os.path.join(REPO_DIR, "sessions")
os.makedirs(SESSIONS_DIR, exist_ok=True)

def get_running_proxy_info():
    """Find running hack3270 proxy processes and their target info."""
    ps_cmd = 'Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match "hack3270\\.py" } | Select-Object ProcessId, CommandLine | ConvertTo-Json'
    try:
        res = subprocess.run(["powershell", "-NoProfile", "-Command", ps_cmd], capture_output=True, text=True)
        out = res.stdout.strip()
        if not out:
            return []
        data = json.loads(out)
        if isinstance(data, dict):
            data = [data]
        return data
    except Exception:
        return []

def stop_running_proxy():
    """Stop all running hack3270 processes."""
    running = get_running_proxy_info()
    for proc in running:
        pid = proc.get("ProcessId")
        if pid:
            try:
                subprocess.run(["powershell", "-NoProfile", "-Command", f"Stop-Process -Id {pid} -Force -ErrorAction SilentlyContinue"], check=False)
                print(f"Stopped previous hack3270 proxy (PID {pid}).")
            except Exception:
                pass
    time.sleep(0.5)

def resolve_target(target_arg):
    """Resolve target shortcut or hostname."""
    key = target_arg.lower().strip()
    if key in TELUS_TARGETS:
        return TELUS_TARGETS[key]["host"], TELUS_TARGETS[key]["port"], TELUS_TARGETS[key]["desc"], key
    # Check if host was given directly
    return target_arg, 23, f"Custom Host: {target_arg}", "custom"

def switch_target(target_name, launch_bz=False):
    host, port, desc, key = resolve_target(target_name)
    
    # Always stop old proxy to ensure a clean state and visible window
    running = get_running_proxy_info()
    if running:
        stop_running_proxy()

    # Launch hack3270 in background with isolated session name in sessions directory
    session_name = f"telus_{key}"
    session_db = os.path.join(SESSIONS_DIR, f"{session_name}.db")
    
    # If the db file already exists with a different target, remove it to prevent mismatch
    # (or let hack3270 handle it since session name is key-specific)
    hack_py = os.path.join(REPO_DIR, "hack3270.py")
    
    cmd = [
        sys.executable, hack_py,
        host, str(port),
        "-n", session_name
    ]
    
    # Run detached in background with log redirection so caller doesn't hang
    # and detached process doesn't crash from invalid stdout/stderr handles
    log_path = os.path.join(SESSIONS_DIR, f"{session_name}.log")
    log_file = open(log_path, "a", encoding="utf-8")
    DETACHED_PROCESS = 0x00000008
    CREATE_NEW_PROCESS_GROUP = 0x00000200
    subprocess.Popen(
        cmd,
        cwd=SESSIONS_DIR,
        creationflags=DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP,
        stdin=subprocess.DEVNULL,
        stdout=log_file,
        stderr=log_file
    )
    
    print(f"Started hack3270 targeting: {desc}")
    print(f"  Host: {host}:{port}")
    print(f"  Proxy Listening on: 127.0.0.1:3271")
    print(f"  MCP API on: 127.0.0.1:31337")
    print(f"  Session: {session_name}")
    print(f"")
    print(f"  👉 NEXT STEP: Open BlueZone Session Manager, connect 'hack3270', then click 'Click to Continue'.")
    # Check BlueZone
    if launch_bz:
        bz_profile = r"C:\ProgramData\BlueZone\6.2\Config\hack3270.zmd"
        bz_exe = r"C:\Program Files (x86)\BlueZone\6.2\bzmd.exe"
        if os.path.exists(bz_exe) and os.path.exists(bz_profile):
            subprocess.Popen([bz_exe, f"/f{bz_profile}"], close_fds=True)
            print("Launched BlueZone with 'hack3270' profile.")

    return {"status": "started", "target": key, "host": host, "port": port}

def list_targets():
    print("Available TELUS Mainframe Targets:")
    print("-" * 65)
    for k, v in sorted(TELUS_TARGETS.items()):
        print(f"  {k:<12} -> {v['desc']} ({v['host']}:{v['port']})")
    print("-" * 65)

def main():
    parser = argparse.ArgumentParser(description="Switch TELUS Mainframe Target for hack3270")
    parser.add_argument("target", nargs="?", help="Target name (e.g. TQC1, ISMMF2, CRIS, TOPS, CICS)")
    parser.add_argument("--list", action="store_true", help="List all available targets")
    parser.add_argument("--stop", action="store_true", help="Stop any running proxy")
    parser.add_argument("--status", action="store_true", help="Show current proxy status")
    parser.add_argument("--bluezone", action="store_true", help="Launch BlueZone with hack3270 profile")
    args = parser.parse_args()

    if args.list:
        list_targets()
        return

    if args.stop:
        stop_running_proxy()
        print("Proxy stopped.")
        return

    if args.status:
        running = get_running_proxy_info()
        if running:
            print(f"hack3270 is RUNNING (PID {running[0]['ProcessId']}):")
            print(f"  {running[0]['CommandLine']}")
        else:
            print("hack3270 is NOT running.")
        return

    if not args.target:
        list_targets()
        print("\nUsage: python switch-target.py <target> [--bluezone]")
        return

    switch_target(args.target, launch_bz=args.bluezone)

if __name__ == "__main__":
    main()
