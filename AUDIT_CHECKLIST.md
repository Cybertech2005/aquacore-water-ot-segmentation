# Network Architecture Audit Checklist
**Aqua Core Solutions — Water Treatment Facility Segmentation**
Auditor: Jaden Lassiter | Scope: VNet/subnet/NSG configuration review

| Control | Reference | Status | Evidence |
|---|---|---|---|
| OT control endpoint has no public IP | CISA AA26-097A remediation guidance | Pass | No public IP assigned to vm-ot-control |
| Inbound access to OT subnet restricted to bastion only | Least privilege / access control lists | Pass | NSG rule Allow-Bastion-Host: source 10.0.1.0/24, port 22/TCP only |
| Bastion admin access restricted to single known IP | Least privilege | Pass | NSG rule Allow-Admin-SSH: source restricted to /32 |
| Default deny-all present as final rule | Defense in depth | Pass | DenyAllInBound (priority 65500) active |
| Default VNet-wide allow rule still present | Defense in depth | Note | AllowVnetInBound (65000) not yet explicitly closed — not currently exploitable with only 2 subnets, but would need addressing before adding a third subnet |
| Infrastructure reproducible without manual steps | Change management / reliability | Pass | deploy.sh recreates full architecture via Azure CLI |

**Overall:** Architecture meets the core remediation pattern identified in the
Minnesota water utility incident (CISA AA26-097A) — no direct internet
exposure of OT infrastructure, single controlled access path. One
non-blocking observation noted above for future hardening.
