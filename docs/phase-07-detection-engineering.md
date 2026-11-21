# Phase 7 — Detection Engineering

**Completed:** 2026-09-22
**Goal:** close the three detection gaps from [Phase 6](phase-06-controlled-attack-simulations.md) with custom Wazuh rules, then validate, test and tune them.

> **Sources:** my custom rules file [`configs/wazuh/local_rules-phase7.xml`](../configs/wazuh/local_rules-phase7.xml) plus the actual command history recovered from WAZUH-SERVER and WIN-ENDPOINT-01. Only screenshots are still missing (marked 📝).

## Custom rules

| Rule | Level | Detects | Logic | ATT&CK |
|---|---|---|---|---|
| **100100** | 10 | Password guessing | **5** failed Windows logons (built-in rule 60122) within **120 s**; quiet for 60 s after firing | T1110 |
| **100110** | 10 | Scheduled-task persistence | Sysmon Event 1 where the image ends in `\schtasks.exe` **and** the command line contains `/Create` | T1053.005 |
| **100120** | 5 | WFP blocked inbound TCP | Windows event (parent 60104) with **Event ID 5157** and **protocol 6** (TCP) | — (building block) |
| **100121** | 10 | TCP port scan | **3** × rule 100120 within **30 s**, **same** source & destination address, **different** destination ports | T1046 |

### How the logic works

**100100: correlation instead of single events.** Rule 60122 fires on each failed logon. `frequency="5" timeframe="120"` with `if_matched_sid` turns a burst into one level-10 alert. `ignore="60"` stops it re-firing on every extra attempt.

```xml
<rule id="100100" level="10" frequency="5" timeframe="120" ignore="60">
  <if_matched_sid>60122</if_matched_sid>
  <description>Possible password guessing: 5 failed Windows logons within 120 seconds.</description>
  <mitre><id>T1110</id></mitre>
</rule>
```

**100110: behavior, not just a process name.** Running `schtasks.exe` alone is common. The rule requires the `/Create` switch in the command line, using case-insensitive PCRE2.

```xml
<rule id="100110" level="10">
  <if_group>sysmon_event1</if_group>
  <field name="win.eventdata.image" type="pcre2">(?i)\\schtasks\.exe$</field>
  <field name="win.eventdata.commandLine" type="pcre2">(?i)/Create</field>
  <description>Possible persistence: scheduled task created using schtasks.exe</description>
  <mitre><id>T1053.005</id></mitre>
</rule>
```

**100120 → 100121: a two-stage port-scan detection.** 100120 is a low-level building block that normalizes "firewall blocked a TCP connection". 100121 correlates it: the same attacker and target hitting **different** ports in a short window is scanning, while repeated hits on one port are not.

```xml
<rule id="100121" level="10" frequency="3" timeframe="30" ignore="60">
  <if_matched_sid>100120</if_matched_sid>
  <same_field>win.eventdata.sourceAddress</same_field>
  <same_field>win.eventdata.destAddress</same_field>
  <different_field>win.eventdata.destPort</different_field>
  <description>Possible TCP port scan: multiple blocked destination ports probed from the same source.</description>
  <mitre><id>T1046</id></mitre>
</rule>
```

## Endpoint change: ingest Event 5157

The port-scan rule can't fire if the endpoint never records blocked connections. Two things were needed on WIN-ENDPOINT-01:

```powershell
# 1. Turn on Filtering Platform Connection auditing (failures)
auditpol /set /subcategory:"Filtering Platform Connection" /failure:enable
auditpol /get  /subcategory:"Filtering Platform Connection"

# 2. The Wazuh agent's ossec.conf had been filtering 5157 out ("and EventID != 5157").
#    Remove that exclusion, validate the XML, and restart the agent.
Restart-Service WazuhSvc
```

Then a scan from Kali was confirmed to reach the manager, filtering on the attacker IP:

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=5157; StartTime=(Get-Date).AddMinutes(-10)} |
  Where-Object { $_.Message -match '10\.10\.10\.30' } | Select-Object -First 10 TimeCreated,Id,Message | Format-List
```

## How the rules were built and validated (WAZUH-SERVER)

The rules live in a dedicated file so the stock ruleset stays untouched, and **every change was validated before restarting the manager**:

```bash
# Create the rules file (one <group> per detection, appended as each was added)
sudo tee /var/ossec/etc/rules/phase7_rules.xml > /dev/null <<'EOF'
... rule XML ...
EOF

# Validate syntax BEFORE restarting — this is the key habit
sudo /var/ossec/bin/wazuh-analysisd -t
sudo systemctl restart wazuh-manager
sudo systemctl is-active wazuh-manager
```

A timestamped backup was taken before each edit (`phase7_rules.xml.after-7.1`, `.before-7.2-fix`, `.before-destfield-fix`, …), so every tuning step was reversible.

## Tuning journey (the real debugging)

The rules didn't work first try. `wazuh-analysisd -t` and live testing drove these fixes:

| Issue found | Fix |
|---|---|
| 100110 first matched on `win.system.eventID = 1`, which was unreliable | Switched to `<if_group>sysmon_event1</if_group>` |
| 100120 used `<options>no_log</options>` at level 1 and never surfaced | Raised to level 5 and removed `no_log` |
| 100120 wasn't anchored to a parent rule | Added `<if_sid>60104</if_sid>` (Windows event decoder) |
| 100121 used `destinationAddress` / `destinationPort` — wrong field names | Renamed to `destAddress` / `destPort` (what Wazuh actually decodes) |
| Port-scan rule too sensitive at `frequency="4"` | Tuned to `frequency="3"` |

> This is the real value of the phase: the final rules file looks clean, but getting there meant reading `wazuh-analysisd` errors, checking which field names Wazuh decodes, and tuning thresholds against live tests.

## Testing

- All four rules were **created, validated, tested and tuned** against controlled activity.
- **Negative control:** repeated probes to the **same** port did **not** trigger 100121. That proves the `different_field` logic works and the rule doesn't fire on ordinary retries.
- The Wazuh agent stayed **stable, with no buffer or flood warnings** after adding 5157 collection (a lesson from Phase 4).

## Gaps closed

| Phase 6 gap | Closed by |
|---|---|
| Repeated authentication not correlated | 100100 |
| WFP 5157 not ingested | Endpoint 5157 collection + 100120 |
| Scheduled-task persistence missed | 100110 |
| (Port scanning now detectable) | 100121 |

### Negative control

Repeated probes to the **same** port were run from Kali to prove 100121 only fires on *different* ports:

```bash
for i in {1..5}; do nmap -sT -Pn -p 445 10.10.10.20; sleep 2; done
```

This did **not** trigger the port-scan alert, confirming the `different_field` logic.

## 📝 Still to add

- [ ] Screenshots of each custom rule firing in Wazuh
- [ ] Negative-control screenshot (same-port probes, no 100121)

## Outcome

- ✅ 4 custom rules (100100, 100110, 100120, 100121) created, tested and tuned
- ✅ All 3 Phase 6 gaps closed, with MITRE mappings included
- ✅ Negative control passed; agent stable
- 📸 Snapshots: `Phase-7-Detection-Engineering-Complete` (both VMs)
