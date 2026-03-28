# Site 2
# Implementation Documentation

Prepared for: CST8248 Emerging Technologies Project  
Environment: Site 2 (Company 1 + Company 2 + shared site services)  
Document status: Expanded working baseline / living document  
Version: 1.1  
Date: 2026-03-12  

---

## Document Control

| Field | Value |
|---|---|
| Document title | Site 2 Implementation Documentation |
| Version | 1.1 |
| Status | Living document |
| Primary scope | Site 2 infrastructure, tenant services, access paths, and validated cross-site behavior |
| Reference baseline | [Site1_Final_Documentation_V1.96.docx](C:/Algonquin/Winter2026/Emerging_Tech/Project/Site1_Final_Documentation_V1.96.docx) |
| Workspace | `C:\Algonquin\Winter2026\Emerging_Tech\Project` |
| Secrets handling | Passwords and sensitive secrets are intentionally excluded |


## Revision History

| Version | Date | Summary |
|---|---|---|
| 0.1 | 2026-03-12 | Initial markdown as-built draft created |
| 0.2 | 2026-03-12 | Reorganized into formal project-document structure and expanded implementation narrative |
| 0.3 | 2026-03-12 | Added Company 1 read-only assessment, MSP jump-box validation notes, and current cross-site project status |
| 0.4 | 2026-03-12 | Added requirement traceability matrices, project validation commands, and acceptance-test appendices for Company 1 and Company 2 |
| 0.5 | 2026-03-12 | Added configuration appendices, redacted automation details, troubleshooting guidance, and demo/runbook material |
| 1.0 | 2026-03-12 | Reframed the document as a full Site 2 implementation record covering Company 1 assessment, Company 2 implementation, shared networking, VPN, and backup context |
| 1.1 | 2026-03-12 | Rebalanced the document to present Site 2 as a site-wide environment first, moved Company 1 forward in the narrative, removed broken subsection numbering, and corrected validation command formatting |


## 1. Purpose

This document records the current Site 2 implementation as a living as-built baseline for the project. It is meant to capture the state of the site as a whole, not only Company 2.

The current version documents:

- Site 2 network and tenant layout
- Company 1 read-only validation performed through the MSP access path
- Company 2 services implemented and validated at Site 2
- shared site services such as SAN, VPN pathing, and repository context
- design choices, constraints, and rationale
- repeatable validation commands and acceptance evidence
- follow-up items for later project phases


## 2. Scope

This document currently covers the following Site 2 areas:

- Site 2 tenant network layout and gateway context
- Site 2 Company 1 read-only assessment through MSP-managed access
- Site 2 Company 2 identity, DNS, DHCP, file services, client access, and SAN use
- Site 1 to Site 2 Company 2 replication design and automation
- Site 2 backup and VPN context as documented in the reference handover and local configuration artifacts

This document does not replace the Site 1 handover. Site 1 remains the reference source for the original cross-site architecture and for Company 1 ownership. Where Site 1 was not modified or directly administered in this phase, that limitation is stated explicitly.


## 3. Executive Summary

Site 2 should be understood as a multi-service site containing:

- shared site networking and gateway services
- Company 1 Windows-based infrastructure that was assessed through a managed MSP access path
- Company 2 Linux-based infrastructure that was directly implemented, validated, and documented during this phase
- cross-site connectivity and backup context tied to the broader project architecture

At the time of this document, the strongest hands-on implementation work at Site 2 is on the Company 2 side. That includes:

- two healthy Site 2 Samba AD domain controllers
- a SAN-backed file server (`C2FS`)
- a domain-joined Linux client (`C2LinuxClient`)
- a Site 1 to Site 2 replicated file-service model for Company 2 content

Company 1 is also represented in this document, but in a different way:

- Company 1 systems were assessed through the MSP jump path in a read-only manner
- no Company 1 configuration changes were made in this phase
- Company 1 behavior is documented through a combination of live network evidence and the reference Site 1 handover

This is intentionally a **site-level living document**. It captures what exists, what was changed, what was only observed, and what still depends on another teammate's scope.


## 4. Design Rationale

Two different design realities exist in this project and both matter:

- Company 1 at Site 2 is primarily documented and assessed through managed access
- Company 2 at Site 2 is the area where direct implementation changes were made

