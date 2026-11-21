# Phase 7 — Detection Engineering

**Completed:** 2026-09-22
**Goal:** close the three detection gaps from [Phase 6](phase-06-controlled-attack-simulations.md) with custom Wazuh rules, then validate, test and tune them.

> **Sources:** my custom rules file [`configs/wazuh/local_rules-phase7.xml`](../configs/wazuh/local_rules-phase7.xml) (copied from the lab's evidence folder) and the milestone snapshot notes from both VMs.

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

## Endpoint change

WIN-ENDPOINT-01 was configured to **collect Event ID 5157** (Windows Filtering Platform blocked connection). That closes the Phase 6 ingestion gap that left port scans invisible.

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

## 📝 To add

- [ ] Screenshots of each custom rule firing in Wazuh
- [ ] Negative-control screenshot (same-port probes, no 100121)
- [ ] Tuning changes made (what was adjusted and why)
- [ ] How 5157 auditing was enabled on the endpoint

## Outcome

- ✅ 4 custom rules (100100, 100110, 100120, 100121) created, tested and tuned
- ✅ All 3 Phase 6 gaps closed, with MITRE mappings included
- ✅ Negative control passed; agent stable
- 📸 Snapshots: `Phase-7-Detection-Engineering-Complete` (both VMs)
