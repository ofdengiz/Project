# CODEX PROMPT — SITE 2 TECHNICAL REPORT (VERSION 5.0, FROM SCRATCH)

You are a senior infrastructure engineer and technical writer producing a formal, client-ready handover document for Site 2 of a multi-tenant managed service environment. This is a real college project submission. The document must be written entirely from scratch. You will write this as if you personally connected to Site 2 through both MSPUbuntuJump (Linux bastion, 172.30.65.179) and Jump64 (Windows bastion, 172.30.65.178) and conducted a systematic, hands-on operational inspection of every service in the environment.

---

## DOCUMENT PURPOSE AND AUDIENCE

This is a formal technical design, validation, and handover report. It must be readable and useful to three distinct audiences simultaneously:
- Client IT staff taking over day-to-day administration
- MSP support teams troubleshooting or making changes later
- Academic assessors evaluating whether the documented environment is complete, coherent, and technically defensible

The document must demonstrate: what was built, why it was designed this way, what was directly observed and validated, and what a support team needs to know to operate the site without a separate verbal walkthrough.

---

## STRUCTURAL REQUIREMENTS (mandatory — do not deviate)

Produce the document with the following top-level structure, in this exact order:

1. Title Page
2. Table of Contents
3. List of Figures (with placeholder captions — figures will be added manually)
4. List of Tables
5. Executive Summary
6. Section 1: Introduction
7. Section 2: Background
   - 2.1 Intended Audience and Support Scope
   - 2.2 Design Context and Operating Model
   - 2.3 Evidence Base, Observation Method, and Evidence Classes
8. Section 3: Discussion
   - 3.1 Environment Overview and Service Boundaries
   - 3.2 Service Inventory and Platform Layout
   - 3.3 MSP Entry, Network Segmentation, Remote Access, and Security
   - 3.4 Company 1 Directory Services, File Services, Web Delivery, and Client Access
   - 3.5 Company 2 Identity Services, DNS, DHCP, and Shared Forest Design
   - 3.6 Storage, File Services, and Isolated SAN Design
   - 3.7 Client Access, Identity Validation, and Dual-Hostname Web Delivery
   - 3.8 Backup, Recovery, and Offsite Protection
   - 3.9 Requirement-to-Implementation Traceability
   - 3.10 Service Dependencies, Failure Domains, and Access Model
   - 3.11 Data Protection Flow
   - 3.12 Maintenance and Routine Checks
   - 3.13 Troubleshooting and Fast Triage Guide
   - 3.14 Integrated Design Summary
   - 3.15 Limitations and Outstanding Items
9. Section 4: Conclusion
10. Section 5: Appendices
    - Appendix A: Observed Addressing, Gateways, and Endpoints
    - Appendix B: Evidence and Reference Traceability
    - Appendix C: Service Verification Matrix
    - Appendix D: Unresolved Items and Known Gaps
    - Appendix E: Sanitized SMB Configuration Excerpt (C2FS)
11. Section 6: References (IEEE format)

---

## TITLE PAGE CONTENT

- Title: Site 2 Infrastructure Deployment — Integrated Technical Design, Validation, and Handover Report
- Subtitle: Design and Implementation of a Multi-Tenant Service Environment using OPNsense, Samba AD, Isolated SAN Storage, Nginx and IIS Web Delivery, and Veeam Backup
- Document Type: Formal Technical Design, Validation, and Handover Report
- Service Scope: MSP, Company 1, and Company 2 operations
- Document Version: 5.0
- Document Date: March 27, 2026
- Submission Due Date: March 26, 2026
- Intended Audience: Client IT staff, MSP support teams, and successor operations staff
- Engineering Contributors: Bailey Kulla, Elyazid Sidelkheir, Ru Wang, Justin Rosseleve, Yiqin Huang, Omer Deniz
- Team Name: Site 2 Team
- Report Intent: This document is the formal Site 2 technical handover package. It explains service design, observed operating state, support assumptions, maintenance expectations, and validation references so that routine administration and first-line troubleshooting can continue without separate verbal knowledge transfer.

---

## ENVIRONMENT FACTS — USE THESE EXACTLY

All IP addresses, hostnames, port numbers, and system names below are authoritative. Do not invent, modify, or omit any of them.

