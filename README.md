# aquacore-water-ot-segmentation

A two-tier Azure Virtual Network lab modeling IT/OT segmentation for a
water treatment facility — built manually first, then fully automated
via Azure CLI.

## Why this exists

In July 2026, attackers compromised 30+ Minnesota water utilities by
exploiting PLCs connected directly to the internet (CISA Advisory
AA26-097A). This lab demonstrates the actual remediation pattern CISA
recommended: no direct internet exposure for OT infrastructure, and
access restricted through a single controlled bastion path.

## Architecture
![Network architecture diagram](architecture-diagram.png)
- **Bastion subnet** (10.0.1.0/24) — `vm-it-monitor-bastion`, public IP,
  NSG restricts inbound SSH to a single admin IP
- **Private/OT subnet** (10.0.2.0/24) — `vm-ot-control`, **no public IP**,
  NSG restricts inbound SSH to the bastion subnet only

## Files

- **`deploy.sh`** — Azure CLI script that builds the entire architecture
  from nothing: resource group, VNet, both subnets, both NSGs with
  correctly scoped rules, and both VMs.
- **`AUDIT_CHECKLIST.md`** — pass/fail review of the deployed
  architecture against the security controls it's meant to demonstrate.

## Usage

```
export ADMIN_IP="your.real.ip.address"
az login
bash deploy.sh
```

Your real IP is never hardcoded into the script — it's read from an
environment variable at runtime, so it's never committed to this repo.

## Notes on VM sizing

This lab went through several VM size changes during development due to
regional capacity restrictions on lower-cost B-series sizes. The final
script uses `Standard_D2als_v7`, a confirmed-available size on a
free-tier subscription — not the cheapest option, but the one proven to
actually deploy. Always delete the resource group after testing to avoid
ongoing charges (`az group delete --name rg-aquacore-water-ot --yes`).
