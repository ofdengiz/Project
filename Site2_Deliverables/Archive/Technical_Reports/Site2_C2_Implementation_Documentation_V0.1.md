# Site 2 Company 2 Implementation Documentation

Version: 0.1 (living document)
Date: 2026-03-12
Workspace: C:\Algonquin\Winter2026\Emerging_Tech\Project
Reference: Site 1 documentation was used as the primary baseline, especially [Site1_Final_Documentation_V1.96.docx](C:/Algonquin/Winter2026/Emerging_Tech/Project/Site1_Final_Documentation_V1.96.docx).

## 1. Purpose

This document is the initial as-built documentation for Company 2 at Site 2. It records the network layout, service roles, implementation decisions, configuration changes, validation results, and remaining follow-up items.

This is intended to be a living document. We can extend or revise it as the environment changes.

## 2. Scope

This document covers the Company 2 Linux-side infrastructure and service integration at Site 2, including:

- Site 2 identity domain controllers
- Site 2 file server
- Site 2 Linux client
- Site 2 SAN / iSCSI relationship
- Site 1 to Site 2 file replication model
- supporting DNS, DHCP, Samba, Kerberos, and SSH validation

This document does not replace the Site 1 master handover. Instead, it complements it.

## 3. High-Level Design Summary

Company 2 at Site 1 and Site 2 is treated as the same company with a shared identity model and shared file structure.

The implemented model is:

- Site 1 Company 2 = authoritative master for shared file content
- Site 2 Company 2 = replica / secondary access point
- Identity = shared `c2.local` domain
- File access = Samba shares at Site 2
- File content replication = pull-based synchronization from Site 1 to Site 2
- Backup = separate concern and not the same as replication

Important design decision:

This implementation does not use active-active, bi-directional full sync across sites. Instead, it uses a controlled one-way master-to-replica model:

- Site 1 writes are authoritative
- Site 2 receives replicated copies
- Site 2 local users consume the replica shares

This approach was chosen because:

- Site 1 was owned by another teammate and was not to be modified
- Site 1 already had its own internal replicated file service for Company 2
- Site 2 needed to align to Site 1 without redesigning Site 1 storage
- the approach is lower-risk and easier to validate in a course project environment

## 4. Site 2 Host Inventory

### 4.1 Company 2 Hosts

- `C2IdM1` = `172.30.65.66`
- `C2IdM2` = `172.30.65.67`
- `C2FS` = `172.30.65.68`
- `C2LinuxClient` = `172.30.65.70`
- `C2SAN` = `172.30.65.194`

### 4.2 Access Notes

Administrative SSH access was performed through the MSP Ubuntu jump box.

Secrets are intentionally not recorded in this document. Credentials were provided out-of-band during implementation.

## 5. Network and Addressing

### 5.1 Site 2 Company 2 LAN

- Company 2 Site 2 subnet: `172.30.65.64/26`
- Default gateway: `172.30.65.65`
- Domain: `c2.local`
- Kerberos realm: `C2.LOCAL`
- NetBIOS domain: `C2`

### 5.2 Site 2 SAN Segment

- `C2SAN`: `172.30.65.194`
- `C2FS` SAN-side interface: `172.30.65.195`

This SAN path is used for iSCSI traffic and is intentionally separate from user-generated LAN traffic.

### 5.3 Site 1 Company 2 Core References

From Site 1 documentation and live read-only checks:

- `C2-DC1` = `172.30.64.146`
- `C2-DC2` = `172.30.64.147`

## 6. Site 2 Services by Host

### 6.1 C2IdM1

Role:

- Additional Samba AD domain controller for `c2.local`
- DNS for Company 2
- DHCP service node

Validated state:

- hostname resolves as `c2idm1`
- interface on `172.30.65.66/26`
- `samba-ad-dc` active
- replication with Site 1 DCs healthy

### 6.2 C2IdM2

Role:

- Additional Samba AD domain controller for `c2.local`
- DNS for Company 2
- DHCP service node

Validated state:

- hostname resolves as `c2idm2`
- interface on `172.30.65.67/26`
- `samba-ad-dc` active
- replication with Site 1 DCs healthy

### 6.3 C2FS

Role:

- Site 2 Company 2 file server
- Samba domain member
- iSCSI initiator for SAN-backed data disk
- Site 1 content replica target

Interfaces:

- LAN: `172.30.65.68/26`
- SAN: `172.30.65.195/29`

Validated state:

- domain joined as a member server
- `smbd` active
- iSCSI session established to `C2SAN`
- share root mounted at `/mnt/c2_public`

### 6.4 C2LinuxClient

Role:

- Linux client for Company 2
- Domain-joined test client
- SSH-reachable Linux workstation

Validated state:

- IP: `172.30.65.70/26`
- domain joined to `c2.local`
- `employee1@c2.local` resolves correctly
- SSH service active
- able to mount and access Site 2 Company 2 shares

### 6.5 C2SAN

Role:

- iSCSI target for Site 2 Company 2 file storage

Validated indirectly:

- `C2FS` shows an active iSCSI session to `172.30.65.194:3260`
- target IQN observed as `iqn.2024-03.org.clearroots:c2san`
- data disk appears on `C2FS` as `sdb`

