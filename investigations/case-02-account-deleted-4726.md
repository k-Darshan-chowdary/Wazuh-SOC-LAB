# Case 02 — Local Account Deleted (Event 4726)

| Field | Value |
|---|---|
| Date | 2026-08 (Phase 3) |
| Host | WIN-ENDPOINT-01 (agent 001) |
| Source event | Windows Security **4726** (user account deleted) + related group-change alert |
| Wazuh rule | **60111**, Level 8, "User account disabled or deleted" |
| MITRE | **T1098** Account Manipulation + **T1531** Account Access Removal (Persistence, Impact) |
| Verdict | **Authorized true positive** (cleanup of Case 01) |

## Scenario

Cleaning up the Case 01 account was monitored too.

```powershell
Remove-LocalUser -Name "SOC-LAB-TEST"
Remove-Variable TestPassword -ErrorAction SilentlyContinue
Get-LocalUser -Name "SOC-LAB-TEST"   # expected error: account not found
```

## Investigation filters

```
agent.name = WIN-ENDPOINT-01
data.win.system.eventID = 4726
```

## Correlated timeline

```
12:53  SOC-LAB-TEST created  → 4720 → 60109 (L8) → T1098
13:24  SOC-LAB-TEST deleted  → 4726 → 60111 (L8) → T1098 + T1531
```

## Conclusion

Detection worked for the deletion as well. Seen together, create → delete 31 minutes later is a pattern worth knowing: in a real environment, a short-lived account can mean an attacker cleaning up after themselves. Here it was planned lab cleanup.