For the Company 2 cross-site file-service portion, the selected model is:

- Site 1 = content master
- Site 2 = local replica and access point
- one-way synchronization from Site 1 to Site 2

This design was selected because:

- Site 1 already existed and was treated as the authoritative reference
- Site 1 was owned by another teammate and was not to be changed in this phase
- Site 1 Company 2 already used internal GlusterFS replication inside Site 1
- Site 2 needed to align to the Site 1 share model without redesigning Site 1 storage
- the master-to-replica approach reduces cross-site conflict risk and is easier to validate under project constraints

Important distinction:

- **Replication** is not the same as **backup**
- **Veeam** belongs to the backup layer
- the implemented Company 2 pull-sync design provides replicated access, not Veeam-style recovery points


## 5. Site 2 Overall Environment Overview

### Site 2 Tenant and Shared Segments

Based on the Site 2 OPNsense configuration artifact and the observed host addressing, the main Site 2 segments are:

| Segment | Gateway / Interface | Purpose |
|---|---|---|
| `172.30.65.0/26` | `172.30.65.1` (`C1LAN`) | Company 1 LAN |
| `172.30.65.64/26` | `172.30.65.65` (`C2LAN`) | Company 2 LAN |
| `172.30.65.160/29` | `172.30.65.161` (`C1DMZ`) | Company 1 DMZ |
| `172.30.65.168/29` | `172.30.65.169` (`C2DMZ`) | Company 2 DMZ |
| `172.30.65.176/29` | `172.30.65.177` (`MSP`) | management / MSP-access segment |
| `172.30.65.192/29` | direct SAN segment | Company 2 SAN path |

### Site 2 OPNsense / VPN Context

A local configuration artifact (`opnsenseconfig.txt`) indicates the Site 2 firewall / gateway context includes:

- hostname: `rp-msp-gateway`
- MSP interface: `172.30.65.177/29`
- Company 1 LAN gateway: `172.30.65.1/26`
- Company 2 LAN gateway: `172.30.65.65/26`
- Company 1 DMZ gateway: `172.30.65.161/29`
- Company 2 DMZ gateway: `172.30.65.169/29`
- OpenVPN server object described as `Site2-S2S-OpenVPN`

This document treats the OPNsense data as a local configuration reference. It was not modified during this phase.

### Site 2 Shared Administrative / Backup Context

From the reference Site 1 handover, the broader project design also expects the following Site 2 shared roles to exist or be reachable:

| Item | Documented role in project design | Current note in this document |
|---|---|---|
| Site 2 offsite backup repository host | Offsite Veeam repository target (`172.30.65.180`) | Documented-by-reference in this phase; not directly reconfigured here |
| MSP jump access path | Controlled administration entry path | Directly used and validated during this phase |
| Site 2 firewall / VPN edge | Inter-site routing and policy enforcement | Reflected from local OPNsense config artifact and project reference handover |

### Scope Split Inside This Document

This document is intentionally split into two evidence styles:

- **Directly implemented and validated**: Company 2 Site 2 Linux services, SAN use, replication, and Linux client access
- **Read-only assessed / documented by reference**: Company 1 Site 2 Windows services, OPNsense/VPN, and Site 2 offsite backup context


## 6. Company 1 Environment Overview
This section summarizes the Site 2 view of Company 1 based on MSP-path validation and the Site 1 reference handover. Company 1 was not reconfigured in this phase; it was assessed in a read-only manner.

At Site 2, Company 1 should be understood as the Windows-centric tenant environment consisting of domain controllers, DFS/file services, a DMZ web server, client systems, SAN usage, and backup/repository relationships documented in the project baseline.

Key points established during this phase:

- Company 1 endpoints were reachable through the MSP jump path
- the two domain controllers exposed the expected AD, DNS, SMB, RDP, and WinRM service ports
- the DFS/file-service node exposed SMB and management access
- the DMZ web server responded over HTTP as Microsoft IIS
- deeper Windows-role validation remained read-only and was cross-referenced against the Site 1 handover

This split is important in the document: Company 1 is represented here as a validated Site 2 tenant area, but not one that was actively reconfigured during the Linux-heavy implementation work performed for Company 2.

## 7. Company 1 Read-Only Assessment Through MSP Access Path