## 7. Identity, DNS, DHCP, and Domain Health

### 7.1 Domain Integration

Company 2 Site 2 uses the same Active Directory domain as Site 1:

- Domain: `c2.local`
- Realm: `C2.LOCAL`

`C2IdM1` and `C2IdM2` were joined as additional domain controllers to the existing Site 1 Company 2 domain.

### 7.2 Replication

Read-only validation showed:

- `C2IdM1` healthy
- `C2IdM2` healthy
- replication to Site 1 Company 2 DCs healthy
- no outstanding consecutive replication failures during validation snapshots

### 7.3 Recursive DNS Fix

Originally, Site 2 internal DNS resolved local Company 2 records but did not resolve external names. This blocked package installation and automation tasks.

Fix applied on both `C2IdM1` and `C2IdM2`:

- added `dns forwarder = 8.8.8.8` to `/etc/samba/smb.conf`
- restarted `samba-ad-dc`

Validation after fix:

- `host archive.ubuntu.com 127.0.0.1` succeeded on both DCs
- `host archive.ubuntu.com 172.30.65.66` succeeded from `C2FS`
- `host archive.ubuntu.com 172.30.65.67` succeeded from `C2FS`

This completed the recursive DNS requirement for Company 2.

### 7.4 DHCP

Read-only checks confirmed:

- `isc-dhcp-server` active on `C2IdM1`
- `isc-dhcp-server` active on `C2IdM2`
- Company 2 DHCP configuration files present on both nodes

Detailed DHCP failover behavior should be expanded later if we need a deeper as-built appendix.

## 8. File Service Design

### 8.1 Site 1 Reference Model

From Site 1 documentation and read-only inspection:

- Site 1 Company 2 file service is published from the Site 1 Company 2 DC layer
- Site 1 uses GlusterFS internally across `C2-DC1` and `C2-DC2`
- mounted path on Site 1: `/mnt/sync_disk`
- Site 1 Samba paths:
  - `C2_Public -> /mnt/sync_disk/Public`
  - `C2_Private -> /mnt/sync_disk/Private/%U`

### 8.2 Site 2 Replica Model

Site 2 was aligned to the same public/private structure:

- `C2_Public -> /mnt/c2_public/Public`
- `C2_Private -> /mnt/c2_public/Private/%U`

Behavioral model:

- `Public` = shared area visible to authorized users
- `Private` = user-specific path based on the logged-in username (`%U`)
- users should only see their own private folder content

### 8.3 Current Samba Configuration on C2FS

Current functional design on `C2FS`:

- `C2_Public`
  - `path = /mnt/c2_public/Public`
  - group-based access
- `C2_Private`
  - `path = /mnt/c2_public/Private/%U`
  - per-user private path model

### 8.4 Group-Based Access

A dedicated Company 2 file access group is used:

- AD / winbind group: `c2_file_users`

Validated on `C2FS`:

- `getent group c2_file_users` resolves
- `/mnt/c2_public/Public` and related share paths are aligned to the expected group model

## 9. Storage and iSCSI

### 9.1 Storage Path

`C2FS` uses a SAN-backed disk for file-share data.

Observed:

- active iSCSI session to `172.30.65.194:3260`
- IQN: `iqn.2024-03.org.clearroots:c2san`
- Linux block device: `sdb`
- mounted share root: `/mnt/c2_public`

### 9.2 Traffic Isolation

The design separates:

- user/data LAN traffic on the `172.30.65.64/26` network
- iSCSI storage traffic on the SAN segment (`172.30.65.194` / `172.30.65.195`)

This satisfies the requirement that iSCSI traffic be isolated from user-generated traffic.

## 10. Client Access Validation

### 10.1 Domain Join

`C2LinuxClient` was joined to `c2.local` and validated with domain identity lookups.

Validated examples:

- `id employee1@c2.local`
- `getent passwd employee1@c2.local`

### 10.2 SSH Accessibility

`C2LinuxClient` was confirmed to have SSH active and listening on TCP 22.

### 10.3 Samba Access Validation

Domain user `employee1` successfully accessed the Site 2 Company 2 shares.

Validated behavior:

- `C2_Public` visible and readable
- `C2_Private` visible using `%U` mapping
- file operations worked from the Linux client using SMB mount and `smbclient`

This aligned with the intended model described by the Site 1 teammate:

- Public should expose shared files to authorized users
- Private should expose only the current logged-in user's private content

## 11. Replication Model and Rationale

### 11.1 Implemented Replication Model

The implemented file replication model is:

- Site 1 Company 2 = master
- Site 2 Company 2 = replica
- one-way synchronization from Site 1 to Site 2

This is not Veeam backup.
This is not active-active full sync.
This is not bi-directional replication.

### 11.2 Why This Model Was Chosen

This model was chosen because:

- Site 1 belonged to another teammate and was not to be modified
- Site 1 already had a working internal replicated file service using GlusterFS
- Site 2 needed to mirror Site 1 without redesigning Site 1 storage
- the project still required equivalent share behavior and multi-site access for the same company