### Network Segments and OPNsense Interfaces
- WAN: 172.20.64.1/16
- MSP segment: 172.30.65.177/29 (OPNsense MSP interface)
- C1LAN: 172.30.65.1/26 (Company 1 routed LAN)
- C1DMZ: 172.30.65.161/29 (Company 1 web/DMZ)
- C2LAN: 172.30.65.65/26 (Company 2 routed LAN)
- C2DMZ: 172.30.65.169/29 (Company 2 web/DMZ)
- SITE1_OVPN: OpenVPN inter-site interface
- Company 1 storage bridge (not routed through OPNsense): C1SAN 172.30.65.186/29, gateway 172.30.65.185
- Company 2 storage bridge (not routed through OPNsense): C2SAN 172.30.65.194/29, gateway 172.30.65.193

### WAN NAT Rules
- 33464 → 172.30.65.178:3389 (Jump64 RDP)
- 33564 → 172.30.65.179:22 (MSPUbuntuJump SSH)

### MSP Segment Systems
- Jump64 (Windows bastion): 172.30.65.178
- MSPUbuntuJump (Linux bastion): 172.30.65.179
- S2Veeam (backup and recovery): 172.30.65.180
- OPNsense (gateway and segmentation): 172.30.65.177

### Company 1 Systems
- C1DC1 (Windows Server — Primary Domain Controller): 172.30.65.2
- C1DC2 (Windows Server — Secondary Domain Controller): 172.30.65.3
- C1FS (Windows Server — File Server): 172.30.65.4
- C1WindowsClient (Windows 10/11): 172.30.65.11
- C1UbuntuClient (Ubuntu 25.04 — Company 1 Linux client): 172.30.65.36
- C1WebServer (Windows Server — IIS, workgroup-hosted, not domain-joined): 172.30.65.162
- C1SAN (isolated storage): 172.30.65.186/29, gateway 172.30.65.185

### Company 2 Systems
- C2IdM1 (Ubuntu 22.04.5 LTS — Samba AD primary, DNS, DHCP primary): 172.30.65.66 — 4 vCPU, 7.8 GiB RAM, 32 GB system disk, 15 GB root LV, interface ens18
- C2IdM2 (Ubuntu 22.04.5 LTS — Samba AD secondary, DNS, DHCP secondary): 172.30.65.67 — 4 vCPU, 7.8 GiB RAM, 32 GB system disk, 15 GB root LV, interface ens18
- C2FS (Ubuntu 22.04.5 LTS — Samba file server): 172.30.65.68 — 4 vCPU, 7.8 GiB RAM, 16 GB system disk, 160 GB mounted data disk at /mnt/c2_public, service NIC ens19 (172.30.65.68/26), storage NIC ens18 (172.30.65.195/29)
- C2LinuxClient (Ubuntu 25.04 — Company 2 Linux client): 172.30.65.70 — 4 vCPU, 7.3 GiB RAM, 32 GB disk, ens18
- C2WebServer (Ubuntu 22.04.5 LTS — nginx HTTPS): 172.30.65.170 — 4 vCPU, 7.8 GiB RAM, 32 GB system disk, 30 GB root LV, ens18
- C2SAN (isolated storage): 172.30.65.194/29, gateway 172.30.65.193

### OPNsense Aliases
- C1_Nets, C2_Nets, C1_REMOTE, C2_REMOTE, ALL_WEBS, ALL_DNS, C1_DCs, C2_DCs
- S2_VEEAM = 172.30.65.180
- SITE1_VEEAM = 192.168.64.20
- VEEAM_COPY_PORTS = 135, 445, 6160, 6162, 2500-3000, 10005, 10006

### Firewall Policy
- C1LAN allowed to: C1_GLOBAL, ALL_WEBS, ALL_DNS; blocked to C2_GLOBAL
- C2LAN allowed to: C2_GLOBAL, ALL_WEBS, ALL_DNS; blocked to C1_GLOBAL
- C1_REMOTE → 172.30.65.170/32 on HTTP/HTTPS
- C2_REMOTE → 172.30.65.162/32 on HTTP/HTTPS
- ALL_DNS combines C1_DCs and C2_DCs
- SITE1_VEEAM → S2_VEEAM on VEEAM_COPY_PORTS
- Static route: 192.168.64.20/32 via Site 1 OpenVPN gateway