A separate read-only assessment was performed for Company 1 through the MSP jump path. No Company 1 configuration changes were made during this work.

### Access Path Used

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

### Live Network and Service Scan Results

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

### Interpretation Against Company 1 Requirements

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

### What Was Not Changed on Company 1

During this assessment:

- no Company 1 configuration files were edited
- no Windows services were restarted
- no DFS, DHCP, DNS, AD, or file-share permissions were changed
- no RDP session configuration was changed
- no backup configuration was changed

This section is important because Company 1 remained under separate ownership during the Site 2 implementation phase.


## 8. Company 2 Environment Overview

### Site 2 Company 2 Hosts

| Host | Role | IP |
|---|---|---|
| `C2IdM1` | Site 2 AD DC / DNS / DHCP node | `172.30.65.66` |
| `C2IdM2` | Site 2 AD DC / DNS / DHCP node | `172.30.65.67` |
| `C2FS` | Site 2 file server / iSCSI initiator / replica target | `172.30.65.68` |
| `C2LinuxClient` | Site 2 Linux client | `172.30.65.70` |
| `C2SAN` | Site 2 iSCSI target | `172.30.65.194` |

### Site 2 Network Summary

| Item | Value |
|---|---|
| Site 2 Company 2 LAN | `172.30.65.64/26` |
| Default gateway | `172.30.65.65` |
| Domain | `c2.local` |
| Kerberos realm | `C2.LOCAL` |
| NetBIOS domain | `C2` |

### SAN Segment Summary

| Item | Value |
|---|---|
| `C2SAN` | `172.30.65.194` |
| `C2FS` SAN interface | `172.30.65.195` |

This separation is used to keep iSCSI traffic isolated from normal user-generated traffic.

### Site 1 Company 2 Reference Hosts

| Host | Role | IP |
|---|---|---|
| `C2-DC1` | Site 1 Company 2 DC / DNS / DHCP / Gluster node | `172.30.64.146` |
| `C2-DC2` | Site 1 Company 2 DC / DNS / DHCP / Gluster node | `172.30.64.147` |


## 9. Site 1 Reference Architecture for Company 2

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


## 10. Site 2 Company 2 Implemented Services

### Identity Layer

`C2IdM1` and `C2IdM2` were validated as healthy Site 2 domain controllers for the existing `c2.local` environment.

Validated state:

- `samba-ad-dc` active on both nodes
- replication with Site 1 healthy
- local DNS functional
- DHCP service present and active on both nodes

### Recursive DNS

Initially, Site 2 internal DNS only resolved local Company 2 records and did not forward recursive lookups.

Applied fix:

- added `dns forwarder = 8.8.8.8` to both Site 2 Company 2 DCs
- restarted `samba-ad-dc`

Validated result:

- external lookups such as `archive.ubuntu.com` now resolve through `172.30.65.66` and `172.30.65.67`
- package management on Site 2 can use normal repositories again

### File Server

`C2FS` was implemented as a Samba domain member server and local replica access point.

Validated state:

- joined to `c2.local`
- `smbd` active
- SAN-backed storage mounted at `/mnt/c2_public`
- share paths aligned to Site 1 public/private model

### Linux Client

`C2LinuxClient` was validated as:

- domain joined
- SSH reachable
- able to resolve domain users
- able to access the Site 2 Samba shares as a Company 2 user


## 11. Company 2 Storage and iSCSI

### Storage Path

Observed on `C2FS`:

- active iSCSI session to `172.30.65.194:3260`
- target IQN: `iqn.2024-03.org.clearroots:c2san`
- block device: `sdb`
- mounted share root: `/mnt/c2_public`

### Traffic Isolation

The implementation uses:

- LAN addressing for user and domain traffic
- a separate SAN path for iSCSI traffic

This supports the project requirement that iSCSI traffic be isolated from user-generated traffic.


## 12. Company 2 File Share Structure at Site 2

### Implemented Paths

The Site 2 file-share layout was aligned to the Site 1 model:

- `C2_Public -> /mnt/c2_public/Public`
- `C2_Private -> /mnt/c2_public/Private/%U`

### Access Model

Public behavior:

- shared content area
- visible to authorized Company 2 users

Private behavior:

- per-user private path using `%U`
- user should only see content for the logged-in account

### Group Model

