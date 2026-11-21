# Case 01 — Local Account Created (Event 4720)

| Field | Value |
|---|---|
| Date | 2026-08 (Phase 3) |
| Host | WIN-ENDPOINT-01 (agent 001) |
| Source event | Windows Security **4720** (user account created) |
| Wazuh rule | **60109**, Level 8, "User account enabled or created" |
| MITRE | **T1098** Account Manipulation (Persistence) |
| Verdict | **Authorized true positive** (benign, intentional test) |

## Scenario

A temporary local account was created on purpose so the full detection path (activity → telemetry → rule → alert → analyst) could be observed.

```powershell
$TestPassword = Read-Host "Temp password" -AsSecureString   # value not recorded
New-LocalUser -Name "SOC-LAB-TEST" -Password $TestPassword -Description "Temporary SOC lab account"
Get-LocalUser SOC-LAB-TEST
```

## Step 1: verify the source event first

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4720; StartTime=(Get-Date).AddMinutes(-15)} |
  Select-Object -First 3 | Format-List TimeCreated,Id,Message
```

The raw Windows event was confirmed **before** looking at Wazuh's interpretation.

## Step 2: Wazuh interpretation

`New-LocalUser` → Windows 4720 → Wazuh 60109 (L8) → MITRE T1098

## Step 3: who did what to whom

| Role | Value |
|---|---|
| **Subject** (who acted) | The logged-in lab user who ran `New-LocalUser` |
| **Target** (what changed) | `SOC-LAB-TEST` on `WIN-ENDPOINT-01`, password never expires |

Analyst question: *was the subject authorized to create this target?* Yes, because it was part of a planned lab exercise.

## Conclusion

Wazuh correctly detected a security-relevant action. The alert was **real** (not a false positive), but the activity was **authorized and benign**, so this is not an incident. In a real SOC the same alert would need ticket or change-request validation.
