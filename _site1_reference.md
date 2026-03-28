Private Cloud Infrastructure Deployment

CST8248 - Emerging Technologies Technical Report

Design and Implementation of a Multi-Tenant Private Cloud Infrastructure
using Proxmox, OPNsense, SAN Storage, and Veeam Backup

| **Course**            | CST8248 - Emerging Technologies                                                       |
|-----------------------|---------------------------------------------------------------------------------------|
| **Professor**         | Denis Latremouille                                                                    |
| **Team Name**         | Raspberry Pioneers                                                                    |
| **Submission Type**   | Group Submission                                                                      |
| **Due Date**          | March 30, 2026                                                                        |
| **Program**           | Computer Systems Technology - Networking                                              |
| **Institution**       | Algonquin College                                                                     |
| **Document Version**  | 2.7                                                                                   |
| **Document Date**     | March 14, 2026                                                                        |
| **Intended Audience** | Client IT staff, MSP support teams, and Level 4 graduates assuming operations support |

Team Members: Bailey Kulla, Elyazid Sidelkheir, Ru Wang, Justin
Rosseleve, Yiqin Huang, Omer Deniz

|                                                                                                                                                                                                                                                                             |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Report intent: this document is written in a client/MSP handover style, but it retains the formal structure required by CST8248: title page, table of contents, executive summary, introduction, background, discussion, conclusion, appendices, and IEEE-style references. |

Contents
========