Site 2 uses the group:

- `c2_file_users`

This group is used to control file-share access and ownership alignment on the Site 2 replica side.


## 13. Company 2 Validation Performed

### Identity Validation

Validated:

- `C2IdM1` healthy
- `C2IdM2` healthy
- AD replication healthy
- Company 2 DNS healthy
- recursive DNS healthy after forwarder fix

### File Service Validation

Validated:

- Samba domain member role on `C2FS`
- public/private share model present
- SAN-backed storage mounted and in use

### Client Validation

Validated:

- `employee1@c2.local` resolves on `C2LinuxClient`
- `employee1` can access `C2_Public`
- `employee1` can access `C2_Private`
- expected user-private visibility model works

### Replication Validation

Validated:

- Site 1 public and private structures can be pulled to Site 2
- Site 2 replica content reflects Site 1 master structure
- sync script executed successfully in manual testing


## 14. Synchronization Automation

### Objective

Automate Site 2 pull-based synchronization from Site 1 without making any changes to Site 1.

### Automation Prerequisites

Completed prerequisites:

- recursive DNS fixed on Site 2
- `sshpass` installed on `C2FS`

### Sync Script

Deployed on `C2FS`:

- `/usr/local/bin/c2_site1_sync.sh`

Validated final state:

- owner: `root:root`
- mode: `700`

### Script Behavior

The script:

- pulls `Public` from Site 1
- pulls `Private` from Site 1
- stages content temporarily on Site 2
- mirrors staged content into the live Site 2 share paths
- reapplies expected group and permission alignment

### Logging

Log file:

- `/var/log/c2_site1_sync.log`

Validated successful log flow included:

- `Starting Site1 -> Site2 C2 sync`
- `Pulling Public from 172.30.64.146:/mnt/sync_disk/Public`
- `Pulling Private from 172.30.64.146:/mnt/sync_disk/Private`
- `Sync completed successfully`

### Schedule

Configured cron schedule on `C2FS`:

```cron
0 2 * * * /usr/local/bin/c2_site1_sync.sh >> /var/log/c2_site1_sync.log 2>&1
```

This means Site 2 performs a daily pull sync from Site 1 at 02:00.


## 15. Why Company 2 Uses Master-to-Replica Instead of Full Active-Active Sync

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


## 16. Changes Applied in This Phase

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


## 17. Explicit Non-Changes

No changes were made to Site 1 during this phase.

Site 1 was used only as:

- architectural reference
- read-only validation source
- content master for Site 2 replication

This is an important project note and should remain explicit in later revisions.


## 18. Risks and Operational Notes

Current operational assumptions:

- Site 1 remains the authority for shared Company 2 content
- Site 2 should not be treated as the primary authoring location
- local edits made only at Site 2 may be overwritten by later pull sync runs

This behavior is expected under the chosen master/replica model.


## 19. Remaining Follow-Up Items

This is the baseline implementation document. Likely next improvements include:

- documenting exact DHCP scopes and failover behavior
- adding Windows client implementation details
- documenting Veeam backup separately from replication
- appending final config excerpts for Samba, DNS, and cron
- adding screenshots and validation evidence as appendices
- deciding whether future phases should remain master/replica or move toward a more advanced multi-site storage design


## 20. Security Note

Credentials used during implementation are intentionally excluded from this document.

Administrative usernames, hostnames, IPs, jump paths, and service behavior are documented. Passwords and secrets should remain in a separate secure record.


## 21. Initial Appendix Placeholders

Future revisions can add:

- Appendix A: command transcript extracts
- Appendix B: final Samba config excerpts
- Appendix C: DNS and DHCP config excerpts
- Appendix D: validation screenshots
- Appendix E: sync script listing


## 22. Change Log

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



## 23. Current Cross-Site Position

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


## 24. Clarification: Replication vs Backup

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
- Added requirement traceability matrices and repeatable validation commands for both Company 1 and Company 2
- Added configuration appendix, redacted sync automation details, troubleshooting guidance, and a presentation runbook



## 25. Requirement Traceability Matrix

### Company 1 Requirement Status