### 11.3 What This Means in Practice

Current behavior:

- files created or changed on Site 1 can be replicated to Site 2
- users at Site 2 can access matching `Public` and `Private` structures locally
- Site 2 is not the authority for shared content

Important limitation:

- files created on Site 2 are not automatically pushed back to Site 1
- if Site 2 diverges from Site 1, a later pull sync can overwrite or remove content based on the master state

This is a deliberate design choice.

## 12. Why We Did Not Use Full Cross-Site Active-Active Sync

A full active-active design would have required Site 1 changes.

Read-only inspection of Site 1 showed:

- Site 1 GlusterFS exists only between `172.30.64.146` and `172.30.64.147`
- Site 2 is not a Gluster peer
- Site 2 is not a Gluster brick in the Site 1 volume

Therefore, Site 1 currently supports:

- internal Site 1 replication

but not:

- cross-site shared distributed storage with Site 2

To implement true full sync, Site 1 would have needed additional work such as:

- adding Site 2 nodes as Gluster peers
- expanding the volume to include Site 2 bricks
- opening and validating cross-site Gluster ports
- planning conflict handling and split-brain behavior
- publishing the same distributed dataset through Samba on both sites

Because none of that existed and Site 1 was not to be changed, the master/replica model was selected instead.

## 13. Site 2 Synchronization Automation

### 13.1 Goal

Automate a Site 2 pull from Site 1 without changing Site 1.

### 13.2 Prerequisites Completed

- recursive DNS fixed on Site 2 DCs
- `sshpass` installed on `C2FS`

### 13.3 Sync Script

Deployed on `C2FS`:

- `/usr/local/bin/c2_site1_sync.sh`

Final validated file state:

- owner: `root:root`
- mode: `700`

### 13.4 Script Behavior

The script performs:

- pull of `Public` from Site 1
- pull of `Private` from Site 1
- staging into a temporary area on Site 2
- mirror into Site 2 share paths using `rsync --delete`
- group and permission re-alignment on Site 2 after sync

The script uses a pull pattern from Site 2 and does not modify Site 1.

### 13.5 Logging

Sync log file:

- `/var/log/c2_site1_sync.log`

Observed successful log messages included:

- `Starting Site1 -> Site2 C2 sync`
- `Pulling Public from 172.30.64.146:/mnt/sync_disk/Public`
- `Pulling Private from 172.30.64.146:/mnt/sync_disk/Private`
- `Sync completed successfully`

### 13.6 Schedule

Configured on `C2FS` root crontab:

```cron
0 2 * * * /usr/local/bin/c2_site1_sync.sh >> /var/log/c2_site1_sync.log 2>&1
```

This means the Site 2 pull sync runs every day at 02:00.

## 14. Changes Applied During This Implementation

### 14.1 Site 2 Only

Changes made on Site 2 included:

- joining and validating additional Site 2 DCs
- configuring and validating `C2FS` as a domain-member file server
- configuring `C2_Public` and `C2_Private`
- validating `C2LinuxClient` domain access and SMB access
- validating iSCSI from `C2FS` to `C2SAN`
- adding DNS forwarders to Site 2 Company 2 DCs
- installing `sshpass` on `C2FS`
- deploying and scheduling the Site 2 sync automation

### 14.2 Site 1 Was Not Modified

No Site 1 configuration, service, directory, permission, or share definition was changed during this implementation.

Site 1 was only used as:

- documentation baseline
- read-only reference
- content master for replication

## 15. Validation Summary

At the end of this phase, the following were validated:

- `C2IdM1` healthy
- `C2IdM2` healthy
- AD replication healthy
- Site 2 recursive DNS healthy
- `C2FS` healthy as a Samba member file server
- `C2SAN` iSCSI path active and mounted on `C2FS`
- `C2LinuxClient` domain joined and SSH reachable
- `employee1` resolves correctly and belongs to the intended file access group
- `C2_Public` access works
- `C2_Private` user-private path logic works
- Site 1 to Site 2 pull replication works
- Site 2 scheduled synchronization exists

## 16. Remaining / Future Improvements

This document is the starting point, not the final project handover. Good next follow-up items include:

- documenting the exact DHCP scopes and failover behavior in detail
- documenting Windows client behavior once that side is completed
- documenting Veeam backup separately from replication
- documenting rollback / recovery procedures for the sync script
- documenting exact Samba share stanzas and final config snapshots as appendices
- deciding whether Site 2 should remain a strict replica or evolve toward a more advanced multi-site storage design

## 17. Security Note

Credentials used during implementation are intentionally excluded from this document.

Administrative usernames, jump paths, and service behavior are documented, but passwords and other secrets should remain outside the project documentation or be stored in a protected secrets record.

## 18. Initial Change Log

### 2026-03-11 to 2026-03-12

- Validated Site 2 Company 2 AD DC health
- Validated and configured Site 2 file service model
- Validated Linux client access
- Confirmed SAN-backed iSCSI storage path
- Aligned Site 2 public/private share structure to Site 1 model
- Implemented Site 1 to Site 2 pull replication
- Added Site 2 sync automation
- Completed recursive DNS for Site 2 Company 2
