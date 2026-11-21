# Phase 5 — SOC Monitoring Fundamentals

**Completed:** 2026-09-04
**Goal:** practice the Tier 1 analyst loop on real lab telemetry (triage, process investigation, timelines, hashes, parent-child reasoning) before any attack simulation.

> **Source of this write-up:** the milestone snapshot notes I recorded on both VMs at the end of the phase. Commands and screenshots from this phase weren't saved locally, so the sections marked 📝 are open for me to fill in from my own notes.

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

## 📝 To add

- [ ] Example failed-logon event (Event ID 4625) and the Wazuh rule it matched
- [ ] One process investigation (PowerShell parent → child, hash lookup result)
- [ ] Correlated timeline screenshot
- [ ] Triage verdicts for each investigated alert

## Outcome

- ✅ Windows agent connected, Sysmon telemetry verified
- ✅ Authentication and process-creation events investigated
- ✅ PowerShell and hash analysis completed
- ✅ Timelines correlated; SOC triage workflow completed
- 📸 Snapshots: `Phase-5-SOC-Monitoring-Complete` (WAZUH-SERVER and WIN-ENDPOINT-01)