| Requirement | Current status | Validation basis |
|---|---|---|
| Web Server in DMZ | Confirmed | Live MSP-path HTTP check returned `HTTP 200` from `172.30.65.162` and Site 1 handover identifies a DMZ IIS server |
| DNS services for local name resolution | Confirmed | DNS-related ports open on both DCs and Site 1 handover documents Windows DNS on both Company 1 DCs |
| Separate DNS services for recursive name resolution | Documented | Site 1 handover states Company 1 DNS resolved external domains successfully and uses a forwarder |
| Fault tolerant / replicated file server | Documented and partially evidenced | Site 1 handover documents DFS namespace + DFS replication; `C1DFS` SMB path is reachable from MSP validation path |
| Active Directory or LDAP | Confirmed | Kerberos / LDAP / SMB / WinRM / RDP ports open on both DCs |
| 2 client machines, 1 Linux and 1 Windows | Documented | Present in Site 1 handover inventory; not revalidated live in this pass |
| Fault tolerant DHCP | Documented | Site 1 handover documents Windows DHCP hot-standby between `C1DC1` and `C1DC2` |
| iSCSI target | Documented | Site 1 handover documents Company 1 SAN presentation from Server2 |
| iSCSI initiator | Documented | Site 1 handover documents Company 1 server/client initiators on SAN VLAN 40 |
| Client access to file shares | Documented | Site 1 handover documents DFS mappings and client validation |
| User accounts mapped/mounted | Documented | Site 1 handover documents Windows H:/P: mappings and Linux CIFS mounts |
| iSCSI traffic isolated | Documented | Site 1 handover documents dedicated SAN VLAN 40 and direct SAN addresses |
| Windows client reachable by RDP from college network | Confirmed by access-path evidence | RDP service reachable on MSP-accessed Company 1 Windows systems; handover states managed RDP path is enabled |

### Company 2 Requirement Status

| Requirement | Current status | Validation basis |
|---|---|---|
| DNS services for local name resolution | Confirmed | `C2IdM1` and `C2IdM2` active; domain resolution and Samba AD services validated |
| DNS services for recursive name resolution | Confirmed | `dns forwarder` configured on Site 2 DCs; external name resolution validated after change |
| Fault tolerant / replicated file server | Confirmed under master/replica model | Site 2 share layout aligned to Site 1, content pulled from Site 1, and scheduled sync enabled |
| Active Directory or LDAP | Confirmed | `C2IdM1` and `C2IdM2` healthy with successful replication |
| 1 client desktop operating system | Confirmed | `C2LinuxClient` domain joined and validated |
| Fault tolerant DHCP | Partially confirmed | DHCP service active on both Site 2 Company 2 DCs; detailed scope/failover behavior should still be appended later |
| iSCSI target | Confirmed | `C2SAN` is the active target endpoint for `C2FS` |
| iSCSI initiator | Confirmed | `C2FS` maintains an active iSCSI session to `C2SAN` |
| Client access to file shares | Confirmed | `employee1` successfully accessed `C2_Public` and `C2_Private` from `C2LinuxClient` |
| User accounts mapped/mounted | Confirmed | CIFS mount on `C2LinuxClient` validated and file creation succeeded |
| iSCSI traffic isolated | Confirmed | SAN-side IPs `172.30.65.194/195` are separate from client/domain LAN path |
| Linux client accessible by SSH from college network | Confirmed by project validation path | `C2LinuxClient` SSH service validated through administrative path; direct college routing policy remains environment-dependent |


## 26. Project Validation Commands

This section collects the most useful project-scope validation commands so that later re-testing can be performed consistently. Unless otherwise stated, the commands below are read-only.

### Company 1 Validation Commands

#### MSP Jump-Path Network Checks

Run from the MSP Ubuntu jump context:

```bash
# Domain controllers and Windows service reachability
for h in 172.30.65.2 172.30.65.3 172.30.65.10 172.30.65.162; do
  ping -c 1 -W 1 "$h"
done

# Representative port checks
for p in 53 88 135 139 389 445 3389 5985; do
  timeout 1 bash -lc '</dev/tcp/172.30.65.2/'"$p"'' && echo "C1DC1 port $p open"
done
```

#### Company 1 Web Server Test

Run from the MSP Ubuntu jump context:

```bash
curl -I --max-time 5 http://172.30.65.162
```

Expected result:

- `HTTP/1.1 200 OK`
- `Server: Microsoft-IIS/10.0`

