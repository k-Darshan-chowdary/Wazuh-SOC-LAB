# Phase 0 — Architecture & Safety

**Goal:** design the lab so that learning never puts the real host or home network at risk.

## Platform decision

The project started as a Splunk idea. The long-term requirement, though, was a **free lab that stays fully useful with no license expiry**. Wazuh (open-source SIEM/XDR) was chosen as the central platform. The project is framed honestly as a **portfolio lab**, not an internship.

**Project goal:** a three-VM environment that can grow into controlled attacks, endpoint telemetry, detection engineering, MITRE mapping, threat hunting, incident investigation, dashboards, response, reporting, and a public portfolio (this repo).

## Lab roles

| VM | Role | SOC-LAB IP |
|---|---|---|
| KALI | Attacker / test generator | 10.10.10.30 |
| WIN-ENDPOINT-01 | Monitored Windows 11 endpoint | 10.10.10.20 |
| WAZUH-SERVER | Manager + Indexer + Dashboard | 10.10.10.10 |

The **physical host runs VMware only**. It is never a test target and does not receive the security tooling used inside the lab.

## Safety rules

**Contain the experiment**
1. Kali targets only the Windows lab VM, never the physical host.
2. No bridged networking for attack traffic; use a private VMware LAN segment.
3. Keep NAT on a separate adapter and disconnect it during higher-risk simulations.

**Make failure reversible**
- Snapshot clean operating systems and every working Wazuh milestone.
- Back up configuration files before editing them.
- Shut down cleanly before taking snapshots.
- Never publish passwords, credentials, or screenshots that expose them.

## The core chain every phase strengthens

```
ACTIVITY → TELEMETRY → ANALYSIS → ALERT → ANALYST
(user/process   (Windows/     (Wazuh      (match    (context decides
 does something) Sysmon logs)  rules)      surfaced)  benign vs malicious)
```

> Telemetry proves something happened. A detection applies logic. An alert surfaces a match. Investigation adds context.

## 15-phase roadmap

0 Architecture & safety · 1 Virtual lab & networking · 2 Wazuh deployment · 3 Windows monitoring · 4 Sysmon · 5 SOC monitoring fundamentals · 6 Kali attack simulations · 7 Detection engineering · 8 MITRE ATT&CK mapping · 9 Threat hunting · 10 Incident investigations · 11 Dashboards · 12 Incident response · 13 Reports · 14 Final portfolio
