---
title: "Site 2 Demo Test Runbook"
subtitle: "Role-Based Validation Guide for Final Project Demonstration"
author: "Raspberry Pioneers"
date: "March 20, 2026"
toc: true
toc-title: "Contents"
---

# Site 2 Demo Test Runbook

Purpose: provide a simple, role-based demo guide for team members who did not build the project directly.  
Audience: 6-person demo team  
Important note: prefer controlled Tailscale and jump-host paths during the demo. OPNsense public publishing is not yet in final hardened state, so public NAT behavior should be treated as optional rather than as the primary proof path.

## 1. Demo structure

Recommended order:
1. Opening and service block map
2. Remote access and jump hosts
3. Identity, DNS, and account administration
4. DNS and HTTPS core service proof
5. File replication and storage
6. Backup and offsite copy

## 2. Team role assignment

## Role 1: Main presenter

Responsibilities:
- open the service block diagram
- explain the two-site model
- narrate transitions between sections

Suggested talking points:
- Site 2 is responsible for Company 2 services and MSP functions
- access is controlled through jump hosts and OPNsense
- identity, storage, replication, and backup were all implemented for the live service-block demo

Primary evidence:
- service block matrix
- final documentation overview page

## Role 2: Remote access and firewall operator

Responsibilities:
- show Tailscale or jump access
- show OPNsense interfaces and OpenVPN routing if needed

Preferred proof path:
- Tailscale access to Windows jump
- Tailscale access to Ubuntu jump
- internal reachability from Ubuntu jump

### GUI steps

1. Open Windows jump access proof or active session.
2. Open Ubuntu jump SSH session.
3. If needed, show OPNsense:
   - Interfaces
   - OpenVPN
   - NAT rules
   - MSP/C1/C2 segmentation rules

### Command proof

Run from local workstation if needed:
```powershell
Test-NetConnection 100.97.37.83 -Port 3389
Test-NetConnection 100.82.97.92 -Port 22
```

Expected outcome:
- both return `TcpTestSucceeded : True`

### Talking point

"We are using the managed jump path as the stable administrative route. This is the preferred demo path because the external OPNsense publishing rules are still broader than the final hardened design."

## Role 3: Identity, DHCP, DNS, and account administration

Responsibilities:
- show Company 2 identity controllers
- show Company 2 user/account resolution
- if needed, show DHCP and DNS consoles or equivalent views

### Ubuntu jump command proof

```bash
host archive.ubuntu.com 172.30.65.66
host archive.ubuntu.com 172.30.65.67
host c2idm1.c2.local 172.30.65.66
host c2idm2.c2.local 172.30.65.67
```

Expected outcome:
- recursive DNS answers from both controllers
- each controller resolves its own FQDN correctly

### Deep read-only identity proof

From the Ubuntu jump:
```bash
sshpass -p admin ssh -o StrictHostKeyChecking=no ofdengiz@172.30.65.66 'hostname; echo admin | sudo -S systemctl is-active samba-ad-dc'
sshpass -p admin ssh -o StrictHostKeyChecking=no ofdengiz@172.30.65.67 'hostname; echo admin | sudo -S systemctl is-active samba-ad-dc'
sshpass -p admin ssh -o StrictHostKeyChecking=no odengiz@172.30.65.70 'getent passwd employee1@c2.local'
```

Expected outcome:
- `c2idm1` and `c2idm2` answer
- `samba-ad-dc` shows `active`
- `employee1@c2.local` resolves on the Linux client

### DHCP note

Because DHCP was not lease-tested in the read-only run, the safest demo method is GUI proof:
- show DHCP scope(s)
- show active reservations or scope configuration
- explain that DHCP is part of the identity/infrastructure service block

## Role 4: DNS and HTTPS core services

Responsibilities:
- show the internal DNS and HTTPS proof path used in the main service-block demo
- keep the live service-block demo on the core internal proof path; the direct Site 2 Linux web server can still be shown afterwards as an implemented web service, but it is not part of the main graded walkthrough

### Internal service proof from Ubuntu jump

```bash
nslookup c1-webserver.c1.local
curl -k -I https://c1-webserver.c1.local
```

Expected outcome:
- `c1-webserver.c1.local` resolves successfully
- `https://c1-webserver.c1.local` returns `200`

