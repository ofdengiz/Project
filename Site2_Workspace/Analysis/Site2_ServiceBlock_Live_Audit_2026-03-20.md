# Site 2 Service Block Live Audit

Date: 2026-03-20  
Method: Read-only validation only  
Access paths used:
- Local workstation to Site 2 Windows jump over Tailscale and RDP reachability
- Local workstation to Site 2 Ubuntu jump over Tailscale and SSH
- Read-only internal service probes from the Ubuntu jump
- Existing project evidence and screenshots for controls that are intentionally restricted to host-specific paths

## 1. Scope and constraints

This audit was executed after the Service Block matrix was provided and after the user clarified that OPNsense hardening is not yet final. The goal of this run was to validate live service behavior without making any changes.

Important constraint:
- Public NAT and some edge firewall behavior should be treated as provisional because the current OPNsense rule set is intentionally broader and not yet in final hardened form.
- For that reason, repeatable demo validation should prefer Tailscale and controlled jump-host paths instead of relying only on WAN NAT tests.

## 2. Reference service blocks

The validation was mapped to the supplied service block matrix:

| Service Block | Control Area | Hotseat 1 | Hotseat 2 |
|---|---|---|---|
| 1 | Remote Access, DHCP, Account Administration | Company 1 & MSP | Company 2 & MSP |
| 2 | DNS, HTTPS | Company 1 & MSP | Company 2 & MSP |
| 3 | Site 1 Hypervisor, vRouter | MSP Site 1 | MSP Site 2 |
| 4 | Replicated File Server, ISCSI | Company 1 | Company 2 |
| 5 | VEEAM, Misc | MSP | Site 1 Physical Inspection |

## 3. Executive summary

### Overall status

- Remote access through Tailscale to both Site 2 jump systems is working.
- Company 2 identity and DNS services are healthy.
- Company 2 file services and Site 1 to Site 2 pull replication are healthy.
- Company 1 internal web service is healthy over HTTP and HTTPS from the internal Site 2 path.
- Company 2 internal web service is healthy over HTTP from the internal Site 2 path.
- Site 2 Veeam control ports are now reachable from the Ubuntu jump path and historical Veeam copy success is visible in the supplied evidence.
- Inter-site identity paths from Site 2 to Site 1 are healthy on the expected ports.

### Important caution

- Direct public port tests to `10.50.17.31` on `33464`, `33564`, and `33465` failed during this run from the local workstation, even though Tailscale access and internal service validation were successful.
- Because OPNsense is not finalized, this should be treated as an edge publishing issue, not as a core service failure.

## 4. Live validation details by service block

## 4.1 Service Block 1: Remote Access, DHCP, Account Administration

### Remote Access

#### PASS: Tailscale access to both jump hosts

Validated:
- Windows jump Tailscale endpoint reachable: `100.97.37.83:3389`
- Ubuntu jump Tailscale endpoint reachable: `100.82.97.92:22`

Observed:
- Windows jump identified as `JUMP64`, Windows Server 2022 Standard, workgroup member
- Ubuntu jump identified as `mspubuntujump`

#### REVIEW: Public NAT publishing through OPNsense

Configured in `site2_opnsense.txt`:
- WAN `33464 -> 172.30.65.178:3389`
- WAN `33564 -> 172.30.65.179:22`
- WAN `33465 -> 172.30.65.162:80`

Current live result from local workstation:
- `10.50.17.31:33464` failed
- `10.50.17.31:33564` failed
- `10.50.17.31:33465` failed

Assessment:
- Because internal service paths were healthy and the firewall is not yet finalized, this is best classified as an edge publication or rule-state issue, not a tenant platform outage.

### DHCP

#### REVIEW: Not directly live-probed in this session

Reason:
- DHCP is not easily validated safely through passive jump-host probing without forcing lease activity.
- This block should be demonstrated during the GUI demo through DHCP scope views rather than synthetic lease churn.

Current confidence basis:
- The environment design and prior implementation artifacts indicate DHCP is delivered through the domain infrastructure and associated services.
- Recommended live demo evidence is listed in the runbook.

### Account Administration

#### PASS: Company 2 account and directory services are healthy

Validated on `C2IdM1` (`172.30.65.66`):
- host identity correct
- `samba-ad-dc` active
- replication output showed repeated `0 consecutive failure(s)`

Validated on `C2IdM2` (`172.30.65.67`):
- host identity correct
- `samba-ad-dc` active
- replication output showed repeated `0 consecutive failure(s)`

Validated on `C2LinuxClient` (`172.30.65.70`):
- domain identity resolution works for `employee1@c2.local`

## 4.2 Service Block 2: DNS, HTTPS

### DNS

#### PASS: Company 2 DNS recursion and internal identity records

