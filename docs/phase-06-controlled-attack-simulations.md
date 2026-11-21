# Phase 6 — Controlled Attack Simulations

**Completed:** 2026-09-06
**Goal:** run controlled attacker activity from Kali against the Windows lab endpoint (never the host), then measure what Wazuh detects out of the box and what it misses.

> **Source of this write-up:** the milestone snapshot notes I recorded on both VMs at the end of the phase. Exact commands and screenshots weren't saved locally, so the sections marked 📝 are open for me to fill in.

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

## 📝 To add

- [ ] Kali commands/tools used for each simulation
- [ ] Screenshots of the alerts that fired (failed auth, nested and encoded PowerShell)
- [ ] Evidence for each gap (e.g. Threat Hunting with no result)
- [ ] Cleanup checklist that was run afterwards

## Outcome

- ✅ Six controlled techniques executed safely inside the lab
- ✅ Default detections confirmed for failed auth and malicious PowerShell patterns
- ✅ Three detection gaps documented → input for Phase 7
- ✅ Temporary rules, files and persistence artifacts cleaned up
- 📸 Snapshots: `Phase-6-Controlled-Attack-Simulations-Complete` (both VMs)
