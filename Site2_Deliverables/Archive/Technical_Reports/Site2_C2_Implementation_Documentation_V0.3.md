# Site 2 Company 2
# Implementation Documentation

Prepared for: CST8248 Emerging Technologies Project  
Environment: Site 2, Company 2  
Document status: Working baseline / living document  
Version: 0.3  
Date: 2026-03-12  

---

## Document Control

| Field | Value |
|---|---|
| Document title | Site 2 Company 2 Implementation Documentation |
| Version | 0.3 |
| Status | Living document |
| Primary scope | Company 2 services implemented at Site 2 |
| Reference baseline | [Site1_Final_Documentation_V1.96.docx](C:/Algonquin/Winter2026/Emerging_Tech/Project/Site1_Final_Documentation_V1.96.docx) |
| Workspace | `C:\Algonquin\Winter2026\Emerging_Tech\Project` |
| Secrets handling | Passwords and sensitive secrets are intentionally excluded |

## Revision History

| Version | Date | Summary |
|---|---|---|
| 0.1 | 2026-03-12 | Initial markdown as-built draft created |
| 0.2 | 2026-03-12 | Reorganized into formal project-document structure and expanded implementation narrative |
| 0.3 | 2026-03-12 | Added Company 1 read-only assessment, MSP jump-box validation notes, and current cross-site project status |

## 1. Purpose

This document records the current Company 2 implementation at Site 2. It is intended to serve as the starting as-built record for the environment and will be updated as the project progresses.

It captures:

- the Site 2 Company 2 network and host layout
- service roles and relationships
- design choices and constraints
- configuration work completed so far
- validation results
- follow-up items for later phases

## 2. Scope

This document covers the Linux-side Company 2 infrastructure at Site 2, including:

- Site 2 identity domain controllers
- Site 2 file server
- Site 2 Linux client
- Site 2 SAN and iSCSI relationship
- DNS, DHCP, Samba, Kerberos, and SSH validation
- Site 1 to Site 2 file replication design and automation

This document does not replace the Site 1 handover. Site 1 remains the reference master environment.

## 3. Executive Summary

Company 2 at Site 1 and Site 2 is treated as the same company with a shared directory domain and a shared file-share model.

The implemented design at this phase is:

- Site 1 Company 2 is the authoritative master for file content
- Site 2 Company 2 acts as a replica and local access point
- Identity services are shared through the existing `c2.local` domain
- Site 2 exposes matching public and private file shares through Samba
- Site 2 pulls file content from Site 1 on a scheduled basis

This is intentionally a **master-to-replica** design, not an active-active full-sync design.

## 4. Design Rationale

The selected model is:

- Site 1 = master
- Site 2 = replica
- one-way synchronization from Site 1 to Site 2

This design was selected because:

- Site 1 was already implemented and treated as the reference environment
- Site 1 was under another teammate's responsibility and was not to be changed
- Site 1 already had internal Company 2 storage replication using GlusterFS
- Site 2 needed to align to the Site 1 share model without redesigning Site 1 storage
- the approach reduces cross-site conflict risk and is easier to validate

Important distinction:

- **Replication** is not the same as **backup**
- this implementation provides replicated access, not Veeam-style restore points

## 5. Environment Overview

### 5.1 Site 2 Company 2 Hosts

| Host | Role | IP |
|---|---|---|
| `C2IdM1` | Site 2 AD DC / DNS / DHCP node | `172.30.65.66` |
| `C2IdM2` | Site 2 AD DC / DNS / DHCP node | `172.30.65.67` |
| `C2FS` | Site 2 file server / iSCSI initiator / replica target | `172.30.65.68` |
| `C2LinuxClient` | Site 2 Linux client | `172.30.65.70` |
| `C2SAN` | Site 2 iSCSI target | `172.30.65.194` |

### 5.2 Site 2 Network Summary

| Item | Value |
|---|---|
| Site 2 Company 2 LAN | `172.30.65.64/26` |
| Default gateway | `172.30.65.65` |
| Domain | `c2.local` |
| Kerberos realm | `C2.LOCAL` |
| NetBIOS domain | `C2` |

### 5.3 SAN Segment Summary

| Item | Value |
|---|---|
| `C2SAN` | `172.30.65.194` |
| `C2FS` SAN interface | `172.30.65.195` |

This separation is used to keep iSCSI traffic isolated from normal user-generated traffic.

### 5.4 Site 1 Company 2 Reference Hosts

| Host | Role | IP |
|---|---|---|
| `C2-DC1` | Site 1 Company 2 DC / DNS / DHCP / Gluster node | `172.30.64.146` |
| `C2-DC2` | Site 1 Company 2 DC / DNS / DHCP / Gluster node | `172.30.64.147` |