[Contents 2](#contents)

[List of Figures 4](#list-of-figures)

[List of Tables 4](#list-of-tables)

[Executive Summary 7](#executive-summary)

[1. Introduction 7](#introduction)

[2. Background 7](#background)

[3. Discussion 7](#discussion)

> [3.1 Environment Overview and Topology
> 8](#environment-overview-and-topology)
>
> [3.2 Network Design and IP Addressing Rationale
> 10](#network-design-and-ip-addressing-rationale)
>
> [3.3 Identity Infrastructure and Tenant Separation
> 10](#identity-infrastructure-and-tenant-separation)
>
> [3.4 Platform and Service Choice Rationale
> 11](#platform-and-service-choice-rationale)
>
> [3.4.1 Physical Server Baseline 12](#physical-server-baseline)
>
> [3.4.2 Physical Switching and Uplink Baseline
> 14](#physical-switching-and-uplink-baseline)
>
> [3.5 Compute and Virtualization 14](#compute-and-virtualization)
>
> [3.6 Identity, DNS, and DHCP Services
> 17](#identity-dns-and-dhcp-services)
>
> [3.7 Storage and SAN Services 18](#storage-and-san-services)
>
> [3.8 Backup and Recovery 23](#backup-and-recovery)
>
> [3.8.1 Agentless System-Level VM Backup
> 24](#agentless-system-level-vm-backup)
>
> [3.8.2 File-Based Client Backup 25](#file-based-client-backup)
>
> [3.8.3 Offsite Backup Copy to Site 2
> 25](#offsite-backup-copy-to-site-2)
>
> [3.9 Value Added Features 27](#value-added-features)
>
> [3.9.1 Company Branding through Group Policy (Company 1)
> 27](#company-branding-through-group-policy-company-1)
>
> [3.9.2 Infrastructure Monitoring Dashboard (Grafana)
> 28](#infrastructure-monitoring-dashboard-grafana)
>
> [3.9.3 Web-Based Server Administration (Cockpit)
> 29](#web-based-server-administration-cockpit)
>
> [3.9.4 Centralized Infrastructure Management using Windows Admin
> Center
> 30](#centralized-infrastructure-management-using-windows-admin-center)
>
> [3.10 Site-to-Site VPN Security and Administrative Access
> 31](#site-to-site-vpn-security-and-administrative-access)
>
> [3.10.1 Site-to-Site VPN Security 31](#site-to-site-vpn-security)
>
> [3.10.2 Administrative Access 33](#administrative-access)
>
> [3.11 Maintenance and Daily Duties 33](#maintenance-and-daily-duties)
>
> [3.11.1 Standard Change Workflow 34](#standard-change-workflow)
>
> [3.11.2 Failure Domains and Recovery Priority
> 34](#failure-domains-and-recovery-priority)
>
> [3.12 Limitations, Risks, and Unresolved Items
> 35](#limitations-risks-and-unresolved-items)

[4. Conclusion 35](#conclusion)

[5. Appendices 35](#appendices)

> [Appendix A. Network Addressing 36](#appendix-a.-network-addressing)
>
> [Appendix B. DHCP Reference 36](#appendix-b.-dhcp-reference)
>
> [Appendix C. Storage Reference 36](#appendix-c.-storage-reference)
>
> [Appendix D. Backup Reference 37](#appendix-d.-backup-reference)
>
> [Appendix E. Site 1 Requirement Coverage and Demonstration Notes
> 37](#appendix-e.-site-1-requirement-coverage-and-demonstration-notes)
>
> [Network and Shared Infrastructure
> 37](#network-and-shared-infrastructure)
>
> [Company 1 38](#company-1)
>
> [Company 2 38](#company-2)
>
> [Cross-Site and Remote Access 38](#cross-site-and-remote-access)
>
> [Operations and Demonstration Use
> 39](#operations-and-demonstration-use)

[6. References 39](#references)

List of Figures
===============

[Figure 1. Overall Site 1 network topology](#fig_01) .... 9

[Figure 2. VLAN routing and firewall flow design](#fig_02) .... 9

[Figure 3. Directory services architecture](#fig_03) .... 11

[Figure 3A. Site 1 rack installation (rear
view)](#fig_3a_rear_rack_view) .... 13

[Figure 3B. Site 1 rack installation (front
view)](#fig_3b_front_drive_layout) .... 14

[Figure 4. Proxmox VE management interface](#fig_04) .... 15

[Figure 5. Virtual machine logical layout](#fig_05) .... 17

[Figure 6. Server2 storage volume presentation](#fig_06) .... 23

[Figure 7. Server2 network interface layout](#fig_07) .... 23

[Figure 8. Veeam backup overview](#fig_08) .... 25

[Figure 8A. Primary Veeam job status .... 23](#fig_8a)

[Figure 8B. Site 1 to Site 2 backup copy job .... 24](#fig_8b)

[Figure 8C. Remote backup copy inventory .... 25](#fig_8c)

[Figure 9. Group Policy desktop branding evidence](#fig_09) .... 28

[Figure 10. Grafana infrastructure dashboard](#fig_10) .... 29

[Figure 11. Cockpit administration overview](#fig_11) .... 30

[Figure 12. Cockpit web terminal](#fig_12) .... 30

[Figure 13. Windows Admin Center connection inventory](#fig_13) .... 31

[Figure 14. Windows Admin Center server overview](#fig_14) .... 31

[Figure 15. Site 1 OpenVPN client status .... 29](#fig_15)

[Figure 16. Site 2 OpenVPN server status .... 30](#fig_16)

[Figure 17. Firewall-centered security segmentation .... 31](#fig_17)

List of Tables
==============

[Table 1. Technology stack summary](#tbl_01) .... 7

[Table 2. VLAN and gateway design](#tbl_02) .... 10

[Table 3. Identity services summary](#tbl_03) .... 10

[Table 4. Platform and service choice rationale](#tbl_04) .... 11

[Table 5. Service stacking rationale](#tbl_05) .... 12

[Table 5A. Physical server hardware
summary](#tbl_5a_physical_server_hardware) .... 12

[Table 6. Management endpoints](#tbl_06) .... 14

[Table 7. Company 1 virtual machine inventory](#tbl_07) .... 15

[Table 8. Company 2 virtual machine inventory](#tbl_08) .... 16

[Table 9. Shared administrative systems](#tbl_09) .... 16

[Table 10. Company 1 domain controllers](#tbl_10) .... 17

[Table 11. Company 2 domain controllers](#tbl_11) .... 17

[Table 12. Company 1 DHCP scope summary](#tbl_12) .... 18

[Table 13. Company 2 DHCP scope summary](#tbl_13) .... 18

[Table 13A. Company 1 file service access control summary ....
17](#tbl_13a)

[Table 14B. Company 2 service stack summary .... 19](#tbl_14b)

[Table 14A. Company 2 replicated file service summary .... 18](#tbl_14a)

[Table 14. Server2 volume layout](#tbl_14) .... 21

[Table 15. Company 1 iSCSI targets](#tbl_15) .... 21

[Table 16. Company 2 iSCSI targets](#tbl_16) .... 22

[Table 17. SAN VLAN design](#tbl_17) .... 22

[Table 18. Storage server SAN interfaces](#tbl_18) .... 22

[Table 19. Backup infrastructure components](#tbl_19) .... 23

[Table 20. Backup repository layout](#tbl_20) .... 23

[Table 21. Backup scope by class .... 22](#tbl_21)

[Table 22. Group Policy branding configuration summary](#tbl_22) .... 27

[Table 23. Grafana dashboard metrics](#tbl_23) .... 28

[Table 24. Cockpit management features](#tbl_24) .... 29

[Table 25. Windows Admin Center managed systems](#tbl_25) .... 30

[Table 26. Windows Admin Center capabilities](#tbl_26) .... 30

[Table 27. Inter-site VPN routing and firewall control summary ....
30](#tbl_27)

[Table 28. Recommended operational checks](#tbl_28) .... 33

[Table 29. Primary failure domains](#tbl_29) .... 34

[Table 30. Known limitations and unresolved items](#tbl_30) .... 35

[Table A1. Full VLAN addressing matrix](#tbl_a1) .... 36

[Table B1. Documented DHCP scope](#tbl_b1) .... 36

[Table C1. Storage server interfaces](#tbl_c1) .... 37

[Table C2. iSCSI target mappings](#tbl_c2) .... 37

[Table D1. Backup repository volumes](#tbl_d1) .... 37

[Table D2. Veeam backup file types](#tbl_d2) .... 37

Executive Summary
=================

This technical report documents the design and deployment of a
multi-tenant private cloud infrastructure for Site 1. It is written in
the style of a client handover document so that an MSP support team or
Level 4 graduate can assume day-to-day operations with minimal knowledge
transfer.

From a decision-making perspective, the environment balances cost and
capability by combining open-source platforms such as Proxmox VE,
OPNsense, Samba, Grafana, and Cockpit with Windows Server and Veeam
where Microsoft integration and enterprise backup features are required.
This keeps licensing concentrated on services that directly benefit
administration, identity, and recovery.

The main maintenance burden is centered on the OPNsense firewall, the
single Proxmox host, and Server2, which together form the primary
control, compute, and storage layers. Future requirements should focus
on higher availability, restore testing, formal credential management,
and clearer ownership of alerting, patching, and configuration backups.

1. Introduction
===============

The purpose of this document is to explain what was built, why specific
design choices were made, and how the resulting environment should be
supported after delivery. The report covers networking, identity
services, virtualization, storage, backup, and administrative tooling
for the Site 1 private cloud environment.

The main content includes topology diagrams, service descriptions, IP
addressing, platform rationale, service stacking rationale, operational
duties, known risks, and appendix material such as DHCP, storage, and
backup reference data.

The scope of this report is limited to the deployed Site 1 environment
and the systems documented in the supplied evidence package. It does not
include credential values or production support contracts.

2. Background
=============

The intended reader is either a client IT administrator, an MSP support
technician, or a Level 4 graduate expected to maintain the environment
after deployment. The reader should understand basic routing, VLANs,
Active Directory concepts, Linux and Windows administration, storage
networking, and backup operations.

Before exploring the discussion section, the reader should understand
that this project simulates two independent organizations sharing common
hardware while remaining logically isolated. The operational goal is not
only to host services, but to do so in a way that is supportable,
documentable, and realistic from a managed services perspective.

3. Discussion
=============

Table 1 gives a high-level summary of the core service layers in the
environment so the reader can understand the technology stack before
moving into detailed design sections.

<span id="tbl_01" class="anchor"></span>Table 1. Technology stack
summary

| **Service Layer**                   | **Platform / Product**                                            | **Operational Role**                                                     |
|-------------------------------------|-------------------------------------------------------------------|--------------------------------------------------------------------------|
| Network Edge and Inter-VLAN Routing | OPNsense                                                          | Gateway, routing, firewall policy enforcement                            |
| Virtualization                      | Proxmox VE                                                        | Primary hypervisor and VM hosting platform                               |
| Identity - Company 1                | Windows Server 2022 AD DS                                         | Authentication, DNS, DHCP, Group Policy                                  |
| Identity - Company 2                | Samba AD on Ubuntu Server                                         | Authentication, DNS, DHCP, SMB                                           |
| Storage                             | Windows Server 2022 iSCSI                                         | Tenant SAN volumes and shared storage services                           |
| Backup                              | Veeam Backup & Replication                                        | Centralized VM backup and restore management                             |
| Monitoring                          | Grafana + InfluxDB on Jumpbox Ubuntu                              | Infrastructure dashboard, metrics collection, and performance visibility |
| Administrative Access               | Jumpbox Windows / Jumpbox Ubuntu / Windows Admin Center / Cockpit | Controlled remote administration and browser-based management access     |

3.1 Environment Overview and Topology
-------------------------------------

The environment is organized around a single Proxmox virtualization
host, a centralized OPNsense firewall, and a dedicated Windows storage
server (Server2). Architecturally, Site 1 follows a centralized control
model in which OPNsense provides routing and policy enforcement, Proxmox
hosts the compute layer, and Server2 delivers shared storage and backup
services. Tenant isolation is achieved through separate client, server,
DMZ, and SAN VLANs for each company, with a restricted management VLAN
used for administrative access. Storage access for Company 1 is
presented from Server2 over dedicated SAN interfaces, and systems that
require block storage use dedicated SAN NICs rather than relying on the
routed client path. In addition to the local Site 1 design, Site 1 and
Site 2 are connected by a site-to-site OpenVPN tunnel that supports
controlled cross-site management and offsite Veeam backup copy traffic.
Although only one tunnel instance is used, Company 1 and Company 2
remain logically separated across that inter-site path through routed
subnet definitions and OPNsense firewall policy.

Figure 1 provides the high-level topology view of the full Site 1
environment, while Figure 2 shows how routing and policy enforcement are
concentrated on OPNsense.

<img src="media/image1.png" style="width:6.1567in;height:4.16895in" />

<span id="fig_01" class="anchor"></span>Figure 1. Overall Site 1 network
topology

<img src="media/image2.png" style="width:6.89583in;height:4.66944in" />

<span id="fig_02" class="anchor"></span>Figure 2. VLAN routing and
firewall flow design

3.2 Network Design and IP Addressing Rationale
----------------------------------------------

Routed east-west and north-south traffic traverses OPNsense. Default
gateways are assigned only to the routed user, server, DMZ, and
management VLANs, and management access is constrained to VLAN 99 jump
hosts. The separate 192.168.64.0/24 segment is the shared infrastructure
and WAN-side management network used for the OPNsense WAN interface, the
Proxmox VE management interface, Server2 management connectivity, and
the hardware iLO endpoints. SAN traffic remains on dedicated storage
segments to avoid contention with client or server workloads, and the
active Company 1 SAN data path is direct from the initiator SAN NICs to
Server2 rather than through OPNsense.

Table 2 lists the VLAN IDs, address ranges, associated routed gateway or
direct-access note, and the intended traffic type for each network
segment. The table is the addressing baseline that future support
changes must preserve.

<span id="tbl_02" class="anchor"></span>Table 2. VLAN and gateway design

| **VLAN**             | **Network**      | **Gateway**       | **Purpose**                                                                                                            | Traffic Type          |
|----------------------|------------------|-------------------|------------------------------------------------------------------------------------------------------------------------|-----------------------|
| VLAN 10              | 172.30.64.0/26   | 172.30.64.1       | Company 1 Client Network                                                                                               | Routed                |
| VLAN 20              | 172.30.64.128/28 | 172.30.64.129     | Company 1 Server Network                                                                                               | Routed                |
| VLAN 30              | 172.30.64.160/29 | 172.30.64.161     | Company 1 Web / DMZ                                                                                                    | Routed                |
| VLAN 40              | 172.30.64.184/29 | None (direct SAN) | Company 1 SAN Network                                                                                                  | Direct storage        |
| VLAN 99              | 172.30.64.176/29 | 172.30.64.177     | Management Network                                                                                                     | Restricted admin      |
| VLAN 110             | 172.30.64.64/26  | 172.30.64.65      | Company 2 Client Network                                                                                               | Routed                |
| VLAN 120             | 172.30.64.144/28 | 172.30.64.145     | Company 2 Server Network                                                                                               | Routed                |
| VLAN 130             | 172.30.64.168/29 | 172.30.64.169     | Company 2 Web / DMZ                                                                                                    | Routed                |
| VLAN 140             | 172.30.64.192/29 | None (direct SAN) | Company 2 SAN Network                                                                                                  | Direct storage        |
| Infrastructure / WAN | 192.168.64.0/24  | 192.168.64.1      | Shared infrastructure and WAN-side management segment for OPNsense WAN, Proxmox VE, Server2 management, and iLO access | Shared infrastructure |

-   Client networks are isolated by tenant and permitted to reach only
    approved services.

-   DMZ networks provide controlled exposure for web workloads.

-   SAN networks are dedicated to storage access and should not be used
    for general traffic.

-   The management VLAN is the only approved path for routine
    administrative access.

3.3 Identity Infrastructure and Tenant Separation
-------------------------------------------------

Table 3 provides the tenant-level identity summary, including the
directory platform, domain name, controller assignments, and major
identity functions delivered to each organization.

<span id="tbl_03" class="anchor"></span>Table 3. Identity services
summary

| **Organization** | **Directory Platform**    | **Domain** | **Domain Controllers**                         | **Core Functions**                         |
|------------------|---------------------------|------------|------------------------------------------------|--------------------------------------------|
| Company 1        | Windows Server 2022 AD DS | c1.local   | C1-DC1 (172.30.64.130), C1-DC2 (172.30.64.131) | AD authentication, DNS, DHCP, Group Policy |
| Company 2        | Samba AD on Ubuntu Server | c2.local   | C2-DC1 (172.30.64.146), C2-DC2 (172.30.64.147) | AD-compatible auth, DNS, DHCP, SMB         |

Company 1 uses a traditional Microsoft Active Directory deployment with
two Windows Server 2022 domain controllers. Company 2 uses Samba Active
Directory on Ubuntu Server to provide a Linux-based domain environment
with Microsoft-compatible protocols. No cross-domain trust relationship
exists between c1.local and c2.local, which preserves administrative
independence between the two tenants.

Table 3 summarizes the tenant identity model, and Figure 3 visualizes
how the two domains remain logically independent while still sharing the
same underlying infrastructure.

<img src="media/image3.png" style="width:6.89583in;height:4.66944in" />

<span id="fig_03" class="anchor"></span>Figure 3. Directory services
architecture

3.4 Platform and Service Choice Rationale
-----------------------------------------

The report requirements specifically call for platform choice and
service stacking rationale. Tables 4 and 5 capture those decisions so
that a receiving support team understands not only what was deployed,
but why the design was assembled in this form.

<span id="tbl_04" class="anchor"></span>Table 4. Platform and service
choice rationale

| **Platform / Service**     | **Rationale**                                                                                                                                |
|----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| Proxmox VE                 | Selected as the hypervisor because it supports enterprise-style virtualization with low licensing overhead and strong lab flexibility \[1\]. |
| OPNsense                   | Chosen to centralize VLAN routing, firewall policy, and gateway control with an interface suitable for support teams \[2\].                  |
| Windows Server AD DS       | Used for Company 1 because it provides native Microsoft identity, DNS, DHCP, Group Policy, and integration with Windows clients \[3\].       |
| Samba AD                   | Used for Company 2 to demonstrate a Linux-based directory platform with Microsoft-compatible protocols and lower platform cost \[4\].        |
| Veeam Backup & Replication | Adopted to provide centralized backup operations, restore workflows, and recognizable enterprise backup practices \[5\].                     |

<span id="tbl_05" class="anchor"></span>Table 5. Service stacking
rationale

| **Service Stack**                                                 | **Rationale**                                                                                                                                                             |
|-------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AD DS + DNS + DHCP + Group Policy on Company 1 domain controllers | These services are tightly related, reduce server count, and are common in smaller enterprise deployments where directory services control address assignment and policy. |
| Samba AD + DNS + DHCP + SMB on Company 2 domain controllers       | Combining these Linux-based services reduces infrastructure overhead while preserving identity, name resolution, and file access for the second tenant.                   |
| iSCSI + backup repositories + Veeam on Server2                    | Storage and backup were grouped on the same physical system to conserve lab hardware and keep storage-adjacent services close to the data path.                           |
| Jumpbox + Windows Admin Center / Grafana / browser-based tooling  | Management interfaces were grouped behind controlled administrative systems to reduce direct access from user networks and simplify support workflows.                    |

### 3.4.1 Physical Server Baseline

Below the service and platform layer, Site 1 is physically hosted on two
HP ProLiant DL380 Gen8 servers. This hardware baseline is important
because the virtualization, storage, and backup design described later
in the report depends directly on how these two hosts are divided
between compute and shared storage roles.

Server1 is dedicated to Proxmox VE and acts as the primary compute host
for the virtual environment. Server2 runs Windows Server 2022 directly
on the hardware and provides centralized SAN storage for shared use.
This split keeps compute and storage responsibilities separate, which
makes the architecture easier to explain, operate, and troubleshoot.

The physical hardware allocation is summarized in the following table so
that a receiving administrator can quickly see which disks are reserved
for the operating systems, which arrays are used for workload storage,
and how each server contributes to the overall platform.

<span id="tbl_5a_physical_server_hardware" class="anchor"></span>Table
5A. Physical server hardware summary

| Server  | Model                  | Base Role                        | Rear Drives / RAID / Use                                                   | Front Drives / RAID / Use                             | Design Intent                                                                                         |
|---------|------------------------|----------------------------------|----------------------------------------------------------------------------|-------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| Server1 | HP ProLiant DL380 Gen8 | Proxmox VE hypervisor host       | 2 x 2 TB drives, RAID 1, used for the Proxmox operating system             | 2 x 2 TB drives, RAID 1, used for Proxmox VM storage  | Keeps the hypervisor OS separate from guest workload storage while preserving basic disk redundancy.  |
| Server2 | HP ProLiant DL380 Gen8 | Windows Server 2022 storage host | 2 x 2 TB drives, RAID 1, used for the Windows Server 2022 operating system | 6 x 2 TB drives, RAID 10, used for SAN shared storage | Provides centralized shared storage with better performance and fault tolerance than a simple mirror. |

From an operational perspective, Table 5A confirms that Server1 should
be described as the compute foundation of Site 1. The mirrored rear
disks protect the Proxmox installation itself, while the mirrored front
disks provide a separate and redundant storage area for virtual machine
deployment. This makes it clear that the host was built first to run
Proxmox reliably and second to provide local VM storage for the
workloads it carries.

Server2 should be described as the storage foundation of Site 1.
Installing Windows Server 2022 directly on mirrored rear disks isolates
the operating system from the high-capacity front storage pool. The
front six-disk RAID 10 array then supports SAN storage for shared
infrastructure use, which aligns with the later discussion of iSCSI
presentation and centralized storage services.

Figure 3A shows the rear rack view of the two HP DL380 Gen8 hosts used
in Site 1, while Figure 3B shows the front chassis and drive layout.

<img src="media/image4.png" style="width:6.2in;height:3.51821in" />

<span id="fig_3a_rear_rack_view" class="anchor"></span>Figure 3A. Site 1
rack installation (rear view)

<img src="media/image5.png" style="width:4.9in;height:3.54238in" />

<span id="fig_3b_front_drive_layout" class="anchor"></span>Figure 3B.
Site 1 rack installation (front view)

### 3.4.2 Physical Switching and Uplink Baseline

A Cisco Catalyst lab switch provides the physical Layer 2 aggregation
point for Site 1. It connects Server1, Server2, both iLO interfaces, the
debug/admin port, and the upstream teacher-switch trunk, so it forms the
handoff between the on-rack infrastructure and the wider lab network.

The Proxmox trunk on Gi8/0/1 carries VLANs 10, 20, 30, 40, 64, 65, 99,
110, 120, 130, and 140 with native VLAN 64 for shared infrastructure
management. Gi8/0/5 and Gi8/0/6 are storage-only trunks that carry only
VLANs 40 and 140 with native VLAN 999 as a blackhole native VLAN, while
Gi8/0/24 uplinks only VLANs 1, 64, and 65 to the teacher switch. Server2
management and both iLO interfaces are placed on VLAN 64 access ports,
and the switch itself is managed over SSH on 192.168.64.2 with HTTP
disabled and rapid-PVST enabled.

3.5 Compute and Virtualization
------------------------------

Proxmox VE is the primary compute platform for all workloads in the
environment. It hosts tenant servers, clients, jump systems, and shared
services. Administrative access should be performed from the management
VLAN through approved jump systems. The documented Site 1 deployment is
a single-node Proxmox platform on Server1, and template virtual machines
for Windows Server 2022, Windows 10, and Linux clients were created to
support repeatable provisioning and consistent configuration across the
environment.

Table 6 identifies the primary management endpoints that an
administrator is expected to use. Tables 7, 8, and 9 then break the
workload inventory into Company 1 systems, Company 2 systems, and shared
administrative nodes. Figure 4 shows the actual Proxmox management
interface, and Figure 5 summarizes the logical VM layout hosted on the
platform.

<span id="tbl_06" class="anchor"></span>Table 6. Management endpoints

| **System**           | **IP / URL**               | **Access Method**          | **Operational Use**                                                      |
|----------------------|----------------------------|----------------------------|--------------------------------------------------------------------------|
| Proxmox VE           | https://192.168.64.10:8006 | Web console                | Hypervisor management                                                    |
| Grafana              | http://172.30.64.180:3000  | Web console                | Monitoring dashboard                                                     |
| Cockpit              | https://172.30.64.146:9090 | Web console                | Linux administration for Company 2                                       |
| Windows Admin Center | https://172.30.64.179:6600 | Web console                | Windows infrastructure management                                        |
| Jumpbox Windows      | 172.30.64.179              | RDP / local admin tooling  | Primary administrative entry point                                       |
| Jumpbox Ubuntu       | 172.30.64.180              | SSH / browser-based access | Linux administration plus Grafana and InfluxDB monitoring services       |
| Proxmox Host iLO     | https://192.168.64.11      | Web console                | Out-of-band hardware management for Server1                              |
| Server2 iLO          | https://192.168.64.21      | Web console                | Out-of-band management endpoint for Server2                              |
| Lab Switch           | ssh admin@192.168.64.2     | SSH                        | Physical switching, VLAN trunk control, and upstream lab-network handoff |

Figure 4 shows the Proxmox management interface that administrators use
to control these workloads from the management network.

<img src="media/image6.png" style="width:6.5in;height:2.59797in" />

<span id="fig_04" class="anchor"></span>Figure 4. Proxmox VE management
interface

<span id="tbl_07" class="anchor"></span>Table 7. Company 1 virtual
machine inventory

| **Virtual Machine** | **Operating System** | **IP Address**                                      | **VLAN**          | **Purpose**                                                                                                                       |
|---------------------|----------------------|-----------------------------------------------------|-------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| C1-DC1              | Windows Server 2022  | 172.30.64.130                                       | VLAN 20           | Primary Domain Controller                                                                                                         |
| C1-DC2              | Windows Server 2022  | 172.30.64.131                                       | VLAN 20           | Secondary Domain Controller                                                                                                       |
| C1-WebServer        | Windows Server 2022  | 172.30.64.162                                       | VLAN 30           | Standalone IIS server in the Company 1 DMZ with internal HTTP and HTTPS enabled                                                   |
| C1-Client1          | Windows 10           | 172.30.64.2 (DHCP reservation); 172.30.64.189 (SAN) | VLAN 10 / VLAN 40 | Client workstation with SAN iSCSI disk, Veeam Agent file-level backup to Server2, and managed RDP access through the jumpbox path |
| C1-Client2          | Ubuntu Linux         | 172.30.64.3 (DHCP reservation); 172.30.64.190 (SAN) | VLAN 10 / VLAN 40 | Client Workstation with SAN iSCSI disk                                                                                            |

<span id="tbl_08" class="anchor"></span>Table 8. Company 2 virtual
machine inventory

| **Virtual Machine** | **Operating System** | **IP Address**      | **VLAN** | **Purpose**                                                                                      |
|---------------------|----------------------|---------------------|----------|--------------------------------------------------------------------------------------------------|
| C2-DC1              | Ubuntu Server        | 172.30.64.146       | VLAN 120 | Primary Domain Controller                                                                        |
| C2-DC2              | Ubuntu Server        | 172.30.64.147       | VLAN 120 | Secondary Domain Controller                                                                      |
| C2-WebServer        | Linux Container      | 172.30.64.170       | VLAN 130 | Nginx-based Linux container web server in the Company 2 DMZ with internal HTTP and HTTPS enabled |
| C2-Client1          | Linux Client         | 172.30.64.66 (DHCP) | VLAN 110 | Client Workstation (realm member via SSSD)                                                       |

<span id="tbl_09" class="anchor"></span>Table 9. Shared administrative
systems

| **System**        | **IP Address** | **VLAN**    | **Purpose**           |
|-------------------|----------------|-------------|-----------------------|
| Jumpbox Windows   | 172.30.64.179  | VLAN 99     | Administrative Access |
| Jumpbox Ubuntu    | 172.30.64.180  | VLAN 99     | Administrative Access |
| OPNsense Firewall | 192.168.64.3   | WAN Network | Network Gateway       |

Figure 5 complements the inventory tables by showing how the tenant
workloads are grouped logically inside the shared virtualization
platform.

<img src="media/image7.png" style="width:6.89583in;height:4.66944in" />

<span id="fig_05" class="anchor"></span>Figure 5. Virtual machine
logical layout

3.6 Identity, DNS, and DHCP Services
------------------------------------

Identity services are intentionally split by tenant. Company 1 and
Company 2 each maintain their own authentication, DNS, and DHCP services
to preserve administrative separation and reduce cross-tenant
dependency, and no trust relationship exists between the two domains.

Tables 10 and 11 identify the domain controller roles for each
organization, while Tables 12 and 13 summarize DHCP scope information.
Together, these tables show how addressing and authentication stay
isolated even though both tenants share the same cloud platform. On
Company 1, custom groups such as C1-G-Admins and C1-G-Employees were
created in Active Directory to separate administrative and employee
identities. On the Company 2 Linux client, domain-member services use
SSSD and the Samba AD controller addresses 172.30.64.146 and
172.30.64.147 for authentication and name resolution.

During final internal-web validation, DNS on both tenant controller sets
was also extended to support cross-company name resolution for the
mirrored web services. `c1-webserver.c1.local` resolved to
172.30.64.162 and 172.30.65.162, while `c2-webserver.c2.local`
resolved to 172.30.64.170 and 172.30.65.170. This allowed the Site 1
Linux clients, Windows clients, and approved jump hosts to test the
internal tenant web names directly instead of relying only on raw IP
addresses.

Client-side resolver behavior required different handling depending on
platform. `C1-Client2-Linux` used `systemd-resolved` and needed both
`~c1.local` and `~c2.local` routing domains present for predictable
cross-company lookups, while the Company 2 Linux client on Site 1 used
traditional `/etc/resolv.conf` and NetworkManager with
172.30.64.146/147 as DNS servers. The final state therefore depends on
both replicated zone content and correct client resolver configuration.

<span id="tbl_10" class="anchor"></span>Table 10. Company 1 domain
controllers

| **Server** | **Role**                    | **IP Address** | **VLAN** |
|------------|-----------------------------|----------------|----------|
| C1-DC1     | Primary Domain Controller   | 172.30.64.130  | VLAN 20  |
| C1-DC2     | Secondary Domain Controller | 172.30.64.131  | VLAN 20  |

<span id="tbl_11" class="anchor"></span>Table 11. Company 2 domain
controllers

| **Server** | **Role**                    | **IP Address** | **VLAN** |
|------------|-----------------------------|----------------|----------|
| C2-DC1     | Primary Domain Controller   | 172.30.64.146  | VLAN 120 |
| C2-DC2     | Secondary Domain Controller | 172.30.64.147  | VLAN 120 |

<span id="tbl_12" class="anchor"></span>Table 12. Company 1 DHCP scope
summary

| **Network**    | **Address Range**          | **Purpose**       |
|----------------|----------------------------|-------------------|
| 172.30.64.0/26 | 172.30.64.2 – 172.30.64.62 | C1 Client Network |

<span id="tbl_13" class="anchor"></span>Table 13. Company 2 DHCP scope
summary

| **Network**     | **Address Range**            | **Purpose**       |
|-----------------|------------------------------|-------------------|
| 172.30.64.64/26 | 172.30.64.66 – 172.30.64.126 | C2 Client Network |

-   Company 1 AD domain functional level is documented as Windows
    Server 2016.

-   Client DNS settings are delivered by DHCP and point to the
    tenant-specific domain controllers.

-   Company 1 DNS is implemented on both domain controllers and
    currently provides authoritative internal name resolution together
    with recursive upstream resolution. The documented configuration
    includes the tenant reverse lookup zone, a configured forwarder, and
    successful internal and external name resolution from the Company 1
    DNS service. The DMZ-based Company 1 web service on C1-WebServer now
    supports both HTTP and HTTPS, with internal HTTPS validated directly
    at https://172.30.64.162 and through the tenant DNS host name
    https://c1-webserver.c1.local.

Company 2 DHCP is implemented as an ISC DHCP failover pair rather than
as two unrelated standalone daemons. C2-DC1 operates as the primary node
and C2-DC2 as the secondary node for the 172.30.64.64/26 client scope,
with the expected failover peer settings, lease coordination values, and
tenant DNS delivery. Client validation from Company.c2.local confirmed
that the scope is actively assigning the expected address, gateway, and
DNS configuration.

Company 2 DNS is provided by the Samba domain controllers and includes
both the c2.local and \_msdcs.c2.local Active Directory-integrated zones
with secure updates enabled. Validation from both controllers confirmed
successful internal host resolution and recursive resolution for
external names through the Company 2 DNS service. The Company 2 DMZ web
service on C2-WebServer now supports both HTTP and HTTPS, with internal
HTTPS validated directly at https://172.30.64.170. A dedicated A record
for c2-webserver.c2.local exists only within the Company 2 tenant DNS
namespace to preserve tenant separation.

3.7 Storage and SAN Services
----------------------------

Server2 is the storage backbone for the environment. It provides
tenant-separated iSCSI volumes for Company 1 and Company 2, plus
dedicated backup repository volumes for Veeam. Architecturally, Server2
acts as the centralized storage backbone, providing SAN volumes over
dedicated VLANs while separating storage traffic from routed tenant
networks. Storage traffic is placed on dedicated SAN VLANs and network
interfaces. In the Company 1 implementation, C1-DC1, C1-DC2, C1-Client1,
and C1-Client2 each use a dedicated SAN interface on VLAN 40 to access
Server2 directly, with Server2 SAN\_C1 at 172.30.64.186 and initiator
addresses 172.30.64.187 through 172.30.64.190. Company 1 file services
are layered above this storage using a DFS namespace and DFS replication
design.

Tables 14 through 18 document the storage layout in detail: the Server2
volume allocation, the iSCSI target mappings, and the SAN VLAN and
interface design used to keep storage traffic separate from routed
client and server traffic. For Company 1, storage is consumed over the
dedicated VLAN 40 SAN path, while file services are published through
the DFS namespace at \\\\c1.local\\namespace so that users interact with
consistent Public and Private share paths rather than with raw
replicated folders.

The final Company 1 file-service model uses Access-Based Enumeration on
the underlying target shares and per-user private folders for admin,
employee1, and employee2. Public collaboration data remains visible
through the shared namespace path, while private content is restricted
to the matching user folder. This preserves the intended
collaboration-versus-private-data split while keeping the Windows-backed
DFS design clean and supportable.

<span id="tbl_13a" class="anchor"></span>Table 13A. Company 1 file
service access control summary

| **Item**                  | **Final Configuration**                                                                                                                                                                                                                                                                          | **Project Relevance**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| Namespace presentation    | \\\\c1.local\\namespace with public and private logical folders                                                                                                                                                                                                                                  | Preserves the documented DFS namespace access model for Company 1 clients.                                                  |
| Back-end share targets    | Pub1 and Priv1 on C1-DC1, Pub2 and Priv2 on C1-DC2, with C1FS as the secondary-site target                                                                                                                                                                                                       | Provides multiple file-service nodes behind the namespace.                                                                  |
| Share-layer permissions   | Authenticated Users = Change, BUILTIN\\Administrators = Full                                                                                                                                                                                                                                     | Allows internal users to work in the shares while preserving administrative control.                                        |
| Private NTFS model        | Per-user folders for admin, employee1, and employee2 with owner-only modify access plus SYSTEM/Administrators full control                                                                                                                                                                       | Meets the requirement that private data is visible only to the owning user.                                                 |
| Fault tolerance           | DFSR replicated folders for public and private; C1-DC2 766 GB SAN disk read-only state corrected before replication validation                                                                                                                                                                   | Restores replicated file-service behavior across both Company 1 domain controllers.                                         |
| Windows client validation | C1-Client1 validated with admin, employee1, and employee2; Public was writable by all three and each user could see only that user's own private folder                                                                                                                                          | Provides direct client evidence for appropriate access control.                                                             |
| Linux client validation   | C1-Client2-Linux now allows admin, employee1, and employee2 to sign in locally and automatically receive \~/C1\_Public plus \~/C1\_Private through per-user CIFS sessions; public is presented from the user-facing shared-content directory and private maps directly to the matching user path | Confirms that the Linux client also satisfies the mounted-share requirement and mirrors the Windows access-control outcome. |

Company 1 Linux client access was normalized so that admin, employee1,
and employee2 can sign in locally and automatically receive
\~/C1\_Public and \~/C1\_Private through per-user CIFS sessions. The
public mount is bound to the user-facing shared-content directory, and
the private mount is bound directly to the corresponding per-user
private path, giving the Ubuntu client the same effective access model
as the Windows client without exposing DFSR system folders in the user
workflow.

Company 2 uses a simpler Linux file-service model than Company 1. C2-DC1
(172.30.64.146) and C2-DC2 (172.30.64.147) publish identical Samba
shares from the GlusterFS replicated volume gv0 mounted at
/mnt/sync\_disk. C2\_Public is presented as the shared collaboration
location, while C2\_Private maps each user directly to
/mnt/sync\_disk/Private/%U so that each account receives its own private
path.

<span id="tbl_14a" class="anchor"></span>Table 14A. Company 2 replicated
file service summary

| **Item**           | **Final Configuration**                                                                                                                                                                                                                             | **Project Relevance**                                                                                                                                       |
|--------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| File-service nodes | C2-DC1 172.30.64.146 and C2-DC2 172.30.64.147                                                                                                                                                                                                       | Provides two Company 2 domain controllers that can both publish the same file shares                                                                        |
| Shared data layer  | GlusterFS replicated volume gv0 mounted at /mnt/sync\_disk on both servers                                                                                                                                                                          | Implements the replicated storage layer used for Company 2 file-service fault tolerance                                                                     |
| Public share       | C2\_Public -&gt; /mnt/sync\_disk/Public                                                                                                                                                                                                             | Allows Company 2 internal users to read and modify the shared collaboration folder                                                                          |
| Private share      | C2\_Private -&gt; /mnt/sync\_disk/Private/%U                                                                                                                                                                                                        | Redirects each authenticated user to a private per-user folder                                                                                              |
| Authorized users   | Members of c2\_file\_users, validated with admin, employee1, and employee2                                                                                                                                                                          | Demonstrates controlled share access rather than anonymous or guest access                                                                                  |
| Client validation  | Company.c2.local validated with admin, employee1, and employee2; live SMB 3.1.1 sessions mounted \~/C2\_Public and \~/C2\_Private from 172.30.64.146 and all three users could write to Public while remaining limited to their own Private content | Confirms that the Linux client can reach the shares, that the mounts persist in the final workflow, and that the private-folder model is enforced per user. |

For Company 2, fault tolerance is implemented at the shared-storage and
service layer. GlusterFS volume gv0 operates as a two-brick replicate
volume across C2-DC1 and C2-DC2, and the Linux client validation
confirmed that admin, employee1, and employee2 can mount \~/C2\_Public
and \~/C2\_Private, write to Public, and remain limited to their own
Private content. This satisfies the project requirement for a replicated
file service with appropriate access control.

Company 2 storage validation also confirms tenant-separated iSCSI
presentation from Server2. The GlusterFS brick disks are delivered over
the dedicated SAN interfaces, while user and server traffic continues to
use the routed tenant network interfaces, preserving the required
separation between storage traffic and general user-generated traffic.

<span id="tbl_14b" class="anchor"></span>Table 14B. Company 2 service
stack summary

| Function                           | Final Software / Service           | Implementation Notes                                                                                                                                                                                  |
|------------------------------------|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| DNS, directory, and authentication | Samba AD DC on C2-DC1 and C2-DC2   | Provides the c2.local domain, AD-compatible authentication, and integrated DNS services. Validation confirmed the c2.local and \_msdcs.c2.local zones plus successful internal and recursive lookups. |
| DHCP                               | ISC DHCP failover pair             | C2-DC1 operates as primary and C2-DC2 as secondary for the 172.30.64.64/26 client scope, with MCLT 3600, split 128, and load balance max seconds 3.                                                   |
| SMB file sharing                   | Samba                              | Publishes C2\_Public and C2\_Private to internal users.                                                                                                                                               |
| Replicated storage                 | GlusterFS volume gv0               | Both domain controllers mount the replicated data set at /mnt/sync\_disk so the same share data remains available on either node.                                                                     |
| Client access workflow             | Linux client auto-mount validation | admin, employee1, and employee2 were validated to sign in and receive \~/C2\_Public plus the correct per-user \~/C2\_Private over SMB 3.1.1 from 172.30.64.146.                                       |
| iSCSI initiators and SAN isolation | open-iscsi on C2-DC1 and C2-DC2    | Sessions from 172.30.64.195 and 172.30.64.196 connect to Server2 SAN\_C2 at 172.30.64.194, and the SAN interfaces remain separate from vlan120 tenant traffic.                                        |
| Remote client access               | OpenSSH on Company.c2.local        | SSH access to 172.30.64.66 was validated from the management path, which satisfies the Linux client remote-access requirement.                                                                        |

<span id="tbl_14" class="anchor"></span>Table 14. Server2 volume layout

| **Drive Letter** | **Volume Name**               | **File System**            | **Purpose**                                                                                         |
|------------------|-------------------------------|----------------------------|-----------------------------------------------------------------------------------------------------|
| C:               | System Volume                 | NTFS                       | Windows Server operating system                                                                     |
| S:               | C1\_ISCSI                     | NTFS                       | iSCSI storage for Company 1                                                                         |
| T:               | C2\_ISCSI                     | NTFS                       | iSCSI storage for Company 2                                                                         |
| V:               | Backups                       | ReFS                       | Primary Veeam backup repository                                                                     |
| Site2 R:         | Site1OffsiteFromServer2\\Repo | NTFS via SMB shared folder | Remote offsite shared-folder repository on 172.30.65.180 used by the Site1-to-Site2 Backup Copy job |

<span id="tbl_15" class="anchor"></span>Table 15. Company 1 iSCSI
targets

| **Target Name** | **Initiator IP** | **Storage Location**  | **Purpose**      |
|-----------------|------------------|-----------------------|------------------|
| c1-dc1          | 172.30.64.187    | S:\\iSCSIVirtualDisks | DC1 Data Storage |
| c1-dc2          | 172.30.64.188    | S:\\iSCSIVirtualDisks | DC2 Data Storage |
| target-win10    | 172.30.64.189    | S:\\iSCSIVirtualDisks | Client1 SAN Disk |
| target-ubuntu   | 172.30.64.190    | S:\\iSCSIVirtualDisks | Client2 SAN Disk |

<span id="tbl_16" class="anchor"></span>Table 16. Company 2 iSCSI
targets

| **Target Name** | **Initiator IP** | **Storage Location**  | **Purpose**      |
|-----------------|------------------|-----------------------|------------------|
| c2-dc1          | 172.30.64.195    | T:\\iSCSIVirtualDisks | DC1 Data Storage |
| c2-dc2          | 172.30.64.196    | T:\\iSCSIVirtualDisks | DC2 Data Storage |

<span id="tbl_17" class="anchor"></span>Table 17. SAN VLAN design

| **VLAN** | **Network**      | **Purpose**           |
|----------|------------------|-----------------------|
| VLAN 40  | 172.30.64.184/29 | Company 1 SAN Network |
| VLAN 140 | 172.30.64.192/29 | Company 2 SAN Network |

<span id="tbl_18" class="anchor"></span>Table 18. Storage server SAN
interfaces

| **Interface** | **IP Address** | **Purpose**             |
|---------------|----------------|-------------------------|
| SAN\_C1       | 172.30.64.186  | Company 1 iSCSI Network |
| SAN\_C2       | 172.30.64.194  | Company 2 iSCSI Network |

Figure 6 confirms the storage volume presentation on Server2, and Figure
7 shows the network-side interface arrangement that supports management
traffic, Company 1 SAN presentation, and Company 2 SAN presentation as
separate paths.

<img src="media/image8.png" style="width:6.5in;height:3.64578in" />

<span id="fig_06" class="anchor"></span>Figure 6. Server2 storage volume
presentation

<img src="media/image9.png" style="width:6.5in;height:2.01807in" />

<span id="fig_07" class="anchor"></span>Figure 7. Server2 network
interface layout

3.8 Backup and Recovery
-----------------------

Veeam Backup & Replication is hosted on Server2 as the main backup
platform for Site 1. The implemented design uses three protection
classes: agentless system-level VM backup, file-based client backup, and
offsite backup copy to Site 2 over the site-to-site OpenVPN tunnel.

Tables 19 through 21 summarize the backup platform, repository
locations, and backup classes. Figure 8 is the overview image for this
section, while Figures 8A through 8C provide supporting screenshots for
the primary jobs, copy session, and remote copy inventory.

<span id="tbl_19" class="anchor"></span>Table 19. Backup infrastructure
components

| Component                         | Role                                                                                                                   | System                                                                       |
|-----------------------------------|------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| Veeam Backup Server               | Central backup management and restore orchestration                                                                    | Server2                                                                      |
| Backup Proxy                      | Data processing and transport for Proxmox VE backup jobs managed from Server2                                          | Proxmox Host                                                                 |
| Primary Backup Repository         | Primary server-side storage for Proxmox VE backup chains and the C1-Client1 Veeam agent backup                         | Server2                                                                      |
| Veeam Agent for Microsoft Windows | Agent-based file-level protection                                                                                      | C1-Client1                                                                   |
| Offsite Backup Repository         | Remote backup copy storage provided through a Veeam-managed SMB shared folder over the Site 1 to Site 2 OpenVPN tunnel | Site2-Offsite-SharedRepo (\\\\172.30.65.180\\Site1OffsiteFromServer2$\\Repo) |
| Backup Copy Job                   | Immediate-copy duplication of seven selected Proxmox VE backup jobs to Site2-Offsite-SharedRepo                        | Server2                                                                      |

<span id="tbl_20" class="anchor"></span>Table 20. Backup repository
layout

| **Drive**              | **Volume Name**                         | **File System**            | **Purpose**                                                                                                    |
|------------------------|-----------------------------------------|----------------------------|----------------------------------------------------------------------------------------------------------------|
| V:                     | Backups                                 | ReFS                       | Primary backup repository on Server2                                                                           |
| Site2 R:               | Site1OffsiteFromServer2\\Repo           | NTFS via SMB shared folder | Remote shared-folder repository on 172.30.65.180 for Site1 backup copy                                         |
| Site2 Local Repository | Not documented in this handover section | NTFS                       | Reserved for Site2 local backup operations on 172.30.65.180 and kept separate from the Site1 offsite copy path |

<span id="tbl_21" class="anchor"></span>Table 21. Backup scope by class

| Backup Class                                | Implemented Scope                                                                                                                                                         |
|---------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Agentless VM backup - Company 1             | C1-DC1, C1-DC2, C1-WebServer, C1-Client1, and C1-Client2 protected through Proxmox VE backup jobs                                                                         |
| Agentless VM backup - Company 2             | C2-DC1, C2-DC2, and C2-Client1 protected through Proxmox VE backup jobs                                                                                                   |
| Agentless VM backup - Shared infrastructure | Jumpbox Win10 and OPNsense protected through Proxmox VE backup jobs                                                                                                       |
| File-based backup                           | C1-Client1 designated folder path protected by Veeam Agent for Microsoft Windows in the Default Backup Repository on Server2                                              |
| Offsite VPN backup copy                     | Seven selected Proxmox VE backup jobs copied through the Site 1 to Site 2 OpenVPN tunnel to Site2-Offsite-SharedRepo at \\\\172.30.65.180\\Site1OffsiteFromServer2$\\Repo |

### 3.8.1 Agentless System-Level VM Backup

Agentless / system-level backup class: drive V: on Server2 formatted
with ReFS is the primary repository for the Proxmox VE backup chains.
These jobs protect the C1 servers, C1 clients, C1-WebServer, C2 servers,
C2 client, Jumpbox Win10, and OPNsense at the virtual machine level.

<img src="media/image10.png" style="width:6.4in;height:2.935in" />

<span id="fig_8a" class="anchor"></span>Figure 8A. Primary Veeam job
status

Figure 8A shows the primary Veeam jobs on Server2, including the Proxmox
VE jobs for both tenants, Jumpbox Win10, OPNsense, and the enabled
C1-Client1 agent-based file backup policy.

### 3.8.2 File-Based Client Backup

File-based backup class: C1-Client1 uses Veeam Agent for Microsoft
Windows to back up the designated client folder path to the Default
Backup Repository on Server2, which allows direct file-level restore
from the Veeam console without restoring the full VM.

<img src="media/image11.png" style="width:6.9in;height:3.3in" />

<span id="fig_08" class="anchor"></span>Figure 8. Veeam backup overview

Figure 8 provides the overall Veeam console view for this section.
Figures 8A through 8C serve as supporting evidence for the primary job
set, the Site1-to-Site2 copy session, and the remote copy inventory.

### 3.8.3 Offsite Backup Copy to Site 2

Selected local backup chains are copied to the Site2-Offsite-SharedRepo
SMB shared-folder repository at
\\\\172.30.65.180\\Site1OffsiteFromServer2$\\Repo on the R: volume
through the Site-to-Site OpenVPN tunnel, providing offsite backup
protection for Site 1. While formal RPO and RTO targets are not defined
in the current lab environment, the offsite backup copy provides an
additional recovery location in the event of a site-level failure.

<img src="media/image12.png" style="width:6.4in;height:4.77619in" />

<span id="fig_8b" class="anchor"></span>Figure 8B. Site 1 to Site 2
backup copy job

Figure 8B shows the Immediate backup copy job configured to transfer
data to Site2-Offsite-SharedRepo, the SMB shared-folder repository
backed by \\\\172.30.65.180\\Site1OffsiteFromServer2$\\Repo.

<img src="media/image13.png" style="width:6.4in;height:3.05239in" />

<span id="fig_8c" class="anchor"></span>Figure 8C. Remote backup copy
inventory

Figure 8C shows the remote copy target now represented by
Site2-Offsite-SharedRepo on 172.30.65.180, using the R:-based shared
repository path \\\\172.30.65.180\\Site1OffsiteFromServer2$\\Repo.

3.9 Value Added Features
------------------------

In addition to the core services required to make the environment
functional, four value-added features were implemented to improve
administration, visibility, user experience, and supportability. These
features are highlighted separately because they extend the platform
beyond a minimum viable build and demonstrate practical operational
improvements that a client or MSP would care about.

### 3.9.1 Company Branding through Group Policy (Company 1)

A Group Policy Object was created in the Company 1 Active Directory
domain to standardize the desktop wallpaper on targeted workstations.
This feature demonstrates centralized desktop management and shows how
the domain can be used to enforce a recognizable company identity across
client systems without manual workstation-by-workstation changes.

Table 22 summarizes the configuration used to deliver this policy, and
Figure 9 shows the result captured from the administrative interface.
Together they demonstrate that the feature is not only conceptual, but
actually implemented.

<span id="tbl_22" class="anchor"></span>Table 22. Group Policy branding
configuration summary

| **Setting**       | **Value**                |
|-------------------|--------------------------|
| Domain            | c1.local                 |
| Domain Controller | C1-DC1                   |
| GPO Name          | GPO\_Wallpaper\_Client1  |
| Linked OU         | Computers                |
| Target System     | CLIENT1                  |
| Policy Type       | Desktop Wallpaper Policy |

Figure 9 is the evidence screenshot for the Group Policy implementation
described in Table 22.

<img src="media/image14.png" style="width:6.2in;height:4.22835in" />

<span id="fig_09" class="anchor"></span>Figure 9. Group Policy desktop
branding evidence

### 3.9.2 Infrastructure Monitoring Dashboard (Grafana)

A containerized Grafana and InfluxDB stack was deployed on the Ubuntu
jumpbox (172.30.64.180) to provide real-time monitoring of the virtual
infrastructure. Proxmox VE writes host and workload metrics to the local
InfluxDB service on port 8086, and Grafana publishes the browser-based
dashboard on port 3000 for daily operations from the management network.
This value-added feature improves operational awareness by allowing
support staff to review CPU load, memory usage, I/O conditions,
interface activity, and running workloads from a single dashboard rather
than checking each system individually.

Table 23 lists the key metrics exposed through the dashboard, and Figure
10 shows how those metrics are presented to an operator during routine
monitoring from the Ubuntu jumpbox monitoring stack.

<span id="tbl_23" class="anchor"></span>Table 23. Grafana dashboard
metrics

| **Metric**               | **Description**                               |
|--------------------------|-----------------------------------------------|
| Server CPU Usage         | Real-time CPU utilization of the Proxmox host |
| Load Average             | Current system load average                   |
| I/O Wait                 | Disk I/O waiting time                         |
| Memory Usage             | Total memory consumption of the server        |
| Running Virtual Machines | List of active virtual machines               |
| Running LXC Containers   | Status of running Linux containers            |
| Network Interfaces       | Monitoring of NIC traffic and performance     |

Figure 10 shows the live Grafana dashboard view for the Proxmox
environment, including host resource usage, workload counts, and
interface activity collected through the local InfluxDB metrics service.

<img src="media/image15.png" style="width:6.5in;height:2.61372in" />

<span id="fig_10" class="anchor"></span>Figure 10. Grafana
infrastructure dashboard

### 3.9.3 Web-Based Server Administration (Cockpit)

Cockpit was deployed to simplify browser-based administration of the
Ubuntu-based Company 2 servers. This value-added feature reduces
dependence on direct SSH sessions by exposing health indicators, logs,
service controls, and a web terminal through a support-friendly
interface. It is especially useful when handover documentation must
support administrators with mixed Windows and Linux experience.

Table 24 summarizes the management capabilities delivered by Cockpit.
Figure 11 shows the overview page available to an administrator, and
Figure 12 shows the browser-based terminal used for direct command-line
tasks.

<span id="tbl_24" class="anchor"></span>Table 24. Cockpit management
features

| **Feature**               | **Description**                                                   |
|---------------------------|-------------------------------------------------------------------|
| System Health Monitoring  | Displays system alerts and service status                         |
| CPU and Memory Monitoring | Shows real-time resource usage                                    |
| System Logs               | Allows administrators to view and filter system logs              |
| Service Management        | Start, stop, and manage system services                           |
| Terminal Access           | Provides a browser-based terminal for command-line administration |
| Network Configuration     | Displays network interface information                            |

Figures 11 and 12 provide interface evidence for the Cockpit functions
summarized in Table 24.

<img src="media/image16.png" style="width:6.5in;height:2.15905in" />

<span id="fig_11" class="anchor"></span>Figure 11. Cockpit
administration overview

<img src="media/image17.png" style="width:6.5in;height:2.05744in" />

<span id="fig_12" class="anchor"></span>Figure 12. Cockpit web terminal

### 3.9.4 Centralized Infrastructure Management using Windows Admin Center

Windows Admin Center was deployed on the Windows jumpbox to provide
centralized management of Windows servers and selected endpoints. This
value-added feature improves support efficiency by consolidating
monitoring, service control, event review, remote PowerShell, and system
management into a single web console on the management network.

Tables 25 and 26 describe the systems managed by Windows Admin Center
and the functions it exposes. Figures 13 and 14 provide evidence of the
connection inventory and the detailed server management view.

<span id="tbl_25" class="anchor"></span>Table 25. Windows Admin Center
managed systems

| **System**     | **IP Address** | **Role**                              |
|----------------|----------------|---------------------------------------|
| C1-DC1         | 172.30.64.130  | Company 1 Primary Domain Controller   |
| C1-DC2         | 172.30.64.131  | Company 1 Secondary Domain Controller |
| Client1        | 172.30.64.2    | Company 1 Windows Client              |
| Storage Server | 192.168.64.20  | Backup and SAN Storage Server         |
| Jumpbox        | 172.30.64.179  | Administrative Access System          |

<span id="tbl_26" class="anchor"></span>Table 26. Windows Admin Center
capabilities

| **Feature**        | **Description**                                           |
|--------------------|-----------------------------------------------------------|
| Server Monitoring  | Displays CPU, memory, and storage usage                   |
| Event Viewer       | Provides centralized access to system event logs          |
| Remote PowerShell  | Allows administrators to run PowerShell commands remotely |
| Service Management | Start, stop, and manage system services                   |
| Storage Management | Monitor disks and storage volumes                         |
| System Updates     | Manage Windows updates for servers and clients            |

Figures 13 and 14 show the Windows Admin Center connection inventory and
a representative server management view that correspond to Tables 25 and
26.

<img src="media/image18.png" style="width:6.5in;height:1.08885in" />

<span id="fig_13" class="anchor"></span>Figure 13. Windows Admin Center
connection inventory

<img src="media/image19.png" style="width:6.5in;height:2.60966in" />

<span id="fig_14" class="anchor"></span>Figure 14. Windows Admin Center
server overview

3.10 Site-to-Site VPN Security and Administrative Access
--------------------------------------------------------

Security controls in this section are centered on the Site 1 to Site 2
OpenVPN design, the routed prefixes carried by that tunnel, and the
firewall rules that keep backup traffic and tenant traffic constrained
to approved paths.

The final demonstration state added a narrow web exception on top of
that baseline. Specific Site 1 client-VLAN and OpenVPN rules were added
so that Company 1 and Company 2 clients could reach each other's
internal web servers over `80/443`, and so that the same dual-record web
names could also be reached across the Site 1 to Site 2 tunnel when DNS
returned the remote mirror IP. These changes were intentionally limited
to the internal web services and did not replace the broader tenant
separation model.

Figures 15 and 16 provide live connection-status evidence from the Site
1 and Site 2 firewalls and confirm that the site-to-site OpenVPN tunnel
is established at both ends.

### 3.10.1 Site-to-Site VPN Security

<img src="media/image20.png" style="width:6.6in;height:1.09569in" />

<span id="fig_15" class="anchor"></span>Figure 15. Site 1 OpenVPN client
status

Figure 15 shows Site 1 operating as the OpenVPN client with the
Site1-to-Site2 instance connected to the remote peer at 10.50.17.31. The
tunnel-side IPv4 address is reported as 192.168.65.2 and the session
status is shown as connected.

<img src="media/image21.png" style="width:6.6in;height:1.09871in" />

<span id="fig_16" class="anchor"></span>Figure 16. Site 2 OpenVPN server
status

Figure 16 shows Site 2 operating as the OpenVPN server with the common
name site1-openvpn-client connected from 10.50.10.33:7429. The active
tunnel-side IPv4 address is 192.168.65.2 and the session status is shown
as ok.

Site-to-site connectivity between Site 1 and Site 2 is implemented with
OpenVPN. The current configuration state shows Site 1 operating as the
OpenVPN client and Site 2 operating as the OpenVPN server. The tunnel
uses TCP port 33664, tun mode, subnet topology, certificate validation
under the OpenVPN-S2S-CA, and a shared static TLS key named
openvpn-s2s-key.

On Site 1, the client instance is described as Site1-to-Site2 and uses
the certificate site1-openvpn-client to connect to the remote endpoint
10.50.17.31. On Site 2, the server instance is described as
Site2-S2S-OpenVPN and uses the certificate site2-openvpn-server with a
tunnel network of 192.168.65.0/24. The routed intent carried across the
tunnel is 172.30.64.0/24 for Site 1, 172.30.65.0/24 for Site 2, and a
host-specific path for Server2 at 192.168.64.20/32 so that the Site 1
Veeam server can reach the Site 2 shared-folder repository hosted on
172.30.65.180. Even though the design uses a single site-to-site VPN,
Company 1 and Company 2 do not share unrestricted inter-site access
because the tunnel only carries approved routed prefixes and the
OPNsense rule base continues to enforce tenant separation across the VPN
path. This design ensures that the VPN functions as a controlled
transport channel rather than as a trusted extension of the internal
network.

Table 27 summarizes the single inter-site VPN, the routed prefixes it
carries, and the firewall-controlled exception used for Veeam offsite
copy. Figure 17 reinforces that traffic control remains centered on the
firewall.

<span id="tbl_27" class="anchor"></span>Table 27. Inter-site VPN routing
and firewall control summary

| Control Area                 | Site 1 / Source                                                    | Site 2 / Destination                                               | Security Intent                                                                                |
|------------------------------|--------------------------------------------------------------------|--------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Shared VPN transport         | Site1-to-Site2 OpenVPN client                                      | Site2-S2S-OpenVPN server                                           | Single inter-site tunnel used only for approved cross-site traffic                             |
| Approved routed prefixes     | 172.30.64.0/24 and 192.168.64.20/32                                | 172.30.65.0/24 and 172.30.65.180/32                                | Carries site routes plus the Server2-to-repository path required for offsite backup copy       |
| Tenant isolation enforcement | Company 1 and Company 2 remain separated by VLAN and subnet policy | Company 1 and Company 2 remain separated by VLAN and subnet policy | OPNsense rules prevent unrestricted cross-tenant access even though both tenants share one VPN |

Figure 17 complements Table 27 by showing the firewall-centered view of
segmentation and controlled traffic flow.

<img src="media/image22.png" style="width:6.89583in;height:4.24375in" />

<span id="fig_17" class="anchor"></span>Figure 17. Firewall-centered
security segmentation

-   SAN VLANs should be limited to iSCSI traffic between Server2 and
    authorized initiators.

-   Cross-tenant connectivity should remain blocked unless explicitly
    justified and approved.

-   Firewall changes should be documented with pre-change backup and
    post-change validation steps. The current implementation includes
    host-specific rules that permit Server2 (192.168.64.20) and the Site
    2 repository host (172.30.65.180) to exchange the SMB traffic
    required for shared-folder repository access and offsite backup copy
    operations over the OpenVPN tunnel.

### 3.10.2 Administrative Access

Routine administrative access should originate from Jumpbox Windows
(172.30.64.179) or Jumpbox Ubuntu (172.30.64.180) on VLAN 99. The Ubuntu
jumpbox also hosts the Grafana dashboard at http://172.30.64.180:3000
and the local InfluxDB metrics service used by the Proxmox monitoring
view. In the evidence set, RDP was enabled on C1-DC1, C1-DC2,
C1-WebServer, C1-Client1, and the Windows jumpbox, while SSH was active
on C1-Client2, C2-DC1, and C2-Client1. C1-Client1 was demonstrated
through the managed jumpbox workflow rather than as a directly exposed
endpoint, and the DMZ-based C1-WebServer is administered through the
same controlled path.

3.11 Maintenance and Daily Duties
---------------------------------

The following guidance is written for the receiving support team. These
checks are not a substitute for monitoring alerts, but they establish a
practical operational baseline for daily support.

Table 28 translates the design into daily, weekly, and monthly duties so
that the report is useful during actual operations rather than only
during grading.

<span id="tbl_28" class="anchor"></span>Table 28. Recommended
operational checks

| **Cadence**            | **Required Checks**                                                                                                                                                                                                                                  | **Evidence / Outcome**               |
|------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| Daily                  | Review Proxmox host health, verify Veeam backup and backup copy job success, verify OpenVPN site-to-site availability when intersite copy is required, confirm firewall/gateway availability, check Grafana for abnormal CPU, memory, or I/O trends. | Dashboard screenshots or ticket note |
| Weekly                 | Review local and offsite repository free space, validate jumpbox accessibility, confirm tenant DNS/DHCP health, verify reachability to the Site2 repository host at 172.30.65.180, inspect SAN interface state on Server2.                           | Ops checklist or change record       |
| Monthly                | Apply approved patch cycle, export configuration backups where available, review firewall rule exceptions, test one representative restore path from the local or offsite repository.                                                                | Change record and restore evidence   |
| After Any Major Change | Re-test authentication, DNS resolution, VM state, backup success, backup copy reachability, monitoring visibility, and OpenVPN site-to-site reachability.                                                                                            | Post-change validation record        |

### 3.11.1 Standard Change Workflow

-   Confirm an approved maintenance window and rollback owner before
    making infrastructure changes.

-   Verify the latest successful backup or snapshot for affected
    systems.

-   Capture current-state evidence for firewall rules, network settings,
    VM configuration, or storage mappings before modification.

-   Validate service health after the change by checking authentication,
    routing, storage access, and backup job status.

-   Record the change outcome, operator, timestamp, and any follow-up
    action in the client change log.

### 3.11.2 Failure Domains and Recovery Priority

Table 29 identifies the systems that would cause the largest operational
impact if they failed, which helps prioritize incident response and
escalation.

<span id="tbl_29" class="anchor"></span>Table 29. Primary failure
domains

| **Component**             | **Operational Impact**                                                     | **Support Priority** |
|---------------------------|----------------------------------------------------------------------------|----------------------|
| OPNsense Firewall         | Loss of routing between VLANs and potential loss of internet egress.       | Critical             |
| Proxmox VE Host           | Loss of hosted tenant workloads and management access to virtual machines. | Critical             |
| Server2                   | Loss of SAN presentation and backup repository availability.               | Critical             |
| Tenant Domain Controllers | Authentication, DNS, and DHCP degradation for the affected tenant.         | High                 |
| Jumpbox Systems           | Reduced remote administration capability from the management network.      | Medium               |

3.12 Limitations, Risks, and Unresolved Items
---------------------------------------------

The architecture has a small number of operational limitations that
should be recognized during handover. The most significant are the
single Proxmox host, the shared dependence on Server2 for both storage
and backup services, and the need to formalize several operational
support practices before long-term production use. Table 30 summarizes
the highest-priority follow-up items for the receiving support team.

<span id="tbl_30" class="anchor"></span>Table 30. Known limitations and
unresolved items

| **Item**                       | **Current State**                                                                                            | **Required Action**                                                                                                 |
|--------------------------------|--------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| Single Proxmox host dependency | All Site 1 workloads depend on one Proxmox VE host.                                                          | Introduce host redundancy or document downtime expectations for the current single-host design.                     |
| Shared dependence on Server2   | Server2 remains the shared storage and backup backbone for both tenants.                                     | Document contingency planning for SAN and backup service interruption, or add service redundancy in a future phase. |
| Backup retention / RPO / RTO   | Repository locations are documented, but retention objectives and recovery targets are not formally defined. | Define retention, offsite policy, and recovery objectives in Veeam and document them for support use.               |
| Monitoring alert routing       | Dashboard visibility exists, but alert thresholds and notification routing are not documented.               | Define alert thresholds, recipients, and escalation path for operational monitoring.                                |

4. Conclusion
=============

This report described the Site 1 private cloud environment as a
client-facing technical handover document while preserving the formal
report structure required by CST8248. The environment successfully
demonstrates tenant isolation, centralized routing, mixed Windows and
Linux identity services, DFS-based file services, SAN storage,
site-to-site VPN connectivity, enterprise-style backup operations, and
remote backup copy to the Site 2 shared-folder repository on
172.30.65.180.

The most important implementation decisions were the use of Proxmox VE
for compute, OPNsense for policy and routing control, Windows AD DS and
Samba AD for tenant-specific identity, and Server2 as the central
storage and backup node. These choices created a supportable
environment, but also introduced clear single points of failure and
documentation gaps that must be addressed before a production handover.

Overall, the project provided a realistic example of how services,
addressing, topology, maintenance, and operational risk should be
documented for a receiving support team. From an educational
perspective, the project also demonstrates how infrastructure
architecture, operational procedures, and technical documentation must
work together to produce a maintainable cloud environment.

5. Appendices
=============

The appendices consolidate reference configurations, hardware baseline
details, storage and backup mappings, and the remaining operational
follow-up items so that a client or receiving support team can use them
both as implementation reference material and as a record of what still
requires validation or ownership assignment.

Appendix A. Network Addressing
------------------------------

Table A1 is the full addressing reference used by the environment and
should be treated as the source of truth for VLAN-to-subnet mapping. In
addition to the tenant VLANs, the table also records the separate
192.168.64.0/24 shared infrastructure and WAN-side management segment
that carries OPNsense WAN connectivity, Proxmox management access,
Server2 management, and hardware iLO access.

<span id="tbl_a1" class="anchor"></span>Table A1. Full VLAN addressing
matrix

| **VLAN**             | **Network**      | **Gateway**       | **Purpose**                                                                                                            | Traffic Type          |
|----------------------|------------------|-------------------|------------------------------------------------------------------------------------------------------------------------|-----------------------|
| VLAN 10              | 172.30.64.0/26   | 172.30.64.1       | Company 1 Client Network                                                                                               | Routed                |
| VLAN 20              | 172.30.64.128/28 | 172.30.64.129     | Company 1 Server Network                                                                                               | Routed                |
| VLAN 30              | 172.30.64.160/29 | 172.30.64.161     | Company 1 Web / DMZ                                                                                                    | Routed                |
| VLAN 40              | 172.30.64.184/29 | None (direct SAN) | Company 1 SAN Network                                                                                                  | Direct storage        |
| VLAN 99              | 172.30.64.176/29 | 172.30.64.177     | Management Network                                                                                                     | Restricted admin      |
| VLAN 110             | 172.30.64.64/26  | 172.30.64.65      | Company 2 Client Network                                                                                               | Routed                |
| VLAN 120             | 172.30.64.144/28 | 172.30.64.145     | Company 2 Server Network                                                                                               | Routed                |
| VLAN 130             | 172.30.64.168/29 | 172.30.64.169     | Company 2 Web / DMZ                                                                                                    | Routed                |
| VLAN 140             | 172.30.64.192/29 | None (direct SAN) | Company 2 SAN Network                                                                                                  | Direct storage        |
| Infrastructure / WAN | 192.168.64.0/24  | 192.168.64.1      | Shared infrastructure and WAN-side management segment for OPNsense WAN, Proxmox VE, Server2 management, and iLO access | Shared infrastructure |

Appendix B. DHCP Reference
--------------------------

Table B1 captures the documented DHCP client scopes for both tenant
networks so that support staff can quickly confirm the expected lease
ranges delivered to Company 1 and Company 2 clients.

<span id="tbl_b1" class="anchor"></span>Table B1. Documented DHCP scope

| **Scope Name**   | **Network**     | **Range**                    |
|------------------|-----------------|------------------------------|
| VLAN10\_Clients  | 172.30.64.0/26  | 172.30.64.2 – 172.30.64.62   |
| VLAN110\_Clients | 172.30.64.64/26 | 172.30.64.66 – 172.30.64.126 |

Company 1 DHCP is documented on Windows Server with hot-standby failover
between C1-DC1 and C1-DC2. Company 2 DHCP is documented as ISC DHCP
failover on the Samba domain controllers.

Appendix C. Storage Reference
-----------------------------

Tables C1 and C2 provide the storage-side reference values for interface
addressing and iSCSI target mapping, including the client-side Company 1
initiators that attach directly to Server2 over the SAN segment.

<span id="tbl_c1" class="anchor"></span>Table C1. Storage server
interfaces

| **Interface** | **IP Address** | **Purpose**                   |
|---------------|----------------|-------------------------------|
| LAN1-WAN      | 192.168.64.20  | Management and backup network |
| SAN\_C1       | 172.30.64.186  | Company 1 storage network     |
| SAN\_C2       | 172.30.64.194  | Company 2 storage network     |

<span id="tbl_c2" class="anchor"></span>Table C2. iSCSI target mappings

| **Target Name** | **Initiator IP** | **Storage Location**  |
|-----------------|------------------|-----------------------|
| c1-dc1          | 172.30.64.187    | S:\\iSCSIVirtualDisks |
| c1-dc2          | 172.30.64.188    | S:\\iSCSIVirtualDisks |
| c2-dc1          | 172.30.64.195    | T:\\iSCSIVirtualDisks |
| c2-dc2          | 172.30.64.196    | T:\\iSCSIVirtualDisks |
| target-win10    | 172.30.64.189    | S:\\iSCSIVirtualDisks |
| target-ubuntu   | 172.30.64.190    | S:\\iSCSIVirtualDisks |

Appendix D. Backup Reference
----------------------------

Tables D1 and D2 summarize the local and remote backup repository
volumes currently referenced by the environment and the Veeam backup
file types currently used in the environment.

<span id="tbl_d1" class="anchor"></span>Table D1. Backup repository
volumes

| **Drive**              | **File System**            | **Purpose**                                                                                                              |
|------------------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------|
| V:                     | ReFS                       | Primary backup storage on Server2                                                                                        |
| Site2 R:               | NTFS via SMB shared folder | Remote offsite backup copy repository on 172.30.65.180 (R:\\Site1OffsiteFromServer2\\Repo)                               |
| Site2 Local Repository | NTFS                       | Reserved for Site2 local backup operations on 172.30.65.180 and intentionally separated from the Site1 offsite copy path |

<span id="tbl_d2" class="anchor"></span>Table D2. Veeam backup file
types

Appendix E. Site 1 Requirement Coverage and Demonstration Notes
---------------------------------------------------------------

This appendix reorganizes the most important project requirements into
service areas so that the handover package is easier to use during
support onboarding and the final demonstration. It focuses on the Site 1
deliverable and includes Company 2 or inter-site items where the
documented Site 1 design depends on them.

### Network and Shared Infrastructure

-   Physical and out-of-band management: Figures 3A and 3B document the
    rack installation and cable layout. Server1 iLO is identified at
    192.168.64.11, and the Server2 iLO endpoint is identified at
    192.168.64.21 for later hardware administration.

-   Type 1 hypervisor: Proxmox VE runs on Server1 as the Site 1 compute
    platform and hosts the tenant servers, clients, jump systems, and
    shared services described in the virtual machine inventory.

-   Storage server and SAN presentation: Server2 provides
    tenant-separated SAN presentation. Company 1 uses SAN\_C1
    172.30.64.186 with initiators 172.30.64.187 through 172.30.64.190,
    while Company 2 uses SAN\_C2 172.30.64.194 with initiators
    172.30.64.195 and 172.30.64.196.

### Company 1

-   Identity, DNS, and DHCP: c1.local is hosted on C1-DC1 and C1-DC2
    with Windows Server AD DS. Company 1 also provides recursive DNS
    through the tenant domain controllers and uses Windows DHCP failover
    for the client scope.

-   Internal web publication and name resolution: Company 1 DNS was
    used to publish `c1-webserver.c1.local` to both Site 1 and Site 2
    internal web IPs (`172.30.64.162` and `172.30.65.162`), and Site 1
    clients were updated so that the internal Company 2 web name could
    also be resolved during the final cross-company demonstration.

-   File services and namespace: \\\\c1.local\\namespace publishes the
    public and private logical paths backed by Pub1, Priv1, Pub2, and
    Priv2 across the Company 1 domain controllers and the secondary-site
    file-service target.

-   Access model and client workflow: Public remains the shared
    collaboration area for internal users, while Private is structured
    as per-user folders for admin, employee1, and employee2. C1-Client1
    uses the published H: and P: mappings, and C1-Client2-Linux now
    provides the same users with automatic \~/C1\_Public and
    \~/C1\_Private mounts through per-user CIFS sessions.

-   Replication and permission state: Pub1, Priv1, Pub2, and Priv2 were
    aligned to the same Access-Based Enumeration and share-permission
    model, and DFS Replication resumed after the read-only state on the
    766 GB SAN disk attached to C1-DC2 was corrected.

### Company 2

-   Identity, DNS, and DHCP: Company 2 uses Samba AD DC on C2-DC1 and
    C2-DC2. The c2.local and \_msdcs.c2.local zones are AD-integrated
    primary zones with secure updates, recursive lookup was verified for
    external names, and ISC DHCP runs as a failover pair with C2-DC1 as
    primary and C2-DC2 as secondary for the 172.30.64.64/26 client
    scope.

-   Cross-company DNS support: the Site 1 Company 2 controllers also
    held the `c1.local` mini-zone required for final testing, and both
    C2-DC1 and C2-DC2 answered locally for `c1-webserver.c1.local`
    while continuing to resolve `c2-webserver.c2.local` to the Site 1
    and Site 2 internal Company 2 web IPs.

-   File services: C2\_Public and C2\_Private are published from the
    replicated GlusterFS volume gv0 mounted at /mnt/sync\_disk. Public
    maps to /mnt/sync\_disk/Public for shared collaboration, while
    Private maps to /mnt/sync\_disk/Private/%U for per-user storage
    limited to members of c2\_file\_users.

-   Fault tolerance and client workflow: GlusterFS gv0 runs as a
    two-brick replicate volume across 172.30.64.146 and 172.30.64.147,
    and Company.c2.local delivers \~/C2\_Public plus \~/C2\_Private to
    admin, employee1, and employee2 over SMB 3.1.1. Each user can write
    to Public and is restricted to the matching Private content.

-   iSCSI and SAN isolation: open-iscsi sessions from 172.30.64.195 and
    172.30.64.196 connect to Server2 SAN\_C2 at 172.30.64.194, while the
    tenant server addresses remain on vlan120 at 172.30.64.146 and
    172.30.64.147. This keeps storage traffic separate from the routed
    user and server path.

### Cross-Site and Remote Access

-   Site-to-site connectivity: Site 1 and Site 2 are linked by the
    documented OpenVPN tunnel, which carries the approved inter-site
    routes used for management dependencies and offsite backup copy
    traffic.

-   Internal web validation path: final OPNsense rule tuning on Site 1
    allowed Company 1 and Company 2 clients to reach the opposite
    company's internal web server on `80/443` both locally and across
    the OpenVPN tunnel when the mirrored remote IP was selected by DNS.

-   Administrative access: Jumpbox Windows and Jumpbox Ubuntu remain the
    approved management entry points. The Ubuntu jumpbox also provides
    the Grafana dashboard at http://172.30.64.180:3000 and hosts the
    local InfluxDB service used for Proxmox metrics collection. RDP is
    enabled on the Windows systems documented in the management section,
    and SSH is active on C1-Client2, C2-DC1, C2-DC2, and
    Company.c2.local.

-   Resolver alignment: Linux clients and jump hosts required explicit
    validation of search domains or resolver routing so that both
    `c1.local` and `c2.local` web names could be demonstrated
    consistently after restart.

-   Backup and offsite copy: Server2 hosts Veeam Backup and Replication
    for local VM backup, the C1-Client1 file-based backup workflow, and
    the Site1-to-Site2 backup copy path to the Site2-Offsite-SharedRepo
    SMB repository on 172.30.65.180 at
    \\\\172.30.65.180\\Site1OffsiteFromServer2$\\Repo on the R: volume.

### Operations and Demonstration Use

-   Operational use: This appendix is intended as a quick acceptance and
    handover guide. The body of the report explains the design and
    rationale, while this section groups the deployed service areas into
    a clear path for review, support onboarding, and final presentation.

6. References
=============

\[1\] Proxmox Server Solutions GmbH, "Proxmox Virtual Environment
Documentation," \[Online\]. Available:
https://pve.proxmox.com/pve-docs/. \[Accessed: Mar. 8, 2026\].

\[2\] OPNsense Project, "OPNsense Documentation," \[Online\]. Available:
https://docs.opnsense.org/. \[Accessed: Mar. 8, 2026\].

\[3\] Microsoft, "Windows Server Documentation," \[Online\]. Available:
https://learn.microsoft.com/windows-server/. \[Accessed: Mar. 8, 2026\].

\[4\] Samba Team, "Setting up Samba as an Active Directory Domain
Controller," \[Online\]. Available:
https://wiki.samba.org/index.php/Setting\_up\_Samba\_as\_an\_Active\_Directory\_Domain\_Controller.
\[Accessed: Mar. 8, 2026\].

\[5\] Veeam Software, "Veeam Backup and Replication Documentation,"
\[Online\]. Available: https://helpcenter.veeam.com/. \[Accessed: Mar.
8, 2026\].
