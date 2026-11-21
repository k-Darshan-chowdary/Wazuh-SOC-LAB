# Phase 2 — Wazuh SIEM Deployment

**Goal:** install an all-in-one Wazuh stack, fix the data-forwarding service, secure access, and capture a known-good snapshot.

## What "all-in-one" means

| Component | Job |
|---|---|
| Wazuh Manager | Collects and analyzes security events |
| Filebeat | Ships alerts/data to the indexer |
| Wazuh Indexer | Stores and searches security data |
| Wazuh Dashboard | Analyst web interface (HTTPS 443) |

Wazuh **4.14** installed with the official assistant on Ubuntu 24.04.4.

## Pre-install checks

The server was started alone to save RAM. Internet, DNS and both interfaces were verified before downloading anything.

```bash
ping -c 4 1.1.1.1
ping -c 4 packages.wazuh.com
ip -br a
# ens33  192.168.234.130/24  (NAT)
# ens37  10.10.10.10/24      (SOC-LAB)

curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
ls -lh wazuh-install.sh       # sane file size?
head -n 5 wazuh-install.sh    # starts with #!/bin/bash, not an HTML error page?
```

## Installation

```bash
sudo bash ./wazuh-install.sh -a

sudo systemctl is-active wazuh-manager wazuh-indexer wazuh-dashboard filebeat
sudo ss -lntp | grep :443
```

A second accidental run reported that the components already existed. The correct response was to **stop**, not to use `--overwrite` on a working deployment.

## Problem: Filebeat inactive

| Service | State |
|---|---|
| wazuh-manager | active |
| wazuh-indexer | active |
| wazuh-dashboard | active |
| **filebeat** | **inactive** |

Wazuh itself was fine, so reinstalling would have been unnecessary and risky. Targeted fix:

```bash
sudo systemctl start filebeat
sudo systemctl enable filebeat
sudo filebeat test output   # connection OK · TLS handshake OK · talk to server OK
```

## Dashboard access

From WIN-ENDPOINT-01: `https://10.10.10.10`. The self-signed certificate warning was accepted for this isolated lab host only. Browser security was not disabled globally. Screenshots that exposed generated credentials were discarded.

## Admin password rotation

The installer-generated admin password was rotated without leaving it in shell history:

```bash
read -s -p "New password: " NEWPASS
sudo /usr/share/wazuh-indexer/plugins/opensearch-security/tools/wazuh-passwords-tool.sh \
  -u admin -p "$NEWPASS"
unset NEWPASS
sudo systemctl restart filebeat wazuh-manager wazuh-dashboard
sudo filebeat test output
```

The first attempt failed because `@` isn't an accepted symbol in this deployment's policy (allowed: `* + ? - .`). The password itself is never stored in this repo.

## Outcome

| Check | Result |
|---|---|
| Manager / Indexer / Dashboard / Filebeat | active |
| Filebeat → Indexer | talk to server OK |
| Windows → Dashboard | HTTPS login OK |

📸 Snapshot: `Wazuh-SIEM-Installed-Working`, taken after health, data path, dashboard access and password rotation were all verified.
