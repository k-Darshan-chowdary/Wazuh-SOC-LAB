# Phase 3 — Windows Monitoring & First Investigations

**Goal:** enroll WIN-ENDPOINT-01, prove the agent channel, learn Threat Hunting, and complete the first two controlled investigations.

## Agent enrollment

| Field | Value |
|---|---|
| Endpoint | WIN-ENDPOINT-01 (Windows 11 Pro, 10.10.10.20) |
| Agent | Wazuh Agent 4.14.7 |
| Agent ID | 001 · group `default` · **Active** |
| Channel | TCP 1514 → 10.10.10.10 |

Enrollment is more than installing software. It ties a named endpoint to a specific manager, creates an agent identity, and sets up the telemetry path.

```powershell
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.7-1.msi `
  -OutFile $env:tmp\wazuh-agent
msiexec.exe /i $env:tmp\wazuh-agent /q `
  WAZUH_MANAGER='10.10.10.10' WAZUH_AGENT_NAME='WIN-ENDPOINT-01'
```

## Proving the channel

```powershell
Get-Service WazuhSvc; Start-Service WazuhSvc
Test-NetConnection 10.10.10.10 -Port 1514   # TcpTestSucceeded = True
```

| Port | Purpose |
|---|---|
| 443/TCP | Humans → dashboard |
| 1514/TCP | Agents → manager |

A successful ping proves neither.

## First look at Threat Hunting: onboarding noise

The new endpoint produced **~485–489 hits** from inventory, service state, SCA (CIS benchmark) checks and normal Windows activity. A Level 9 SCA alert did **not** mean compromise.

How to read an event: filter `agent.name: WIN-ENDPOINT-01`, set a sensible time window, open the details, and check `rule.id`, `rule.level`, `rule.description`, `data.win.system.eventID`, channel, provider, and timestamp.

## Windows Event ID vs. Wazuh Rule ID

| Windows Event | Meaning | Wazuh Rule | Interpretation |
|---|---|---|---|
| 7040 | Service startup changed | 61104 (L3) | Service startup type changed |
| 4720 | User account created | 60109 (L8) | User enabled or created |
| 4726 | User account deleted | 60111 (L8) | User disabled or deleted |

The SIEM adds interpretation without changing the source event.

## Investigations

- [Case 01: Local account created (4720)](../investigations/case-01-account-created-4720.md)
- [Case 02: Local account deleted (4726)](../investigations/case-02-account-deleted-4726.md)

**Timeline**
```
12:53  SOC-LAB-TEST created → 4720 → Rule 60109 (L8) → T1098 Persistence
13:24  SOC-LAB-TEST deleted → 4726 → Rule 60111 (L8) → T1098 + T1531
```

**Lesson:** correlation, not row counting.

## Outcome

- ✅ Agent installed and Active; TCP 1514 verified
- ✅ Security / System / Application telemetry received
- ✅ Raw source events validated before reading Wazuh's interpretation
- ✅ Two controlled detections investigated and classified
- 📸 Snapshot: `Wazuh-SIEM-With-Windows-Agent`