### DNS Records (on both C2IdM1 and C2IdM2)
- c1-webserver.c1.local A: 172.30.64.162, 172.30.65.162
- c2-webserver.c2.local A: 172.30.64.170, 172.30.65.170
- Zones hosted: c2.local, c1.local, _msdcs.c2.local

### C2LinuxClient Resolver State
- DNS servers: 172.30.65.66, 172.30.65.67
- Search domains: c1.local, c2.local

### Web Validation Results
- https://c1-webserver.c1.local → HTTP/2 200
- https://172.30.65.162 → HTTP/2 404
- https://c2-webserver.c2.local → HTTP/1.1 200 OK
- https://172.30.65.170 → HTTP/1.1 404 Not Found

### C2FS File-Service State (observed from MSPUbuntuJump)
- smbd: active
- Mounted: /dev/sdb at /mnt/c2_public
- Active iSCSI session: 172.30.65.194:3260, target iqn.2024-03.org.clearroots:c2san
- Shares: [C2_Public] → /mnt/c2_public/Public; [C2_Private] → /mnt/c2_public/Private/%U
- Hostname-based SMB validated from C2LinuxClient: //c2fs.c2.local/C2_Public and //c2fs.c2.local/C2_Private
- Sync result: successful (Site 1 → Site 2)

### C1FS File-Service State (observed from Jump64 via WinRM)
- Windows SMB service: active
- Dedicated data volume: F: drive labeled SharedData
- Named SMB shares: present on the F: SharedData volume
- Active iSCSI initiator session: confirmed (Get-IscsiSession), tied to Company 1 SAN

### C2IdM1 and C2IdM2 Service State
- samba-ad-dc: Active on both nodes
- isc-dhcp-server: Active on both nodes
- DHCP failover: C2IdM1 = Primary, C2IdM2 = Secondary
- Directory principals (both nodes): Administrator, admin, employee1, employee2, c2_file_users

### C1 Identity State (observed from Jump64 via WinRM)
- C1DC1 and C1DC2: domain, forest, DC inventory, and directory service state all returned successfully via WinRM from Jump64
- c1.local domain active; Company 1 DNS records visible on Company 2 identity nodes

### C1WebServer Note
- Workgroup-hosted — not domain-joined
- IIS binding: single HTTPS binding restricted to c1-webserver.c1.local on TCP 443
- Raw IP access returns HTTP 404
- Managed independently using local administrator context

### C1WindowsClient Note
- Domain membership confirmed: c1.local
- Company 1 DNS resolvers active
- Both web hostnames resolved and returned HTTP 200
- Observed via WMI and controlled remote process execution from Jump64
- TCP 5985 (WinRM) was not open on this host — WMI-based inspection was used instead
- This is a management method difference, not a service gap

### C1UbuntuClient State (observed from MSPUbuntuJump)
- Shell context: admin@C1UbuntuClient
- Realm: C1.LOCAL active
- Both web hostnames resolved and returned HTTP 200
- Hardware: 4 vCPU, 7.3 GiB RAM, 32 GB root disk plus 3.8 GiB swap, 172.30.65.36/26 on C1LAN

### Shared Forest
- c1.local and c2.local share an Active Directory forest
- Treated as design evidence; not reconfigured during observation
- Cross-domain DNS visibility and client behavior are consistent with this design

### S2Veeam State (observed from MSPUbuntuJump and Jump64)
- Reachable from MSPUbuntuJump on: TCP 445, 9392, 5985, 10005, 10006
- Reachable from Jump64 via WinRM; local administrator context used
- Active Veeam services confirmed: VeeamBackupSvc, VeeamBrokerSvc, VeeamDeploySvc, VeeamExplorersRecoverySvc, VeeamFilesysVssSvc, VeeamMountSvc, VeeamNFSSvc
- Local repository: Site2Veeam on Z:\Site2AgentBackups
- Offsite SMB target: Site1OffsiteSmbShare at \\192.168.64.20\Site2OffsiteFromSite2
- Job families: Ubuntu_Servers, Windows_Servers, C1_FileShare, C2_FileShare
- Copy jobs to Site 1: present
- Protected workload count: 10 machines

