# Phase 1 — Virtual Lab & Isolated Networking

**Goal:** build three recoverable VMs and a dual-network design that keeps internet access while isolating lab traffic.

## Resource planning (16 GB host)

- Host: Intel i7-13650HX (14 cores / 20 threads), 16 GB DDR5, 1 TB NVMe, virtualization enabled. Lab stored on the `E:` drive.
- Idle RAM was ~80%; cleaning up startup/background apps brought it to ~49%.
- **Operating rule**
  - Config work: Wazuh 6 GB + Windows 4 GB, Kali off.
  - Attack testing: Wazuh 6 GB + Windows 4 GB + Kali 2 GB = 12 GB to VMs.

## VM specs

| VM | OS | RAM | vCPU | Disk | Adapters |
|---|---|---|---|---|---|
| WAZUH-SERVER | Ubuntu 24.04.4 Server | 6 GB | 4 | 60 GB | NAT + SOC-LAB |
| WIN-ENDPOINT-01 | Windows 11 Pro | 4 GB | 2 | 64 GB | NAT + SOC-LAB |
| KALI | Kali Linux | 2 GB | 2 | 75 GB | NAT + SOC-LAB |

## Project structure & recovery points

```
E:\Cybersecurity-SOC-Lab
├─ Kali
├─ Windows-Endpoint
├─ Wazuh-Server
├─ ISO-Files
└─ Portfolio-Evidence
```

Snapshots: `Clean-Ubuntu-Before-Wazuh`, `Clean-Windows-Before-Security-Tools`, then one per working milestone (see later phases).

## Two adapters, two jobs

| Adapter | Subnet | Purpose | Gateway/DNS |
|---|---|---|---|
| VMware NAT | 192.168.234.0/24 | Downloads, updates, browser | Yes (default route lives here) |
| SOC-LAB LAN segment | 10.10.10.0/24 | Attack traffic, telemetry, investigations | **None**, no default route |

Kali is never bridged onto the home network.

## Static addressing

| Host | Interface | Address |
|---|---|---|
| WAZUH-SERVER | `ens37` | 10.10.10.10/24 |
| WIN-ENDPOINT-01 | `Ethernet1` | 10.10.10.20/24 |
| KALI | `eth1` | 10.10.10.30/24 |

Predictability beats convenience: agents always know where the manager is, and attack scenarios target known addresses.

One design, three toolsets: **Netplan** (Ubuntu), **NetTCPIP cmdlets** (Windows), **NetworkManager/nmcli** (Kali). Configs are in [`configs/`](../configs).

## Connectivity testing

Pairwise tests (to save RAM) all passed: Kali↔Wazuh, Windows↔Wazuh, Windows↔Kali, with NAT internet still working.

**The one failure:** Kali → Windows ping failed. Cause: Windows Firewall blocking inbound ICMP. Fix: a **scoped** rule allowing echo requests only from `10.10.10.0/24`, without disabling the firewall.

```powershell
New-NetFirewallRule -DisplayName "SOC-LAB Allow ICMPv4" `
  -Direction Inbound -Protocol ICMPv4 -IcmpType 8 `
  -RemoteAddress 10.10.10.0/24 -Action Allow
```

## Mistakes → lessons

- Netplan used `dhcp` instead of `dhcp4`.
- Kali tab-completion produced a huge command list; a half-configured profile was deleted and rebuilt.
- Windows 11 install failed until a virtual TPM 2.0 was added.

Recovery pattern: inspect current state → identify the exact setting → change only that → validate addresses and routes. No broad fixes such as disabling the firewall or reinstalling.

## Outcome

- ✅ Three named VMs built, clean snapshots taken
- ✅ NAT internet preserved, SOC-LAB segment added
- ✅ Static .10 / .20 / .30 addressing
- ✅ Scoped ICMP rule; pairwise connectivity proven