#### Company 1 Windows-Host Interactive Checks (RDP Session)

If an RDP session is available to Company 1 Windows servers, useful validation commands include:

```powershell
hostname
ipconfig /all
Get-Service DNS, NTDS, DFSR, DFS, DHCPServer
Get-SmbShare
Get-DfsnRoot
Get-DfsnFolder -Path "\\c1.local\namespace\*"
Get-DfsrState
Get-DhcpServerv4Scope
Get-IscsiSession
```

These commands were not all executed in this phase because Company 1 remained read-only and was owned by a different teammate. They are included here as the recommended validation pack for the next review cycle.

### Company 2 Validation Commands

#### `C2IdM1` and `C2IdM2`

```bash
hostname
ip -br a
sudo systemctl is-active samba-ad-dc
sudo samba-tool drs showrepl | head -n 20
host archive.ubuntu.com 127.0.0.1
```

Expected result:

- correct host identity
- active `samba-ad-dc`
- healthy replication with Site 1
- successful recursive resolution

#### `C2FS`

```bash
hostname
ip -br a
realm list
sudo systemctl is-active smbd
sudo testparm -s
mount | grep c2_public
lsblk
sudo iscsiadm -m session
ls -ld /mnt/c2_public /mnt/c2_public/Public /mnt/c2_public/Private
getent group c2_file_users
```

Expected result:

- domain member state present
- `smbd` active
- active iSCSI session to `172.30.65.194:3260`
- SAN-backed storage mounted under `/mnt/c2_public`
- `c2_file_users` resolves locally

#### `C2LinuxClient`

```bash
hostname
ip -br a
realm list
id employee1@c2.local
mount | grep c2_public_test
```

Expected result:

- domain member state present
- `employee1@c2.local` resolves
- CIFS test mount visible when mounted

#### Company 2 Share Access Test

```bash
sudo umount ~/c2_public_test 2>/dev/null
mkdir -p ~/c2_public_test
sudo mount -t cifs //172.30.65.68/C2_Public ~/c2_public_test -o rw,username=employee1,domain=C2,vers=3.0,sec=ntlmssp,uid=$(id -u),gid=$(id -g),file_mode=0660,dir_mode=0770
mount | grep c2_public_test
echo "hello from employee1" > ~/c2_public_test/test-from-employee1.txt
cat ~/c2_public_test/test-from-employee1.txt
ls -l ~/c2_public_test
```

Private-share validation:

```bash
smbclient //172.30.65.68/C2_Private -W C2 -U employee1 -c ls
```

Expected behavior:

- public area visible and writable for authorized user
- private area shows only the logged-in user's own path/content

#### Company 2 Sync Automation Checks

```bash
sudo ls -l /usr/local/bin/c2_site1_sync.sh
sudo crontab -l
sudo tail -n 50 /var/log/c2_site1_sync.log
```

Expected result:

- script exists and is executable
- root cron contains the scheduled sync entry
- log shows successful pull activity from Site 1


## 27. Acceptance-Test Summary

### Minimum Acceptable Project Evidence for Company 1

The project can reasonably claim Company 1 compliance when the following evidence set is available:

- `C1DC1` and `C1DC2` respond on DNS / Kerberos / LDAP / SMB / RDP / WinRM ports
- `C1WebServer` returns `HTTP 200` and identifies as IIS
- Site 1 handover shows DFS namespace, DFS replication, DHCP hot-standby, and SAN/iSCSI mapping
- RDP management path is available through the MSP / jump workflow

### Minimum Acceptable Project Evidence for Company 2

The project can reasonably claim Company 2 compliance when the following evidence set is available:

- `C2IdM1` and `C2IdM2` show healthy `samba-ad-dc` state and replication
- `C2FS` shows active iSCSI session and mounted SAN-backed storage
- `C2LinuxClient` is domain joined and resolves `employee1@c2.local`
- `employee1` can access `C2_Public` and `C2_Private` according to the expected visibility rules
- Site 1 -> Site 2 sync automation is present and logged as successful


## 28. Recommended Next Documentation Upgrades

To make this document stronger in the next revision, the following additions are recommended:

- append actual screenshots for the Company 1 RDP windows and Company 2 Linux validation steps
- append the final `smb.conf` share snippets from `C2FS`
- append the exact Site 2 sync script body
- append Company 2 DHCP config excerpts and scope values
- append a one-page "demo script" showing the exact order in which to prove project success live
- add a concise Company 1 / Company 2 side-by-side comparison table on one page for presentation use


## 29. Configuration Appendix

This appendix captures the most relevant implementation snippets for repeatability and later comparison. Sensitive values are intentionally redacted.

### Site 2 Company 2 Samba Share Model (`C2FS`)

The implemented share intent on `C2FS` is aligned to the Site 1 Company 2 model:

```ini
[C2_Public]
   path = /mnt/c2_public/Public
   browseable = yes
   read only = no
   valid users = @"c2_file_users"
   force group = "c2_file_users"
   create mask = 0770
   directory mask = 0770

[C2_Private]
   path = /mnt/c2_public/Private/%U
   browseable = no
   read only = no
   valid users = %U
   force group = "c2_file_users"
   create mask = 0700
   directory mask = 0700
```

The key behavior target is:

- `Public` is shared among authorized Company 2 users
- `Private` resolves dynamically to the logged-in user's own directory
- users should not browse other users' private content through the published share path

### Site 2 Recursive DNS Forwarder Intent

The Site 2 Company 2 DCs were updated so that Samba AD DNS supports external recursive lookups.

Representative `smb.conf` line on both `C2IdM1` and `C2IdM2`:

```ini
dns forwarder = 8.8.8.8
```

This was validated by resolving an external package repository host after the change.

### Site 2 Sync Automation Schedule

Root crontab entry on `C2FS`:

```cron
0 2 * * * /usr/local/bin/c2_site1_sync.sh >> /var/log/c2_site1_sync.log 2>&1
```

This means the Company 2 Site 2 replica performs a daily pull from Site 1 at `02:00`.

### Redacted Site 2 Sync Script

The deployed sync script was captured locally and is reproduced below with credentials removed:

```bash
#!/bin/bash
set -euo pipefail

LOG_FILE=/var/log/c2_site1_sync.log
SITE1_HOST=172.30.64.146
SITE1_USER=admindc
SITE1_PASS='<REDACTED>'
SITE1_SUDO_PASS='<REDACTED>'
SRC_BASE=/mnt/sync_disk
DEST_BASE=/mnt/c2_public
TMP_BASE=$(mktemp -d /tmp/c2_site1_sync.XXXXXX)

cleanup() {
  rm -rf "$TMP_BASE"
}
trap cleanup EXIT

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"
}

pull_tree() {
  local name="$1"
  local src="$SRC_BASE/$name"
  local stage="$TMP_BASE/$name"
  local dest="$DEST_BASE/$name"

  mkdir -p "$stage" "$dest"
  log "Pulling $name from ${SITE1_HOST}:$src"
  sshpass -p "$SITE1_PASS" ssh -o StrictHostKeyChecking=no "${SITE1_USER}@${SITE1_HOST}" \
    "echo '$SITE1_SUDO_PASS' | sudo -S -p '' tar -C '$src' -cpf - ." | tar -C "$stage" -xpf -

  log "Mirroring staged $name into $dest"
  rsync -aH --delete "$stage"/ "$dest"/
}

log 'Starting Site1 -> Site2 C2 sync'
pull_tree Public
pull_tree Private

chgrp -R c2_file_users "$DEST_BASE/Public"
chmod -R g+rwX "$DEST_BASE/Public"
find "$DEST_BASE/Public" -type d -exec chmod g+s {} +
chgrp c2_file_users "$DEST_BASE/Private"
chmod 0711 "$DEST_BASE/Private"

for d in "$DEST_BASE/Private"/*; do
  [ -d "$d" ] || continue
  user_name="$(basename "$d")"
  if id "$user_name" >/dev/null 2>&1; then
    chown "$user_name":c2_file_users "$d"
    chmod 0700 "$d"
  else
    chown root:c2_file_users "$d"
    chmod 0711 "$d"
  fi
done

log 'Sync completed successfully'

```

### Operational Meaning of the Sync Script

The script performs the following actions:

1. creates a temporary staging directory on `C2FS`
2. pulls `Public` from Site 1 Company 2 using remote `sudo tar`
3. pulls `Private` from Site 1 Company 2 using remote `sudo tar`
4. mirrors both trees into the active Site 2 share paths using `rsync --delete`
5. reapplies Site 2-side ownership and permission expectations
6. writes progress and completion markers into `/var/log/c2_site1_sync.log`


## 30. Troubleshooting Guide

### Company 2 DNS Symptoms

Problem indicators:

- `apt update` fails on Site 2 Linux hosts
- internal DNS works but external names return `NXDOMAIN`

Primary checks:

```bash
host archive.ubuntu.com 172.30.65.66
host archive.ubuntu.com 172.30.65.67
```

Likely cause:

- recursive forwarding is missing on `C2IdM1` / `C2IdM2`

### Company 2 Share Access Symptoms

Problem indicators:

- mount succeeds but writes fail
- `smbclient` can list shares but cannot enter a share
- private data visibility is wrong

Primary checks:

```bash
sudo testparm -s
getent group c2_file_users
ls -ld /mnt/c2_public /mnt/c2_public/Public /mnt/c2_public/Private
id employee1@c2.local
smbclient //172.30.65.68/C2_Public -W C2 -U employee1 -c ls
smbclient //172.30.65.68/C2_Private -W C2 -U employee1 -c ls
```

Likely causes:

- share paths do not match the intended Site 1-style model
- group ownership is misaligned
- the expected private directory does not exist for the user

### Company 2 Sync Symptoms

Problem indicators:

- Site 2 content does not match Site 1
- expected files are missing in `Public` or `Private`
- automation log stops updating

Primary checks:

```bash
sudo ls -l /usr/local/bin/c2_site1_sync.sh
sudo crontab -l
sudo tail -n 100 /var/log/c2_site1_sync.log
```

Likely causes:

- SSH or password-based pull from Site 1 failed
- recursive DNS failure prevented prerequisite package use earlier
- remote Site 1 content changed but automation has not run yet

### Company 1 Assessment Limitations

The Company 1 section of this document should be interpreted carefully:

- live validation was performed through the MSP jump path
- no Company 1 configuration changes were made
- some Company 1 requirements are confirmed directly
- others remain documented-by-reference from the official Site 1 handover

This is intentional and should remain explicit in later revisions.


## 31. Demo / Presentation Runbook

A concise live demonstration can be performed in the following order.

### Company 1 Demo Flow

1. Show MSP jump reachability
2. Show `C1DC1` and `C1DC2` service reachability (DNS / Kerberos / LDAP / RDP)
3. Show `C1WebServer` returning `HTTP 200`
4. Explain that Company 1 storage and DFS are already documented in the Site 1 handover

### Company 2 Demo Flow

1. Show `C2IdM1` or `C2IdM2` replication health
2. Show `C2FS` iSCSI session and mounted storage
3. Show `C2LinuxClient` domain membership
4. Mount `C2_Public` from `C2LinuxClient` as `employee1`
5. Write a file into `C2_Public`
6. Show `C2_Private` only exposing the user's own content
7. Show the sync log on `C2FS`

### Key Demo Talking Points

- Site 1 and Site 2 Company 2 are the same company, not separate tenants
- Site 1 remains the content authority
- Site 2 provides local access using a synchronized replica
- this design is replication, not backup
- Veeam belongs to the backup scope and is separate from file-share replication


## 32. Known Technical Debt and Open Questions

The following items are known and should be tracked in later revisions:

- Company 2 DHCP needs a stronger config-level appendix, not just service-state confirmation
- Company 1 DFS and DHCP were not re-validated interactively through a full Windows admin session in this phase
- Company 2 sync currently uses password-based pull logic because Site 1 was intentionally left unchanged
- a future cleanup could replace stored-password pull logic with a more tightly controlled read-only sync identity if Site 1 ownership permits it
- the current document is comprehensive by design; a shorter final submission version should later be derived from it


## 33. Expanded Appendix Placeholders

Future revisions can further add:

- Appendix A: exact Company 1 MSP jump scan output
- Appendix B: final `C2FS` Samba config excerpt from the live host
- Appendix C: live `C2IdM1` and `C2IdM2` DNS config excerpts
- Appendix D: live `C2FS` iSCSI evidence output
- Appendix E: validation screenshots grouped by requirement
- Appendix F: one-page final submission summary derived from this full working document