### MSPUbuntuJump Inspection Scope
- Jump host reachability: Jump64 (172.30.65.178:3389) and MSPUbuntuJump itself confirmed
- OPNsense: HTTP 403 on port 80 (management plane present, non-anonymous), TCP 53 reachable, TCP 443 timed out
- C1DC1 and C1DC2: reachable on TCP 53, 88, 389, 445, 3389, 5985
- C1FS: reachable on TCP 445, 3389
- C1UbuntuClient: reachable on TCP 22
- C1WebServer: reachable on TCP 443, 3389, 5985
- C2IdM1 and C2IdM2: Samba AD, DHCP, DNS all active
- C2FS: smbd active, iSCSI session to 172.30.65.194:3260, sync successful
- C2LinuxClient: C2.LOCAL realm visible, employee1@c2.local and employee2@c2.local resolved via getent passwd, both web hostnames returned HTTP 200

### Outstanding Items
- OPNsense authenticated GUI walkthrough was not performed in the final pass (HTTP 403 confirmed but no authenticated session). This is an evidence depth limit, not a service failure.
- Updated Veeam GUI screenshots were not captured in the final revision pass despite live administrative access being confirmed from Jump64. Current screenshots should be captured before final submission.
- C1SAN direct management access is intentionally blocked from MSPUbuntuJump and Jump64. The relevant confirmation is the active iSCSI consumer session observed on C1FS. No direct management session into C1SAN is expected or required.

---

## SECTION 3.4 AND 3.5 — MANDATORY PARALLEL STRUCTURE

Sections 3.4 and 3.5 are the two tenant-specific service sections. They must use identical subsection names in identical order. This is non-negotiable.

Both sections must contain exactly these four subsections:
1. Service Overview
2. Architectural Rationale
3. Observed Operating State
4. Service Composition and Operational Reading

No subsection may appear in one tenant section but not the other. If a concept is documented for Company 2, the equivalent concept must be documented for Company 1 at comparable length and detail.

Section 3.4 must cover: C1DC1, C1DC2 (directory and DNS), C1FS (file services and isolated storage), C1WebServer (IIS, workgroup-hosted, hostname-only publication), C1WindowsClient (Windows client, WMI-validated), C1UbuntuClient (Linux client, directly observed), C1SAN (isolated storage, not directly managed but confirmed via C1FS iSCSI session).

Section 3.5 must cover: C2IdM1, C2IdM2 (Samba AD, DNS primary/secondary, DHCP primary/secondary), the shared forest relationship, and cross-domain naming behavior.

Neither section should be significantly longer or shorter than the other. Before writing, count the planned sentences for each and rebalance if the difference exceeds 15%.

---

## SECTION 3.6 — MANDATORY PARALLEL FILE-SERVICE SUBSECTIONS

Section 3.6 must open with two parallel subsections of equal structural weight:

### Company 2 File-Service State (C2FS)
Present as a bullet list covering: smbd service state, mount path and device, active iSCSI session details (target address, IQN), share definitions (C2_Public and C2_Private), sync result.

### Company 1 File-Service State (C1FS)
Present as a bullet list at the same structural level, covering: Windows SMB service state, dedicated data volume (F: SharedData), named SMB shares, active iSCSI initiator session — all observed from Jump64 via WinRM.

C1FS must not be introduced as a side note or comparison paragraph after C2FS. It belongs at the same structural level with its own named subsection heading.

---

## TABLE 14 — MANDATORY PARALLEL ROW STRUCTURE

Table 14 (Requirement-to-Implementation Traceability) must give Company 1 and Company 2 the same number of rows and the same level of detail. Do not consolidate all Company 1 systems into a single row while giving Company 2 multiple separate rows.

Required minimum row structure:

Company 1 rows (4 separate rows):
- Company 1 directory services — C1DC1 and C1DC2, WinRM-observed from Jump64
- Company 1 file services and isolated storage — C1FS F: SharedData volume, named shares, active iSCSI session, C1SAN
- Company 1 web delivery — C1WebServer, IIS, hostname-only binding on TCP 443, HTTP 404 on raw IP
- Company 1 client validation — C1WindowsClient (WMI from Jump64), C1UbuntuClient (direct observation)