## 6. Site 1 Reference Architecture

Read-only validation against Site 1 confirmed:

- GlusterFS is active on `C2-DC1` and `C2-DC2`
- the Company 2 Gluster volume is `gv0`
- the volume is internally replicated across Site 1 only
- the mounted file-share path is `/mnt/sync_disk`

Observed Site 1 Samba mapping:

- `C2_Public -> /mnt/sync_disk/Public`
- `C2_Private -> /mnt/sync_disk/Private/%U`

Observed Site 1 Company 2 content model:

- `Public` contains shared content visible to authorized users
- `Private` contains per-user directories
- users should only see their own private path through `%U`

Observed Site 1 user private directories included:

- `admin`
- `admindc`
- `employee1`
- `employee2`
- `user1`
- `user2`

## 7. Site 2 Implemented Services

### 7.1 Identity Layer

`C2IdM1` and `C2IdM2` were validated as healthy Site 2 domain controllers for the existing `c2.local` environment.

Validated state:

- `samba-ad-dc` active on both nodes
- replication with Site 1 healthy
- local DNS functional
- DHCP service present and active on both nodes

### 7.2 Recursive DNS

Initially, Site 2 internal DNS only resolved local Company 2 records and did not forward recursive lookups.

Applied fix:

- added `dns forwarder = 8.8.8.8` to both Site 2 Company 2 DCs
- restarted `samba-ad-dc`

Validated result:

- external lookups such as `archive.ubuntu.com` now resolve through `172.30.65.66` and `172.30.65.67`
- package management on Site 2 can use normal repositories again

### 7.3 File Server

`C2FS` was implemented as a Samba domain member server and local replica access point.

Validated state:

- joined to `c2.local`
- `smbd` active
- SAN-backed storage mounted at `/mnt/c2_public`
- share paths aligned to Site 1 public/private model

### 7.4 Linux Client

`C2LinuxClient` was validated as:

- domain joined
- SSH reachable
- able to resolve domain users
- able to access the Site 2 Samba shares as a Company 2 user

## 8. Storage and iSCSI

### 8.1 Storage Path

Observed on `C2FS`:

- active iSCSI session to `172.30.65.194:3260`
- target IQN: `iqn.2024-03.org.clearroots:c2san`
- block device: `sdb`
- mounted share root: `/mnt/c2_public`

### 8.2 Traffic Isolation

The implementation uses:

- LAN addressing for user and domain traffic
- a separate SAN path for iSCSI traffic

This supports the project requirement that iSCSI traffic be isolated from user-generated traffic.

## 9. File Share Structure at Site 2

### 9.1 Implemented Paths

The Site 2 file-share layout was aligned to the Site 1 model:

- `C2_Public -> /mnt/c2_public/Public`
- `C2_Private -> /mnt/c2_public/Private/%U`

### 9.2 Access Model

Public behavior:

- shared content area
- visible to authorized Company 2 users

Private behavior:

- per-user private path using `%U`
- user should only see content for the logged-in account

### 9.3 Group Model

Site 2 uses the group:

- `c2_file_users`

This group is used to control file-share access and ownership alignment on the Site 2 replica side.

## 10. Validation Performed

### 10.1 Identity Validation

Validated:

- `C2IdM1` healthy
- `C2IdM2` healthy
- AD replication healthy
- Company 2 DNS healthy
- recursive DNS healthy after forwarder fix

### 10.2 File Service Validation

Validated:

- Samba domain member role on `C2FS`
- public/private share model present
- SAN-backed storage mounted and in use

### 10.3 Client Validation

Validated:

- `employee1@c2.local` resolves on `C2LinuxClient`
- `employee1` can access `C2_Public`
- `employee1` can access `C2_Private`
- expected user-private visibility model works

### 10.4 Replication Validation

Validated:

- Site 1 public and private structures can be pulled to Site 2
- Site 2 replica content reflects Site 1 master structure
- sync script executed successfully in manual testing

## 11. Synchronization Automation

### 11.1 Objective

Automate Site 2 pull-based synchronization from Site 1 without making any changes to Site 1.

### 11.2 Automation Prerequisites

Completed prerequisites:

- recursive DNS fixed on Site 2
- `sshpass` installed on `C2FS`

### 11.3 Sync Script

Deployed on `C2FS`:

- `/usr/local/bin/c2_site1_sync.sh`

Validated final state:

- owner: `root:root`
- mode: `700`

### 11.4 Script Behavior

The script:

- pulls `Public` from Site 1
- pulls `Private` from Site 1
- stages content temporarily on Site 2
- mirrors staged content into the live Site 2 share paths
- reapplies expected group and permission alignment

### 11.5 Logging

Log file:

- `/var/log/c2_site1_sync.log`

Validated successful log flow included:

- `Starting Site1 -> Site2 C2 sync`
- `Pulling Public from 172.30.64.146:/mnt/sync_disk/Public`
- `Pulling Private from 172.30.64.146:/mnt/sync_disk/Private`
- `Sync completed successfully`

### 11.6 Schedule

Configured cron schedule on `C2FS`:

```cron
0 2 * * * /usr/local/bin/c2_site1_sync.sh >> /var/log/c2_site1_sync.log 2>&1
```

This means Site 2 performs a daily pull sync from Site 1 at 02:00.

## 12. Why This Is Not Full Active-Active Sync

The current implementation is intentionally **not** a full bi-directional active-active sync design.

Why:

- Site 1 GlusterFS currently replicates only inside Site 1
- Site 2 is not part of the Site 1 Gluster peer/brick layout
- Site 1 was not to be modified during this phase

Therefore, the current design is:

- Site 1 internal replication
- Site 2 downstream replica

If future work required real full sync, Site 1 would also need changes such as:

- adding Site 2 nodes as Gluster peers
- extending the storage volume across sites
- validating cross-site Gluster traffic and healing behavior
- planning conflict and split-brain handling

## 13. Changes Applied in This Phase

Changes were applied only on Site 2.

Implemented changes included:

- validating and stabilizing Site 2 Company 2 AD services
- fixing recursive DNS for Site 2 Company 2
- validating DHCP presence on Site 2 Company 2 DCs
- configuring and validating `C2FS`
- aligning Site 2 file-share layout to Site 1
- validating Linux client domain access and share access
- validating SAN/iSCSI connectivity
- implementing Site 1 to Site 2 pull replication
- automating the Site 2 pull sync with a scheduled cron job

## 14. Explicit Non-Changes

No changes were made to Site 1 during this phase.

Site 1 was used only as:

- architectural reference
- read-only validation source
- content master for Site 2 replication

This is an important project note and should remain explicit in later revisions.

## 15. Risks and Operational Notes

Current operational assumptions:

- Site 1 remains the authority for shared Company 2 content
- Site 2 should not be treated as the primary authoring location
- local edits made only at Site 2 may be overwritten by later pull sync runs

This behavior is expected under the chosen master/replica model.

## 16. Remaining Follow-Up Items

This is the baseline implementation document. Likely next improvements include:

- documenting exact DHCP scopes and failover behavior
- adding Windows client implementation details
- documenting Veeam backup separately from replication
- appending final config excerpts for Samba, DNS, and cron
- adding screenshots and validation evidence as appendices
- deciding whether future phases should remain master/replica or move toward a more advanced multi-site storage design

## 17. Security Note

Credentials used during implementation are intentionally excluded from this document.

Administrative usernames, hostnames, IPs, jump paths, and service behavior are documented. Passwords and secrets should remain in a separate secure record.

## 18. Initial Appendix Placeholders

Future revisions can add:

- Appendix A: command transcript extracts
- Appendix B: final Samba config excerpts
- Appendix C: DNS and DHCP config excerpts
- Appendix D: validation screenshots
- Appendix E: sync script listing

## 19. Change Log

### 2026-03-11 to 2026-03-12

- Validated Site 2 Company 2 AD DC health
- Validated Site 2 DNS, DHCP, and Samba service state
- Confirmed SAN-backed iSCSI storage path
- Aligned Site 2 public/private share structure to Site 1 model
- Validated Linux client access with Company 2 user accounts
- Implemented Site 1 to Site 2 pull replication
- Fixed recursive DNS forwarding on Site 2 Company 2 DCs
- Installed prerequisites for automation on `C2FS`
- Deployed and scheduled the Site 2 sync automation


## 20. Company 1 Read-Only Assessment Through MSP Access Path

A separate read-only assessment was performed for Company 1 through the MSP jump path. No Company 1 configuration changes were made during this work.

### 20.1 Access Path Used

The validation path used was:

- local administration host -> MSP jump system `10.50.17.31:33564`
- MSP path -> Company 1 Windows endpoints supplied by the project owner

The live Company 1 endpoints validated through this path were:

| Host | IP used for validation | Expected role |
|---|---|---|
| `C1DC1` | `172.30.65.2` | Company 1 Domain Controller |
| `C1DC2` | `172.30.65.3` | Company 1 Domain Controller |
| `C1DFS` | `172.30.65.10` | Company 1 DFS / file-service node |
| `C1WebServer` | `172.30.65.162` | Company 1 DMZ web server |