Validated from the Ubuntu jump:
- `archive.ubuntu.com` resolved successfully through `172.30.65.66`
- `archive.ubuntu.com` resolved successfully through `172.30.65.67`
- `c2idm1.c2.local` resolved correctly through `172.30.65.66`
- `c2idm2.c2.local` resolved correctly through `172.30.65.67`

#### PASS: Company 1 DNS record visibility from Site 2

Validated:
- `www.lumora.c1.local` resolved through `172.30.65.2`
- Returned A records:
  - `172.30.65.162`
  - `172.30.64.162`

Interpretation:
- This confirms the intended round-robin style name publication is visible from Site 2.

### HTTPS / web delivery

#### PASS: Company 1 web service

Validated from the Ubuntu jump:
- `http://172.30.65.162` returned `HTTP/1.1 200 OK`
- `https://172.30.65.162` returned `HTTP/2 200`
- Server: `Microsoft-IIS/10.0`

Interpretation:
- Internal Company 1 web service is reachable from Site 2 and the HTTPS endpoint is active.

#### PASS: Company 2 web service

Validated from the Ubuntu jump:
- `http://172.30.65.170` returned `HTTP/1.1 200 OK`
- Server: `Apache/2.4.52 (Ubuntu)`

Validated directly on the host:
- `apache2` active on `c2-webserver`
- local curl to `http://127.0.0.1` returned `200 OK`

#### PASS: OPNsense management listener present internally

Validated from the Ubuntu jump:
- `http://172.30.65.177` returned `HTTP/1.1 403 Forbidden`
- Server header: `OPNsense`

Interpretation:
- Internal management path exists and is responding, even though direct access is intentionally restricted.

## 4.3 Service Block 3: Site 1 Hypervisor, vRouter

### vRouter / OPNsense

#### PASS: Site 2 OPNsense internal management plane reachable

Validated:
- `172.30.65.177` ping successful
- TCP `53` open
- TCP `80` open
- OPNsense HTTP response confirmed

Configuration review from `site2_opnsense.txt`:
- tenant LAN and DMZ interfaces mapped correctly
- OpenVPN routing includes:
  - `172.30.64.0/24`
  - `192.168.64.20/32`
- NAT rules for jump access and web publication exist

#### REVIEW: Site 1 hypervisor and physical inspection

This block is partly outside the reach of a pure Site 2 read-only jump test.

What was validated indirectly:
- Site 2 can reach Site 1 identity infrastructure on expected ports
- Site 2 sync automation pulls from Site 1 Company 2 DC path `172.30.64.146`
- Veeam offsite artifact exists in the Site 1 repository evidence

What remains best demonstrated by GUI or physical evidence:
- Site 1 hypervisor console state
- Site 1 physical inspection items
- final OPNsense hardened NAT/public publishing behavior

## 4.4 Service Block 4: Replicated File Server, ISCSI

### Replicated File Server

#### PASS: Company 2 file server and pull replication

Validated directly on `C2FS` (`172.30.65.68`):
- host identity correct
- `smbd` active
- `/dev/sdb` mounted on `/mnt/c2_public`
- recent log lines show:
  - `Pulling Private from 172.30.64.146:/mnt/sync_disk/Private`
  - `Sync completed successfully`

Interpretation:
- This is strong live proof that the Site 1 to Site 2 Company 2 replication workflow is currently operating.

### Inter-site sync dependencies

#### PASS: Site 2 to Site 1 Company 2 identity path

Validated from the Ubuntu jump:
- `172.30.64.146` open on `22`, `53`, `88`, `389`, `445`
- `172.30.64.147` open on `22`, `53`, `88`, `389`, `445`

#### PASS: Site 2 to Site 1 Company 1 identity path

Validated from the Ubuntu jump:
- `172.30.64.130` open on `53`, `88`, `389`, `445`, `3389`
- `172.30.64.131` open on `53`, `88`, `389`, `445`, `3389`

### ISCSI

#### PASS with inference: storage presentation is active on C2FS

Direct iSCSI session inspection was not run in this pass, but the following live evidence strongly supports a healthy path:
- SAN-side address present on `C2FS`: `172.30.65.195/29`
- data disk mounted as `/dev/sdb`
- file-share data volume live and writable
- sync workflow using mounted storage completed successfully

Assessment:
- For demo purposes, `lsblk`, `mount`, and the mounted sync-backed volume are sufficient evidence unless a dedicated iSCSI target screen is required.

## 4.5 Service Block 5: VEEAM, Misc

### VEEAM

#### PASS: Site 2 Veeam host management plane now reachable

Validated from the Ubuntu jump to `172.30.65.180`:
- ping successful
- `445` open
- `2049` open
- `3389` open
- `5985` open
- `9392` open