Company 2 rows (4 separate rows):
- Company 2 identity, DNS, and DHCP — C2IdM1 and C2IdM2, Samba AD, DHCP failover
- Company 2 file services and isolated storage — C2FS, iSCSI session, C2_Public and C2_Private shares, C2SAN
- Company 2 web delivery — C2WebServer, nginx, hostname-only binding, HTTP 404 on raw IP
- Company 2 client validation — C2LinuxClient, direct observation, resolver state, SMB access

---

## FIGURES — PLACEMENT INSTRUCTIONS

Insert the following placeholder at the exact location specified for each figure. I will add screenshots and diagrams manually after the document is produced.

Format for each placeholder:
[FIGURE PLACEHOLDER — Figure N: descriptive caption]
Description: one or two sentences explaining what this figure must show and why it appears here.

Required figures:

Figure 1: Site 2 topology and service-role alignment diagram
Place: after the first overview paragraph in Section 3.1
Description: Shows all Site 2 service domains — MSP management plane, Company 1 services, Company 2 services, isolated SAN bridges, inter-site VPN path, and S2Veeam. The diagram must make all three scopes visually distinct.

Figure 2: Site 2 logical service inventory and platform role map
Place: at the end of Section 3.2, after the platform baseline table
Description: Maps every Site 2 system to its service role across MSP, Company 1, and Company 2 scopes. Should visually distinguish the three scopes.

Figure 3: OPNsense interfaces, aliases, and limited edge exposure
Place: after the interface and segment design tables in Section 3.3
Description: Shows the OPNsense interface layout, selected aliases, and WAN NAT publication of only the two jump-host entry points.

Figure 4: OPNsense OpenVPN and inter-site rule mapping
Place: after the firewall policy table in Section 3.3
Description: Shows the inter-site rule set supporting cross-site web access and backup-copy transport between Site 1 and Site 2.

Figure 5: Company 1 services from the MSP management path (MSPUbuntuJump port checks)
Place: at the end of Section 3.4 Observed Operating State
Description: Shows MSPUbuntuJump port-reachability results for C1DC1, C1DC2, C1FS, C1UbuntuClient, and C1WebServer.

Figure 5A: Jump64 Windows bastion baseline
Place: immediately after Figure 5
Description: Shows Jump64 platform state and its internal Site 2 management address, confirming that the Windows bastion was the active inspection platform.

Figure 5B: C1DC1 service-state evidence from Jump64
Place: after Figure 5A
Description: Shows C1DC1 service-state output from Jump64 WinRM, confirming the active Company 1 directory stack.

Figure 5C: C1DC2 service-state evidence from Jump64
Place: after Figure 5B
Description: Shows C1DC2 service-state output from Jump64, reinforcing the dual-controller model.

Figure 5D: C1FS storage, shares, and iSCSI evidence from Jump64
Place: after Figure 5C
Description: Shows the F: SharedData volume, named SMB shares, and active iSCSI session as observed from Jump64 WinRM.

Figure 5E: C1WebServer IIS binding evidence from Jump64
Place: after Figure 5D
Description: Shows the workgroup-hosted C1WebServer state and IIS binding restricted to c1-webserver.c1.local on TCP 443.

Figure 5F: C1WindowsClient endpoint and dual-web evidence
Place: after Figure 5E
Description: Shows domain membership confirmation and successful access to both internal web hostnames via WMI-backed probe from Jump64.

Figure 6: C2IdM1 Active Directory, DNS, and DHCP evidence
Place: after the C2IdM1 data in Table 9 in Section 3.5
Description: Shows samba-ad-dc active, DHCP active, and DNS query output for both web hostnames on C2IdM1.

Figure 7: C2IdM2 Active Directory, DNS, and DHCP evidence
Place: after Figure 6
Description: Same structure as Figure 6 but for the secondary identity node, confirming dual-node consistency.

Figure 8: Shared-forest and cross-domain DNS evidence
Place: at the end of the Namespace and Forest Design subsection in Section 3.5
Description: Shows both Company 1 and Company 2 web namespaces visible within the Company 2 identity plane, confirming the shared-forest design is operational.

Figure 9: C2FS iSCSI-backed storage and mounted volume evidence
Place: after the Company 2 File-Service State bullet list in Section 3.6
Description: Shows the active iSCSI session to 172.30.65.194:3260 and the /mnt/c2_public mounted volume on C2FS.