Note: these live MSP-access paths differ from the addressing shown in the Site 1 reference handover. The reference handover remains the architectural source, while the MSP-access scan above reflects the currently reachable validation path provided during implementation.

### 20.2 Live Network and Service Scan Results

A read-only scan was executed from the MSP jump system against the Company 1 endpoints.

| Host | Ping | Open ports observed | Interpretation |
|---|---|---|---|
| `C1DC1` | Yes | `53`, `88`, `135`, `139`, `389`, `445`, `3389`, `5985` | DNS, Kerberos, AD/LDAP, SMB, RDP, and WinRM all reachable |
| `C1DC2` | Yes | `53`, `88`, `135`, `139`, `389`, `445`, `3389`, `5985` | Secondary DC exposes the same core AD services |
| `C1DFS` | Yes | `135`, `139`, `445`, `3389`, `5985` | File-services path, SMB, RDP, and WinRM reachable |
| `C1WebServer` | No ICMP reply | `80`, `3389`, `5985` | Web service reachable; ICMP likely filtered |

Additional web validation from the MSP path confirmed:

- `http://172.30.65.162` returned `HTTP/1.1 200 OK`
- server banner: `Microsoft-IIS/10.0`

### 20.3 Interpretation Against Company 1 Requirements

Based on the Site 1 handover plus the MSP-path validation above, the following Company 1 items are strongly evidenced:

| Requirement area | Current evidence status | Notes |
|---|---|---|
| Web server in DMZ | Confirmed | IIS responds with HTTP 200 on `C1WebServer` |
| DNS for local resolution | Confirmed by architecture and open DNS service ports on both DCs | Reference handover documents Windows DNS on both DCs |
| Recursive DNS | Documented in Site 1 handover | The reference handover states external recursive resolution was validated on Company 1 DNS |
| Active Directory / LDAP | Confirmed | `53`, `88`, `389`, `445`, `5985`, and `3389` are reachable on both DCs |
| Fault tolerant / replicated file server | Documented and partially evidenced | Reference handover describes DFS namespace and DFS replication; live SMB service path on `C1DFS` is reachable |
| Two clients (1 Linux, 1 Windows) | Documented in Site 1 handover | Not re-validated live in this pass because only the server-side MSP endpoints above were scanned |
| Fault tolerant DHCP | Documented in Site 1 handover | The handover states Windows DHCP hot-standby between `C1DC1` and `C1DC2` |
| iSCSI target / initiator | Documented in Site 1 handover | The handover includes Company 1 SAN targets and client/server initiators on the SAN VLAN |
| Remote access | Confirmed | RDP is reachable on `C1DC1`, `C1DC2`, `C1DFS`, and `C1WebServer`; WinRM also reachable |

### 20.4 What Was Not Changed on Company 1

During this assessment:

- no Company 1 configuration files were edited
- no Windows services were restarted
- no DFS, DHCP, DNS, AD, or file-share permissions were changed
- no RDP session configuration was changed
- no backup configuration was changed

This section is important because Company 1 remained under separate ownership during the Site 2 implementation phase.

## 21. Current Cross-Site Position

The current cross-site project state can be summarized as follows:

| Area | Current state |
|---|---|
| Site 1 Company 1 | Read-only assessed through MSP path; no changes made |
| Site 1 Company 2 | Used as the authoritative source for the Site 2 Company 2 replica design |
| Site 2 Company 2 identity | Implemented and validated |
| Site 2 Company 2 file services | Implemented and validated |
| Site 2 Company 2 Linux client access | Implemented and validated |
| Site 1 -> Site 2 Company 2 sync | Implemented as one-way pull replication |
| Backup (Veeam) | Separate scope from replication; not treated as equivalent |

## 22. Clarification: Replication vs Backup

A recurring project question was whether the implemented Site 1 to Site 2 content transfer should be treated as backup. The answer is no.

- **Replication** keeps a current copy of shared content available at another site
- **Backup** preserves restore points and historical recovery capability
- **Veeam** belongs to the backup layer, not the share replication layer

For this project phase, the implemented Company 2 cross-site file solution is a **replicated file-service design**, not a Veeam-style backup workflow.

### 2026-03-12 (additional Company 1 assessment)

- Validated MSP jump access path for Company 1 Windows infrastructure
- Confirmed reachability of `C1DC1`, `C1DC2`, `C1DFS`, and `C1WebServer`
- Confirmed IIS response on the Company 1 web server
- Added Company 1 read-only assessment findings to the living implementation document
