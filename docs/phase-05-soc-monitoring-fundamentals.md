# Phase 5 — SOC Monitoring Fundamentals

**Completed:** 2026-09-04
**Goal:** practice the Tier 1 analyst loop on real lab telemetry (triage, process investigation, timelines, hashes, parent-child reasoning) before any attack simulation.

> **Source of this write-up:** the milestone snapshot notes plus the actual command history recovered from WIN-ENDPOINT-01. Only screenshots are still missing (marked 📝).

## What was done

- Confirmed a stable baseline: Windows agent **active**, alerts and telemetry flowing, Sysmon process telemetry working.
- **Failed authentication activity** was generated and investigated through Windows Security events in Wazuh.
- **Sysmon process-creation events** were investigated, including **PowerShell activity and SHA256 hash analysis**.
- **Timelines were correlated** across authentication and process events.
- A complete **SOC triage workflow** was practiced end-to-end: alert → evidence → context → verdict.

## Analyst workflow practiced

```
Alert surfaces  →  read rule.id / rule.level / description
                →  open the raw event (Windows Security or Sysmon)
                →  who? (subject/user)  what? (image, command line, hash)
                   from where? (parent process, source IP)  when? (timeline)
                →  correlate related events into one timeline
                →  classify: benign / authorized true positive / suspicious → escalate
```

Key reasoning carried over from Phase 4: a process name alone is weak evidence. The **parent-child chain, the command line and the hash** decide whether activity is normal.

## Commands used (WIN-ENDPOINT-01)

**Failed-logon investigation (Event ID 4625)**
```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=(Get-Date).AddMinutes(-10)} |
  Select-Object -First 3 | Format-List TimeCreated,Id,Message
```

**Process investigation (Sysmon Event 1, PowerShell)**
```powershell
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Sysmon/Operational'; Id=1; StartTime=(Get-Date).AddMinutes(-10)} |
  Where-Object { $_.Message -match 'powershell.exe' } |
  Select-Object -First 3 | Format-List TimeCreated,Id,Message
```

**Hash analysis** — take the SHA256 from a process event and confirm it against the on-disk binary:
```powershell
Get-FileHash "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Algorithm SHA256
```

**Timeline correlation** — merge Security and Sysmon events into one time-ordered view:
```powershell
$Start = (Get-Date).AddHours(-2)
$SecurityEvents = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625,4720,4726; StartTime=$Start}
$SysmonEvents = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Sysmon/Operational'; Id=1; StartTime=$Start} |
  Where-Object { $_.Message -match 'powershell.exe' }
($SecurityEvents + $SysmonEvents) | Sort-Object TimeCreated |
  Select-Object TimeCreated,Id,ProviderName | Format-Table -AutoSize
```

## 📝 Still to add

- [ ] Screenshots of the investigations above in the Wazuh dashboard
- [ ] Triage verdicts recorded for each investigated alert

## Outcome

- ✅ Windows agent connected, Sysmon telemetry verified
- ✅ Authentication and process-creation events investigated
- ✅ PowerShell and hash analysis completed
- ✅ Timelines correlated; SOC triage workflow completed
- 📸 Snapshots: `Phase-5-SOC-Monitoring-Complete` (WAZUH-SERVER and WIN-ENDPOINT-01)
