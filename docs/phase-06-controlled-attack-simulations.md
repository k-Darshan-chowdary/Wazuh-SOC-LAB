# Phase 6 — Controlled Attack Simulations

**Completed:** 2026-09-06
**Goal:** run controlled attacker activity from Kali against the Windows lab endpoint (never the host), then measure what Wazuh detects out of the box and what it misses.

> **Source of this write-up:** the milestone snapshot notes plus the actual command history recovered from the Kali and Windows VMs. Only screenshots are still missing (marked 📝).

## Safety boundary

All activity was Kali (10.10.10.30) → WIN-ENDPOINT-01 (10.10.10.20) on the isolated SOC-LAB segment, following the [Phase 0 rules](phase-00-architecture-and-safety.md). Any temporary SMB or firewall rules, test files and persistence artifacts were **removed after testing**.

## Simulations performed

| # | Activity | ATT&CK (for reference) | Telemetry source |
|---|---|---|---|
| 1 | Controlled network reconnaissance | T1046 Network Service Discovery | Windows Filtering Platform |
| 2 | SMB authentication attempts | T1110 Brute Force | Windows Security |
| 3 | Repeated failed logins | T1110 Brute Force | Windows Security |
| 4 | PowerShell download activity | T1059.001 PowerShell / T1105 Ingress Tool Transfer | Sysmon Event 1 |
| 5 | Base64-encoded PowerShell execution | T1059.001 / T1027 Obfuscated Files or Information | Sysmon Event 1 |
| 6 | Scheduled-task persistence simulation | T1053.005 Scheduled Task | Sysmon Event 1 |

Sysmon and Windows Security telemetry was verified for the simulations.

**Attacker side (Kali VM, 10.10.10.30):** controlled **Nmap** reconnaissance, **SMB authentication** attempts, and a temporary **HTTP test server** that served the file for the PowerShell download test. All were aimed at WIN-ENDPOINT-01 only. Temporary test files and services were cleaned up afterwards (snapshot `Phase-6-Attacker-Ready`).

## Results: detected vs. gaps

**Detected by default Wazuh rules ✅**
- Remote failed authentication
- Nested PowerShell (PowerShell spawning PowerShell)
- Base64-encoded PowerShell

**Detection gaps found ❌**

| Gap | Why it mattered |
|---|---|
| No correlation of **repeated** failed authentication | Single failures alerted, but a password-guessing burst wasn't treated as one higher-severity pattern |
| **Windows Filtering Platform Event 5157** (blocked connection) not ingested | Port-scan reconnaissance against the firewall left no usable signal in Wazuh |
| **Scheduled-task persistence** not detected | `schtasks /Create` persistence passed without a specific alert |

> Measuring gaps was the point of this phase. Each one became a custom detection in [Phase 7](phase-07-detection-engineering.md).

## Commands used

### Attacker (Kali, 10.10.10.30)

```bash
# Reconnaissance (connect and SYN scans)
nmap -sT -Pn -p 135,139,445,3389 10.10.10.20
sudo nmap -sS -Pn -T5 --max-retries 0 -p 135,139,445,3389,5985,5986 10.10.10.20

# SMB authentication attempts (fake account → failed logons)
smbclient -L //10.10.10.20 -U SOC-FAKE

# HTTP test server (serves the file for the PowerShell download test)
mkdir -p ~/soc-share && echo "SOC LAB SAFE TEST FILE" > ~/soc-share/soc-test.txt
cd ~/soc-share && python3 -m http.server 8000 --bind 10.10.10.30
```

### Endpoint (WIN-ENDPOINT-01)

```powershell
# Temporary SMB exposure so failed logons from Kali reach the endpoint
New-NetFirewallRule -DisplayName "SOC-LAB TEMP SMB from Kali" -Direction Inbound `
  -Protocol TCP -LocalPort 445 -RemoteAddress 10.10.10.30 -Action Allow

# PowerShell download from the Kali HTTP server
powershell.exe -NoProfile -Command "Invoke-WebRequest -Uri 'http://10.10.10.30:8000/soc-test.txt' -OutFile 'C:\Users\Public\soc-test.txt'"

# Base64-encoded PowerShell
$cmd = 'Write-Output "SOC ENCODED TEST"'
$encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cmd))
powershell.exe -NoProfile -EncodedCommand $encoded

# Scheduled-task persistence
schtasks /Create /TN "SOC-LAB-PERSIST-TEST" `
  /TR "cmd.exe /c echo SOC-PERSIST-TEST > C:\Users\Public\soc-persist.txt" /SC ONLOGON /F
```

Each step was verified with a matching Sysmon Event 1 / Security query (e.g. filtering on `soc-test.txt`, `EncodedCommand`, or `schtasks.exe`).

### Cleanup (run afterwards)

```powershell
Remove-NetFirewallRule -DisplayName "SOC-LAB TEMP SMB from Kali"
schtasks /Delete /TN "SOC-LAB-PERSIST-TEST" /F
Remove-Item "C:\Users\Public\soc-test.txt","C:\Users\Public\soc-persist.txt" -Force -ErrorAction SilentlyContinue
```

## 📝 Still to add

- [ ] Screenshots of the alerts that fired (failed auth, nested and encoded PowerShell)
- [ ] Screenshot of a detection gap (e.g. Threat Hunting with no result for the port scan)

## Outcome

- ✅ Six controlled techniques executed safely inside the lab
- ✅ Default detections confirmed for failed auth and malicious PowerShell patterns
- ✅ Three detection gaps documented → input for Phase 7
- ✅ Temporary rules, files and persistence artifacts cleaned up
- 📸 Snapshots: `Phase-6-Controlled-Attack-Simulations-Complete` (both VMs)