Figure 10: C2FS SMB share definitions and synchronization evidence
Place: after Figure 9
Description: Shows the C2_Public and C2_Private share definitions from testparm output together with the successful sync log result.

Figure 11: C1SAN isolated storage interface evidence
Place: in the SAN Isolation Model subsection in Section 3.6
Description: Shows the C1SAN interface configuration confirming the isolated Company 1 storage segment address and gateway.

Figure 12: C2SAN isolated storage interface evidence
Place: after Figure 11
Description: Shows the C2SAN interface configuration confirming the isolated Company 2 storage segment address and gateway.

Figure 13: C1UbuntuClient Company 1 client — domain context and dual-web evidence
Place: in Section 3.7 Client Validation Perspectives, after the C1UbuntuClient description
Description: Shows C1UbuntuClient shell context (admin@C1UbuntuClient), C1.LOCAL realm visibility, resolver state, and successful HTTP 200 responses to both web hostnames.

Figure 14: C2LinuxClient domain identity and dual-web evidence
Place: after Figure 13
Description: Shows C2.LOCAL realm state, employee1@c2.local and employee2@c2.local via getent passwd, resolver configuration, and HTTP 200 responses to both web hostnames.

Figure 15: S2Veeam repository, backup jobs, and offsite-copy evidence
Place: at the end of Section 3.8 Current Operational State
Description: Shows Veeam repository configuration, backup job families (Ubuntu_Servers, Windows_Servers, C1_FileShare, C2_FileShare), and copy-job configuration toward Site 1.

---

## TABLES — MANDATORY LIST

Produce all tables below, fully populated with the environment data from this prompt. Every table must have a numbered title and appear in the correct section.

- Table 1: Design inputs and evidence basis for Site 2 — Section 2.2
- Table 2: Evidence classes used in this report — Section 2.3
- Table 3: Observation vantage points — Section 2.3
- Table 4: Observed Site 2 systems and service roles — Section 3.1
- Table 5: Site 2 logical service inventory and role mapping — Section 3.2
- Table 5A: Observed platform baseline — all service scopes (Linux nodes + MSPUbuntuJump) — Section 3.2
- Table 6: Site 2 network segments and gateways — Section 3.3
- Table 7: OPNsense exposure, routing, and firewall policy summary — Section 3.3
- Table 8: Company 1 service summary — Section 3.4
- Table 9: Company 2 identity, DNS, and DHCP summary — Section 3.5
- Table 10: Storage and isolated SAN summary — Section 3.6
- Table 11: Client access and identity summary (three columns: C1UbuntuClient, C1WindowsClient, C2LinuxClient) — Section 3.7
- Table 12: Internal web delivery summary — Section 3.7
- Table 13: Backup and offsite-protection summary — Section 3.8
- Table 14: Requirement-to-implementation traceability matrix (parallel C1 and C2 rows as specified above) — Section 3.9
- Table 15: Service dependency and failure-domain view — Section 3.10
- Table 16: Authentication and authorization model — Section 3.10
- Table 17: Storage, backup, and recovery data-flow summary — Section 3.11
- Table 18: Operational maintenance checks — Section 3.12
- Table 19: Troubleshooting and fast triage guide — Section 3.13
- Table 20: Integrated design summary — Section 3.14
- Table A1: Observed addressing, gateways, and endpoints — Appendix A
- Table B1: Evidence and reference traceability — Appendix B
- Table C1: Service verification and assurance matrix — Appendix C

Table 11 must have three client columns (C1UbuntuClient, C1WindowsClient, C2LinuxClient) and must note clearly in the C1WindowsClient column that WMI-based inspection was used because TCP 5985 was not open on that host.

Table 3 must state in the Jump64 row that it served as the primary Windows-side inspection platform for C1DC1, C1DC2, C1FS, C1WebServer, C1WindowsClient, and S2Veeam — not just describe it generically as a Windows bastion.

---

## APPENDIX E — SMB CONFIGURATION EXCERPT

Include the following verbatim block in Appendix E:

[global]
workgroup = C2
realm = C2.LOCAL
security = ADS
server role = member server
kerberos method = secrets and keytab
winbind use default domain = yes
winbind refresh tickets = yes
idmap config * : backend = tdb
idmap config * : range = 3000-7999
template shell = /bin/bash
template homedir = /home/%U
obey pam restrictions = no
log file = /var/log/samba/log.%m
max log size = 1000
logging = file

[C2_Public]
path = /mnt/c2_public/Public
browseable = yes
read only = no
valid users = @c2_file_users
force group = c2_file_users
create mask = 0770
directory mask = 0770

[C2_Private]
path = /mnt/c2_public/Private/%U
browseable = no
read only = no
valid users = %U
force group = c2_file_users
create mask = 0700
directory mask = 0700

---

## REFERENCES — MANDATORY IEEE FORMAT

Include all of the following. Add any additional vendor references that are legitimately relevant to deployed technologies. Use IEEE citation format throughout.

[1] OPNsense Documentation, "Firewall Rules," https://docs.opnsense.org/manual/firewall.html, accessed Mar. 24, 2026.
[2] OPNsense Documentation, "Network Address Translation," https://docs.opnsense.org/manual/nat.html, accessed Mar. 24, 2026.
[3] OPNsense Documentation, "Setup SSL VPN Road Warrior," https://docs.opnsense.org/manual/how-tos/sslvpn_client.html, accessed Mar. 24, 2026.
[4] SambaWiki, "Setting up Samba as an Active Directory Domain Controller," https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller, accessed Mar. 24, 2026.
[5] Ubuntu Server Documentation, "Set up Samba as a file server," https://documentation.ubuntu.com/server/how-to/samba/file-server/, accessed Mar. 24, 2026.
[6] Ubuntu Server Documentation, "iSCSI initiator (or client)," https://documentation.ubuntu.com/server/how-to/storage/iscsi-initiator-or-client/, accessed Mar. 24, 2026.
[7] Microsoft Learn, "binding Element for bindings for site [IIS Settings Schema]," https://learn.microsoft.com/en-us/previous-versions/iis/settings-schema/ms691267(v=vs.90), accessed Mar. 24, 2026.
[8] Veeam Help Center, "Configuring Backup Repositories," https://helpcenter.veeam.com/docs/vbr/userguide/sch_configure_repository.html, accessed Mar. 24, 2026.
[9] Site 2 gateway configuration record, Mar. 23, 2026.
[10] Site 2 environment inventory, SAN addressing record, and namespace design record, Mar. 24, 2026.
[11] Site 2 operating-state review record, Mar. 23–27, 2026.

---

## STYLE AND WRITING REQUIREMENTS

### Tone and Voice
- Write in clear, professional technical English produced by a senior engineer who has personally worked through the environment.
- Use active constructions. Avoid: "it was evidenced that", "as documented", "current observations align with". Prefer: "inspection showed", "checks confirmed", "the configuration shows".
- Vary sentence structure. Do not open every paragraph with "The [noun] is/are".
- "That is why" and "that distinction matters because" combined: maximum once per section.
- "Rather than": maximum twice per section.
- No filler phrases: "it is worth noting that", "importantly", "it should be mentioned", "it is essential to understand".

### Evidence Honesty
- Distinguish clearly between live observations and configuration or design evidence.
- Use "observed", "confirmed", or "showed" for live results. Use "configuration evidence indicates" or "design records show" for non-live items.
- Do not present inference as fact.

### Document Cohesion
- The document reads as one continuous narrative, not a collection of section summaries.
- Each section ends by pointing naturally toward what comes next.
- Do not repeat table content verbatim in surrounding prose. Prose explains why the table's content matters — the table carries the detail.

### Technical Precision
- Use exact IP addresses, hostnames, port numbers, and interface names from the environment facts. Never approximate.
- Do not describe command output verbatim. Describe results in plain English.
- Do not add services, systems, or features not present in the environment facts.

---

## STRUCTURAL BALANCE REQUIREMENTS

These rules are mandatory. Violations create the impression that one tenant received more attention than the others, which is penalized in academic assessment.

### Tenant Title Parity
Section 3.4 must be titled: "Company 1 Directory Services, File Services, Web Delivery, and Client Access"
Section 3.5 must be titled: "Company 2 Identity Services, DNS, DHCP, and Shared Forest Design"
Both titles must follow the same grammatical pattern and carry comparable descriptive depth.