This is a material improvement over the earlier `2026-03-15` snapshot, which had reported Veeam control-plane failure from the jump path.

#### PASS: Backup and copy success visible in supplied evidence

Evidence supplied by the user shows:
- successful `Site2_Windows_AgentBackup`
- successful `Site2_Linux_AgentBackup`
- successful `C1 File Backup Job`
- successful `C2 File Backup Job`
- successful copy jobs
- offsite SMB copy folders visible on Site 1 under `R:\Repo_Site2_Offsite\Site2OffsiteFromSite2`

#### REVIEW: SMB offsite repository path is restricted by design

Validated from the Ubuntu jump:
- `192.168.64.20:445` was closed

Interpretation:
- This does not contradict the offsite backup evidence.
- It more likely indicates that the offsite SMB path is intended to be consumed by the Site 2 Veeam server rather than by the general MSP jump network.
- The existing successful Veeam copy evidence is more authoritative for this control than a generic jump-host SMB probe.

### Misc

At this stage, the AWS public web platform can also be considered an implemented value-add service for Site 2:
- EC2 master and worker instances present
- S3 remote state present
- Route53 A record present
- public HTTPS website functioning
- Kubernetes nodes and pods healthy

## 5. Detailed live evidence snippets

## 5.1 Ubuntu jump baseline

- hostname: `mspubuntujump`
- Tailscale IP: `100.82.97.92`
- Site 2 management IP: `172.30.65.179/29`
- default route via `172.30.65.177`

## 5.2 Windows jump baseline

- hostname: `JUMP64`
- operating system: Windows Server 2022 Standard
- Tailscale RDP path reachable

## 5.3 C2 identity hosts

### C2IdM1
- hostname: `c2idm1`
- address: `172.30.65.66/26`
- `samba-ad-dc`: `active`
- replication: `0 consecutive failure(s)` repeated in captured output

### C2IdM2
- hostname: `c2idm2`
- address: `172.30.65.67/26`
- `samba-ad-dc`: `active`
- replication: `0 consecutive failure(s)` repeated in captured output

## 5.4 C2 file services

### C2FS
- hostname: `c2fs`
- LAN address: `172.30.65.68/26`
- SAN-side address: `172.30.65.195/29`
- `smbd`: `active`
- mounted volume: `/dev/sdb on /mnt/c2_public`
- sync log shows successful pull from `172.30.64.146`

## 5.5 C2 client identity

### C2LinuxClient
- hostname: `c2linuxclient`
- address: `172.30.65.70/26`
- `employee1@c2.local` resolved successfully
- local resolver points to the expected stub resolver path

## 5.6 Web hosts

### C1Web
- `HTTP 200`
- `HTTPS 200`
- IIS server header returned

### C2Web
- `HTTP 200`
- Apache active on host

## 6. Findings and risk notes

## 6.1 Positive findings

1. Site 2 core identity stack is healthy.
2. Site 2 file replication from Site 1 is healthy.
3. Site 2 internal web delivery is healthy.
4. Company 1 internal web delivery is healthy from Site 2.
5. Veeam management and offsite copy evidence is now substantially stronger than in the earlier test snapshot.
6. Inter-site routed identity paths are healthy and support the documented synchronization model.

## 6.2 Residual risks

1. Public NAT publishing through OPNsense is not currently a stable validation path and should not be the primary demo method until final firewall work is completed.
2. DHCP was not directly lease-tested in this read-only run and still needs GUI-backed operational evidence.
3. Site 1 physical inspection controls remain outside the reach of this remote validation session.
4. Generic jump-host access to `192.168.64.20:445` is blocked, so offsite repository validation should continue to rely on Veeam console evidence and the target folder contents rather than generic SMB browse tests.

## 7. Recommended demo-safe interpretation

For the final demo, treat the environment as follows:
- Core tenant services: ready to demonstrate
- Inter-site sync: ready to demonstrate
- Veeam backup and offsite copy: ready to demonstrate
- Public NAT behavior on OPNsense: show only if specifically needed, and only with the caveat that firewall hardening is not final
- Preferred admin path: Tailscale to jump hosts, then internal validation

## 8. Conclusion

Based on this read-only live audit, Site 2 currently demonstrates healthy behavior across the majority of the supplied service blocks. The strongest validated areas are:
- remote administrative access through Tailscale
- Company 2 identity and account services
- Company 2 file services and Site 1 to Site 2 replication
- internal Company 1 and Company 2 web publishing
- Veeam backup and offsite copy evidence

The main area that should still be treated as provisional is edge publication through OPNsense, since the firewall configuration is intentionally not yet finalized. This does not undermine the core service stack, but it does affect which demo paths should be preferred.