### DNS proof for Company 1 internal web name

```bash
host www.lumora.c1.local 172.30.65.2
```

Expected outcome:
- returns:
  - `172.30.65.162`
  - `172.30.64.162`

### Talking point

"For the live service-block demo, we are focusing on the core DNS and HTTPS proof path. The direct Site 2 Linux web server is still a real implemented web service, but we are keeping it outside the main graded walkthrough so the service-block demo stays aligned with the required scope."

## Role 5: Replicated file server and storage

Responsibilities:
- show Company 2 file server
- show mounted storage
- show Site 1 to Site 2 pull sync evidence

### Read-only proof on C2FS

From Ubuntu jump:
```bash
sshpass -p admin ssh -o StrictHostKeyChecking=no odengiz@172.30.65.68 'hostname; echo admin | sudo -S systemctl is-active smbd; mount | grep /mnt/c2_public; echo admin | sudo -S tail -n 5 /var/log/c2_site1_sync.log'
```

Expected outcome:
- hostname `c2fs`
- `smbd` active
- `/dev/sdb` mounted on `/mnt/c2_public`
- sync log ends with `Sync completed successfully`

### Talking point

“The Company 2 file platform is backed by mounted storage and receives scheduled pull synchronization from Site 1. This is a controlled one-way replication workflow, not an active-active full sync.”

### Optional GUI evidence

If a GUI is available, show:
- mounted filesystem
- file-share paths
- sync script path
- log file

## Role 6: Backup and offsite copy

Responsibilities:
- show Site 2 Veeam success
- show offsite copy folder on Site 1 target

### Veeam success proof

Show in Veeam GUI:
- `Site2_Windows_AgentBackup`
- `Site2_Linux_AgentBackup`
- `C1 File Backup Job`
- `C2 File Backup Job`
- `Site2_Offsite_Copy`

Expected outcome:
- all recent jobs show `Success`

### Offsite copy proof

Show target folder:
- `R:\Repo_Site2_Offsite\Site2OffsiteFromSite2`

Expected visible folders:
- `C1 File Backup Job (Copy) 1`
- `C2 File Backup Job (Copy) 1`
- `Site2_Offsite_Copy`

### Veeam network proof from Ubuntu jump

```bash
python3 - <<'PY'
import socket
for port in [445,2049,3389,5985,9392]:
    s=socket.socket(); s.settimeout(2)
    try:
        s.connect(('172.30.65.180',port))
        print(port, 'open')
    except Exception:
        print(port, 'closed')
    finally:
        s.close()
PY
```

Expected outcome:
- the Veeam control ports show open

## 3. Suggested demo sequence by minute

## Minute 0-2

Role 1:
- introduce the service block map
- explain Site 2 tenant and MSP responsibilities

## Minute 2-5

Role 2:
- show jump access
- optionally show OPNsense interface/routing

## Minute 5-8

Role 3:
- show DNS and identity resolution
- explain DHCP proof path through GUI rather than lease churn

## Minute 8-11

Role 4:
- show the core DNS and HTTPS proof path only

## Minute 11-14

Role 5:
- show mounted storage
- show file sync log and explain Site 1 to Site 2 replication

## Minute 14-17

Role 6:
- show Veeam success
- show offsite copy evidence

## 4. Demo-safe fallback plan

If any public NAT test fails:
- do not panic
- switch to Tailscale + jump-host path
- explain that the core service path is intentionally demonstrated through the managed admin route while OPNsense hardening is still in progress

If any GUI is slow:
- use the prepared screenshots
- narrate the expected outcome
- continue to the next role

If time is tight:
- prioritize these six proofs:
  1. jump access
  2. DNS and identity
  3. core DNS/HTTPS proof
  4. file sync log
  5. Veeam success

## 5. Must-have screenshots for the live demo deck

1. Service block matrix
2. Veeam success history
3. offsite copy target folder
4. OPNsense interfaces / OpenVPN / NAT
5. C2FS sync evidence

## 6. Final note for the team

This runbook is intentionally operational rather than theoretical. The goal is not to prove every subsystem exhaustively during the demo, but to show a clean chain of evidence across:
- access
- identity
- DNS and HTTPS core proof
- storage and replication
- backup and offsite recovery

If the team follows the order above, the demo will stay coherent even if one individual proof path becomes unstable.