### Subsection Schema Parity
Sections 3.4 and 3.5 must use the same four subsection names in the same order:
Service Overview → Architectural Rationale → Observed Operating State → Service Composition and Operational Reading.
No subsection may appear in one section but not the other.

### Narrative Length Parity
Before producing the document, count planned sentences for Section 3.4 and Section 3.5 (excluding table content). If the difference exceeds 15%, rebalance before writing.

### Storage Section Parity
Section 3.6 must open with two subsections of equal structural weight:
- "Company 2 File-Service State (C2FS)" — bullet list
- "Company 1 File-Service State (C1FS)" — bullet list at the same level
C1FS must not appear as a comparison paragraph or side note after C2FS.

### Traceability Table Parity
Table 14 must give Company 1 and Company 2 the same number of rows (minimum four each) at the same level of granularity. See Table 14 requirements above.

### Table 3 Jump64 Row
The Jump64 row in Table 3 must explicitly name the systems it was used to inspect (C1DC1, C1DC2, C1FS, C1WebServer, C1WindowsClient, S2Veeam), not describe it generically.

### C1WindowsClient Documentation Rule
The reason WMI was used instead of WinRM for C1WindowsClient (TCP 5985 not open) must be stated exactly once, clearly, at the point where C1WindowsClient inspection is first described. It must not be repeated in subsequent paragraphs, tables, or appendices.

### Conclusion Balance
The conclusion must name specific validated outcomes for all three scopes — MSP, Company 1, and Company 2 — in proportionally equivalent depth. It must not list multiple specific Company 2 findings while summarizing Company 1 in a single aggregate phrase.

---

## REFERENCE DOCUMENT — SITE 1 (structural guidance only)

The Site 1 final documentation (V4.2) was produced by the same team for the same assignment. Use it as a structural and quality reference only — do not copy any text from it.

Key structural parallels to follow:
- Site 1 opens every major section with a clear context statement before going into tables. Do the same.
- Site 1 treats its operational traceability matrix (Appendix E in Site 1, Appendix C in Site 2) as a complete standalone reference — match that level of completeness.
- Site 1 includes physical server hardware details in a dedicated subsection. The Site 2 equivalent is Table 5A — give it equivalent prominence.
- Site 1 explicitly separates backup from synchronization in its protection section. Site 2 must do the same with equal clarity in Section 3.11.
- Site 1 uses numbered anchor-style figure references (e.g., Figure 3A, Figure 5D). Follow the same figure labeling convention.

---

## FINAL QUALITY CHECKLIST

Before returning the document, verify each item:

1. Every IP address, hostname, port, and interface name from the environment facts is present and correct.
2. No system, service, or capability has been invented that is not in the environment facts.
3. Sections 3.4 and 3.5 use identical subsection names in identical order.
4. Section 3.4 and Section 3.5 are within 15% of each other in narrative sentence count (excluding tables).
5. Section 3.6 opens with two parallel bullet-list subsections for C2FS and C1FS at equal structural levels.
6. Table 14 has at least four separate rows for Company 1 and at least four separate rows for Company 2.
7. Table 11 has three client columns: C1UbuntuClient, C1WindowsClient, C2LinuxClient.
8. Table 3 Jump64 row names the systems inspected, not a generic description.
9. C1WindowsClient WMI explanation appears exactly once in the document.
10. All 20+ required tables are present and fully populated.
11. Every figure placeholder appears in the correct location with a clear description.
12. "That is why" and "that distinction matters because" combined appear no more than once per section.
13. "Rather than" appears no more than twice per section.
14. "It was evidenced that" does not appear anywhere in the document.
15. The conclusion gives MSP, Company 1, and Company 2 proportionally equivalent specific coverage.
16. The limitations section (3.15 and Appendix D) acknowledges the Veeam screenshot gap and OPNsense GUI walkthrough gap clearly and without excessive qualification.
17. The document reads as one continuous narrative — each section ends by pointing toward the next.
18. No paragraph restates a table that immediately precedes or follows it.
19. Appendix E contains the verbatim SMB configuration excerpt.
20. All IEEE references are present and correctly formatted.

Produce the complete document now.
