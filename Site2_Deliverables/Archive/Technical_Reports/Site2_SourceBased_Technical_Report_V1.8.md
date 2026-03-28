---
title: "Site 2 Infrastructure Deployment"
subtitle: "Integrated Technical Design, Validation, and Handover Report"
author: "Site 2 Infrastructure Delivery Team"
date: "March 24, 2026"
---

Design, Validation, and Handover Narrative for the Site 2 Environment Supporting Company 1, Company 2, and MSP Operations

**Prepared For:** Company 1, Company 2, and MSP stakeholders  
**Prepared By:** Site 2 Infrastructure Delivery Team  
**Document Context:** Client-facing technical handover package  

| Document Control | Value |
|---|---|
| Document Type | Formal technical handover and validation report |
| Environment Scope | Site 2 services supporting Company 1, Company 2, and MSP operations |
| Revision | 1.8 |
| Revision Date | March 24, 2026 |
| Status | Client-facing technical handover revision |
| Intended Audience | Client IT staff, MSP support teams, and successor operators |
| Distribution | Company stakeholders, MSP operations, and successor support teams |
| Document Classification | Internal technical handover and operational validation record |

**Engineering Contributors:** Bailey Kulla, Elyazid Sidelkheir, Ru Wang, Justin Rosseleve, Yiqin Huang, Omer Deniz

**Document Purpose:** This report explains the Site 2 architecture, operational logic, validation results, and handover-ready support context using design inputs, environment evidence, official vendor documentation, and live read-only validation collected for the Site 2 deployment.

**Document Positioning:** The report is intentionally written as a professional technical document first. Presentation flow and walkthrough guidance are maintained separately so that this document remains suitable for formal review, handover, and client-facing interpretation.

**Report Intent:** This document is written in a client/MSP handover style while retaining the formal structure expected in a formal technical handover document, including a title page, table of contents, executive summary, introduction, discussion, conclusion, appendices, and IEEE-style references.

\newpage

# Contents

[[TOC]]

\newpage

# List of Figures

**Figure 1.** Site 2 topology and service-role alignment  

**Figure 2.** Site 2 logical service inventory and platform role map  

**Figure 3.** OPNsense interfaces, aliases, and limited edge exposure  

**Figure 4.** OPNsense OpenVPN and inter-site rule mapping  

**Figure 5.** Company 1 service integration from the Site 2 management path  

**Figure 6.** `C2IdM1` Active Directory, DNS, and DHCP proof  

**Figure 7.** `C2IdM2` Active Directory, DNS, and DHCP proof  

**Figure 8.** Shared-forest and cross-domain DNS proof  

**Figure 9.** `C2FS` iSCSI-backed storage and mounted volume proof  

**Figure 10.** `C2FS` SMB share definitions and synchronization proof  

**Figure 11.** `C1SAN` isolated storage interface proof  

**Figure 12.** `C2SAN` isolated storage interface proof  

**Figure 13.** `S2-Ubuntu-Client` Company 1 client dual-web proof  

**Figure 14.** `C2LinuxClient` domain identity and dual-web proof  

**Figure 15.** `S2Veeam` repository, backup jobs, and offsite-copy proof  

# List of Tables

**Table 1.** Design inputs and evidence basis for Site 2  

**Table 2.** Evidence classes used in this report  

**Table 3.** Approved live validation vantage points  

**Table 4.** Observed Site 2 systems and service roles  

**Table 5.** Site 2 logical service inventory and role mapping  

**Table 6.** Site 2 network segments and gateways  

**Table 7.** OPNsense exposure, routing, and firewall policy summary  

**Table 8.** Company 1 service baseline and integration within Site 2  

**Table 9.** Company 2 identity, DNS, and DHCP summary  

**Table 10.** Storage and isolated SAN summary  

**Table 11.** Client-side validation summary  

**Table 12.** Internal web delivery summary  

**Table 13.** Backup and offsite-protection summary  

**Table 14.** Requirement-to-implementation traceability matrix  

**Table 15.** Service dependency and failure-domain view  

**Table 16.** Authentication and authorization model  

**Table 17.** Storage, backup, and recovery data-flow summary  

**Table 18.** Operational maintenance checks  

**Table 19.** Troubleshooting and fast triage guide  

**Table 20.** Current limitations and evidence gaps  

**Table 21.** Integrated design assurance summary  

**Table A1.** Observed addressing, gateways, and endpoints  

**Table B1.** Evidence and reference traceability  

**Table C1.** Service verification and assurance matrix

# Executive Summary

Site 2 operates as an integrated service environment that combines MSP administration, Company 1 service visibility, Company 2 core services, isolated storage, and backup or recovery workflows within a single managed design. Rather than being explained one server at a time, it is best understood as a coordinated platform in which routing, identity, storage, web delivery, and protection services all contribute to the final operating model.

This report is based on three evidence classes:

- design requirements and service objectives for the Site 2 environment
- the Site 2 environment evidence set, including the OPNsense XML export, logical inventory records, and SAN screenshots
- live read-only validation performed on March 23 and March 24, 2026

Current analysis and validation show Site 2 operating through three tightly related service layers:

- MSP management through controlled jump hosts, OPNsense segmentation, and an OpenVPN-backed inter-site path
- Company 1 service delivery through domain visibility, file-service adjacency, internal web publication, client participation, and isolated storage presence
- Company 2 core services through `C2IdM1`, `C2IdM2`, `C2FS`, `C2LinuxClient`, `C2WebServer`, and `C2SAN`

The most important technical findings are:

- the OPNsense configuration shows deliberate segmentation across MSP, `C1LAN`, `C1DMZ`, `C2LAN`, `C2DMZ`, and a Site 1 OpenVPN path, while exposing only the jump hosts at the WAN edge
- both `C2IdM1` and `C2IdM2` were healthy for Samba AD and DHCP, and both held the expected dual A records for `c1-webserver.c1.local` and `c2-webserver.c2.local`
- environment evidence indicates that `c1.local` and `c2.local` operate within a shared forest; the observed cross-domain DNS visibility and client behavior are consistent with that design
- `C2FS` showed a live iSCSI session to `172.30.65.194:3260`, a mounted data volume at `/mnt/c2_public`, valid `C2_Public` and `C2_Private` share definitions, and successful Site 1 to Site 2 synchronization
- both `S2-Ubuntu-Client` and `C2LinuxClient` resolved and reached `https://c1-webserver.c1.local` and `https://c2-webserver.c2.local`, confirming that the same hostnames work from both company perspectives
- available backup design evidence indicates that `S2Veeam` protects 10 machines to a Site 2 dedicated disk, stores file-share backup data, and copies those backups offsite to Site 1; live validation corroborated the management and control paths to the Veeam server

The remaining gaps are evidence gaps rather than design gaps. Final screenshots for OPNsense, Veeam console views, and interactive share access will strengthen presentation quality, but the current evidence already supports a complete and defensible Site 2 technical narrative.

# 1. Introduction

The purpose of this document is to describe Site 2 in a form that supports operational handover, ongoing support, and formal service validation. The report is intentionally written for a reader who may need to understand the environment quickly, assess its behavior, and support it afterward without relying on undocumented tribal knowledge.

This version is grounded in the available design inputs, the current Site 2 evidence set, official vendor documentation for the deployed technologies, and live read-only validation completed on March 23 and March 24, 2026. It is also written to reflect three senior perspectives at the same time: project delivery, network engineering, and systems administration. For that reason, each major section is expected to answer four questions clearly: what exists, why it was designed that way, how it behaves in operation, and which evidence supports that conclusion.

The report deliberately follows a formal handover structure so that it can be reviewed by technical leads, client stakeholders, and successor operators without requiring a separate explanatory walkthrough. That structure includes:

- formal report sections
- rationale and design discussion, not just build notes
- handover-oriented language
- figures, tables, appendices, and test traceability

For web-service validation, the report is intentionally limited to the internal service hostnames used by the environment:

- `https://c1-webserver.c1.local`
- `https://c2-webserver.c2.local`

The previously discussed external hostname is intentionally excluded from the technical narrative because it is outside the required validation scope for this final package.

# 2. Background

## 2.1 Design inputs and environment evidence

### Design and service expectations

The evidence set establishes two things at the same time: what Site 2 is expected to deliver as an operational environment, and what can be proven directly from the current implementation.

At the design level, Site 2 is expected to provide:

- MSP-controlled administrative entry through bounded jump-host access
- service delivery for both Company 1 and Company 2 within the same operating site
- segmented networking, site-to-site communication, and limited edge exposure
- SMB-backed file services with isolated iSCSI-based storage transport
- backup and offsite-protection capability that is operationally separate from live service delivery

### Site 2 environment evidence

The current documentation set includes direct environment evidence for Site 2:

- `config-rp-msp-gateway.et.lab-20260323222847.xml`, containing the OPNsense interface, NAT, alias, routing, and firewall configuration
- a platform inventory record identifying the Site 2 virtual machine set and service roles
- a PowerShell screenshot showing `C1SAN` at `172.30.65.186/29` with gateway `172.30.65.185`
- an Ubuntu screenshot showing `C2SAN` at `172.30.65.194/29` with gateway `172.30.65.193`
- a confirmed role mapping that identifies `S2-Ubuntu-Client` as the Company 1 client role for Site 2
- a confirmed namespace relationship showing that `c1.local` and `c2.local` operate within a shared forest
- a confirmed backup-design note stating that Veeam protects 10 machines to a Site 2 disk, retains file-share backup data, and copies that protected set offsite to Site 1

**Table 1. Design inputs and evidence basis for Site 2**

| Evidence or Input Type | What It Establishes | Site 2 Implication |
|---|---|---|
| Service requirements definition | Site 2 must support MSP operations, Company 1, Company 2, storage, backup, and secure connectivity | Site 2 must be documented as an integrated multi-service environment rather than as a single workload |
| Service-role mapping | Company 1, Company 2, and MSP responsibilities coexist inside one operating site | The technical narrative must explain how all three scopes interact |
| OPNsense configuration export | Real interface, NAT, alias, route, and firewall logic for Site 2 | Network and security sections can be evidence-based rather than inferred |
| Environment inventory record | Current system set and service-role distribution | The system inventory and role mapping can be presented without exposing hypervisor tooling |
| SAN addressing screenshots | Exact isolated-storage addressing and gateway structure | The storage architecture can be explained as a deliberate transport design |
| Namespace and client-role confirmations | Shared-forest interpretation and Company 1 client-role mapping | Cross-domain reachability and client behavior can be described accurately |
| Backup design summary | Protected workload count, file-share backup, and offsite-copy intent | The protection narrative can distinguish backup from synchronization and live service delivery |
| Live read-only validation | Actual observed behavior through approved administrative paths | The final conclusions can be supported by current operational evidence |

## 2.2 Evidence classes used in this report

This report intentionally separates evidence by source so that claims remain accurate and supportable.

**Table 2. Evidence classes used in this report**

| Evidence Class | What It Includes | How It Is Used |
|---|---|---|
| Internal design inputs | Service requirements, service-role mapping, confirmed role notes, and backup design summary | Defines intended scope, operating model, and service expectations |
| Site 2 environment evidence | OPNsense XML, platform inventory record, SAN screenshots, and confirmed environment notes | Provides architecture details that are valid even when not always directly queryable over CLI |
| Official vendor documentation | OPNsense, Samba, Ubuntu Server, Microsoft IIS, and Veeam documentation | Supports the rationale for network policy, identity, storage, web delivery, and protection design |
| Live read-only validation | March 23 and March 24, 2026 checks from the approved remote path, jump hosts, MSP bastion, and direct read-only SSH | Confirms current operational state without changing configuration |

## 2.3 Evidence-based method used for this report

This report was rebuilt using only:

- the available Site 2 design inputs and evidence records
- official documentation for the core technologies deployed in Site 2
- live read-only Site 2 validation performed on March 23 and March 24, 2026


## 2.4 Live validation method

The live validation approach followed a management-first bastion model. `MSPUbuntuJump` was treated as the primary bastion for repeatable CLI checks, especially for management-first validation into Company 1 and Company 2 paths. The Windows jump and local workstation were used only where they added practical reachability proof. Direct read-only SSH was used only against systems where it could validate state without configuration changes.

**Table 3. Approved live validation vantage points**

| Vantage Point | Why It Was Used |
|---|---|
| Approved remote management path | To verify controlled access to Site 2 jump services through the authorized operator path |
| `MSPUbuntuJump` | To perform low-risk, repeatable CLI checks from the MSP management plane into Company 1 and Company 2 paths |
| `Jump64` and local workstation | To add Windows-jump reachability proof and external operator context where needed |
| Direct read-only SSH to Linux systems | To confirm service state without changing configuration |
| Environment screenshots and XML | To fill architecture details that are accurate but not always directly queryable from CLI |
| Final GUI screenshot placeholders | To reserve correct locations for Veeam, OPNsense, and interactive proof |

# 3. Discussion

## 3.1 Environment Overview and Service Boundaries

Site 2 should be read as a complete service site, not as a loose grouping of servers. It combines MSP administrative control, Company 1 cross-site service delivery, Company 2 core tenant services, isolated storage transport, and backup or recovery functions inside one routed operating model. That whole-site view matters because the design only makes sense when those layers are evaluated together.

The live validation and the configuration evidence support that whole-site reading clearly. MSP control is represented by OPNsense, the jump systems, and Veeam. Company 1 is represented by its domain footprint, file-service adjacency, web delivery, client roles, and storage presence. Company 2 is represented by its identity, file, client, and web tiers. Together, those components define the real operating boundary of Site 2.

**Table 4. Observed Site 2 systems and service roles**

| System / Endpoint | Observed or Inferred Role |
|---|---|
| `172.30.65.177` | OPNsense MSP gateway and segmentation point |
| `172.30.65.178` | `Jump64` Windows jump on the MSP segment |
| `172.30.65.179` | `MSPUbuntuJump` Linux jump on the MSP segment |
| `172.30.65.180` | `S2Veeam` backup and recovery host |
| `172.30.65.2` | `C1DC1` Company 1 domain controller |
| `172.30.65.3` | `C1DC2` Company 1 domain controller |
| `172.30.65.4` | `C1FS` Company 1 file server |
| `172.30.65.11` | `C1WindowsClient` Company 1 Windows client |
| `172.30.65.36` | `S2-Ubuntu-Client`, identified in the environment evidence as the Company 1 client role |
| `172.30.65.162` | `C1WebServer` internal Company 1 web service on the Site 2 path |
| `172.30.65.66` | `C2IdM1` Company 2 identity, DNS, and DHCP |
| `172.30.65.67` | `C2IdM2` Company 2 identity, DNS, and DHCP |
| `172.30.65.68` | `C2FS` Company 2 file service and storage consumer |
| `172.30.65.70` | `C2LinuxClient` Company 2 Linux client |
| `172.30.65.170` | `C2WebServer` internal Company 2 web service |
| `172.30.65.186` | `C1SAN`, isolated storage segment for Company 1 file services |
| `172.30.65.194` | `C2SAN`, isolated storage segment for Company 2 file services |

**Figure 1. Site 2 topology and service-role alignment.**  
Description: Insert a topology or diagram view showing MSP jump paths, OPNsense, Company 1 services, Company 2 services, isolated SAN paths, `S2Veeam`, and the logical relationship between the major service groups.  

| Figure 1 Placeholder |
|---|
| Insert the Site 2 topology diagram here before final issue. |
|  |
|  |
|  |

## 3.2 Site 2 Logical Service Inventory and Platform Roles

The system inventory matters because it demonstrates planned platform structure rather than ad-hoc implementation. Site 2 was built as a separated service estate with clear roles for MSP control, Company 1 delivery, Company 2 operations, storage transport, and protection services. That role-mapping view is the foundation for understanding dependency, failure domain, and support ownership.

One useful example is the Company 1 Linux client role. Earlier environment records identify this role as `C1LinuxClient`, while the current IP and hostname evidence labels the same function as `S2-Ubuntu-Client`. This report uses `S2-Ubuntu-Client` in the narrative while retaining that alias for traceability.

**Table 5. Site 2 logical service inventory and role mapping**

| System Name | Role |
|---|---|
| `Jump64` | Windows jump on MSP segment |
| `RP-S2-Gateway` | Site 2 OPNsense gateway |
| `MSPUbuntuJump` | Linux bastion host |
| `S2Veeam` | Backup and offsite-copy platform |
| `C1SAN` | Company 1 isolated storage server |
| `C1WebServer` | Company 1 web service |
| `C1FS` | Company 1 file server |
| `C1DC1` | Company 1 domain controller |
| `C1DC2` | Company 1 domain controller |
| `C1WindowsClient` | Company 1 Windows client |
| `S2-Ubuntu-Client` | Company 1 Linux client role |
| `C2IdM1` | Company 2 identity, DNS, and DHCP |
| `C2IdM2` | Company 2 identity, DNS, and DHCP |
| `C2FS` | Company 2 file server |
| `C2LinuxClient` | Company 2 Linux client |
| `C2WebServer` | Company 2 web service |
| `C2SAN` | Company 2 isolated storage server |

This platform layout is useful because it demonstrates role separation, shows intentional infrastructure design, and makes the environment easier to understand for an operations handoff without exposing the underlying training or hosting platform.

**Figure 2. Site 2 logical service inventory and platform role map.**  
Description: Insert a sanitized logical inventory figure, role map, or architecture view that identifies the major Site 2 systems and their functions without exposing hypervisor-management tooling.  

| Figure 2 Placeholder |
|---|
| Insert the sanitized Site 2 logical service inventory or role map here before final issue. |
|  |
|  |
|  |

## 3.3 MSP Entry, Network Segmentation, Remote Access, and Security Rationale

### Interface and Segment Design

The network layer is the controlling discipline of Site 2. If routing, segmentation, and exposure control are not well designed, then identity, storage, web delivery, and backup quickly become difficult to defend. The OPNsense XML shows that Site 2 applies a disciplined bastion-first model rather than relying on broad edge exposure.

The OPNsense interface layout is structured as follows:

- `WAN` on `172.20.64.1/16`
- `MSP` on `172.30.65.177/29`
- `C1DMZ` on `172.30.65.161/29`
- `C1LAN` on `172.30.65.1/26`
- `C2DMZ` on `172.30.65.169/29`
- `C2LAN` on `172.30.65.65/26`
- `SITE1_OVPN` for the inter-site OpenVPN path

The WAN NAT rules expose only the jump systems:

- `33464 -> 172.30.65.178:3389` for the Windows jump
- `33564 -> 172.30.65.179:22` for `MSPUbuntuJump`

That limited edge exposure is significant. It means the environment is designed around entering through bastion hosts and then performing controlled internal administration, which is consistent with standard supportable network operations practice.

**Table 6. Site 2 network segments and gateways**

| Segment | OPNsense Interface | Address / Gateway | Purpose |
|---|---|---|---|
| WAN | `WAN` | `172.20.64.1/16` | Upstream or provider-facing interface |
| MSP management | `MSP` | `172.30.65.177/29` | Jump hosts, OPNsense, and Veeam access plane |
| Company 1 LAN | `C1LAN` | `172.30.65.1/26` | Company 1 routed internal network |
| Company 1 DMZ | `C1DMZ` | `172.30.65.161/29` | Company 1 web and DMZ publishing segment |
| Company 2 LAN | `C2LAN` | `172.30.65.65/26` | Company 2 routed internal network |
| Company 2 DMZ | `C2DMZ` | `172.30.65.169/29` | Company 2 web and DMZ publishing segment |
| Company 1 storage bridge | Not routed through OPNsense | `C1SAN 172.30.65.186/29`, gateway `172.30.65.185` | Isolated SAN path used by Company 1 storage |
| Company 2 storage bridge | Not routed through OPNsense | `C2SAN 172.30.65.194/29`, gateway `172.30.65.193` | Isolated SAN path used by Company 2 storage |
| Inter-site VPN | `SITE1_OVPN` | OpenVPN interface | Site 1 to Site 2 routing, backup, and cross-site access |

### Policy and Exposure Model

The firewall and alias design is equally instructive. The XML defines aliases for `C1_Nets`, `C2_Nets`, `C1_REMOTE`, `C2_REMOTE`, `ALL_WEBS`, `ALL_DNS`, `C1_DCs`, `C2_DCs`, `S2_VEEAM`, `SITE1_VEEAM`, and `VEEAM_COPY_PORTS`. That alias-driven style makes the policy easier to maintain and easier to explain in a handover report.

**Table 7. OPNsense exposure, routing, and firewall policy summary**

| Area | Evidence from XML | Operational Meaning |
|---|---|---|
| Edge exposure | WAN NAT exposes only `Jump64` RDP and `MSPUbuntuJump` SSH | Reduces attack surface and matches bastion-host guidance |
| Inter-site tunnel | OpenVPN interface plus Site 1 route for `192.168.64.20/32` | Supports cross-site service reachability and backup copy flow |
| Company 1 policy | `C1LAN` allowed to `C1_GLOBAL`, `ALL_WEBS`, and `ALL_DNS`, with a block to `C2_GLOBAL` | Company 1 can reach shared services without flat access to Company 2 networks |
| Company 2 policy | `C2LAN` allowed to `C2_GLOBAL`, `ALL_WEBS`, and `ALL_DNS`, with a block to `C1_GLOBAL` | Company 2 can reach shared services without flat access to Company 1 networks |
| Cross-site web rule | `C1_REMOTE -> 172.30.65.170/32` on HTTP/HTTPS and `C2_REMOTE -> 172.30.65.162/32` on HTTP/HTTPS | Each site can reach the other site's web service using the expected hostname path |
| DNS reachability | `ALL_DNS` combines `C1_DCs` and `C2_DCs` | Supports shared name resolution across the service environment |
| Backup copy | `SITE1_VEEAM -> S2_VEEAM` on `VEEAM_COPY_PORTS` | Supports offsite backup transfer between the two sites |

### Operational Interpretation

The live validation matched this design well:

- Approved remote management access to both jump services was successful
- OPNsense management returned `HTTP 403`, which is consistent with a present but non-anonymous management plane
- OPNsense TCP `53` was reachable from `MSPUbuntuJump`

**Figure 3. OPNsense interfaces, aliases, and limited edge exposure.**  
Description: Insert a screenshot or annotated export showing OPNsense interfaces, key aliases, and the two published jump-host NAT rules.  

| Figure 3 Placeholder |
|---|
| Insert the OPNsense interface, alias, and NAT evidence here before final issue. |
|  |
|  |
|  |

**Figure 4. OPNsense OpenVPN and inter-site rule mapping.**  
Description: Insert a screenshot showing the OpenVPN rule set, the cross-site web rules, or the Veeam copy rule that ties Site 1 and Site 2 together.  

| Figure 4 Placeholder |
|---|
| Insert the OPNsense OpenVPN and cross-site rule evidence here before final issue. |
|  |
|  |
|  |

## 3.4 Company 1 Service Integration Within Site 2

Company 1 is not an incidental reference inside Site 2. It has an identifiable domain footprint, file-service adjacency, web-service delivery path, client presence, and isolated storage relationship within the broader Site 2 design. If those components are not described clearly, the resulting report understates what Site 2 actually does.

### Company 1 Service Baseline

The available evidence identifies the following Company 1 components as part of the Site 2 operating picture:

- `C1DC1` at `172.30.65.2`
- `C1DC2` at `172.30.65.3`
- `C1FS` at `172.30.65.4`
- `C1WindowsClient` at `172.30.65.11`
- `S2-Ubuntu-Client` at `172.30.65.36`, aligned to the active Company 1 Linux client role
- `C1WebServer` at `172.30.65.162`
- `C1SAN` at `172.30.65.186/29`, gateway `172.30.65.185`

Taken together, those components show that Company 1 participates in Site 2 through identity adjacency, file-service adjacency, client-side validation, internal web delivery, and isolated storage architecture.

### Observed Cross-Site Evidence

From the source documents:

- the service-role mapping assigns Company 1 and Company 2 responsibilities across the same final operating site
- the design inputs define Site 2 as an MSP-operated environment rather than a single-tenant segment
- the documentation objective requires cross-site behavior to be documented and defended

From the live validation:

- Company 1 records existed on both Company 2 identity nodes
- `MSPUbuntuJump` reached `C1DC1` and `C1DC2` on `53`, `88`, `389`, `445`, `3389`, and `5985`
- `MSPUbuntuJump` reached `C1FS` on `445` and `3389`, and `S2-Ubuntu-Client` on `22`
- `MSPUbuntuJump` reached `C1WebServer` on `443`, `3389`, and `5985`
- `c1-webserver.c1.local` was resolved through `C2IdM1` and returned `HTTP 200`, while raw-IP access returned `HTTP 404`
- `S2-Ubuntu-Client` successfully resolved and reached both required web hostnames

**Table 8. Company 1 service baseline and integration within Site 2**

| Company 1 Component | Role in the Site 2 Narrative | Current Evidence | Operational Significance |
|---|---|---|---|
| `C1DC1` and `C1DC2` | Company 1 domain presence and cross-site administrative continuity | Reachable from `MSPUbuntuJump` on `53`, `88`, `389`, `445`, `3389`, and `5985`; present in addressing and DNS context | Shows that Company 1 identity infrastructure remains part of the Site 2 operating picture |
| `C1FS` | Company 1 file-service presence across the inter-site path | Reachable from `MSPUbuntuJump` on `445` and `3389` | Confirms that Company 1 file operations remain visible from the Site 2 management side |
| `C1WebServer` | Company 1 internal web service delivered through Site 2 web paths | `c1-webserver.c1.local` returned `200`; raw IP returned `404`; `443`, `3389`, and `5985` reachable from `MSPUbuntuJump` | Confirms hostname-based Company 1 service publication rather than flat IP exposure |
| `C1WindowsClient` | Company 1 Windows endpoint represented in the environment inventory | Present in the environment inventory evidence | Shows that Company 1 user-side estate is part of the documented platform baseline |
| `S2-Ubuntu-Client` | Active Company 1 Linux client role inside Site 2 validation | Resolved both required web hostnames and showed Company 1 domain context | Provides real client-side proof that Company 1 can consume the intended Site 2 services |
| `C1SAN` | Isolated Company 1 storage path | Addressing and gateway confirmed by environment evidence; not exposed to the MSP management plane as a general-purpose routed service | Shows that Company 1 storage is engineered as a distinct transport domain rather than mixed into tenant LAN segments |
| `c1.local` shared-forest relationship | Cross-domain naming and namespace visibility | Design evidence plus Company 1 DNS visibility on Company 2 identity nodes | Explains why both required hostnames can be consumed consistently across the two company contexts |

### Architectural Significance

This section shows that Company 1 is part of the Site 2 service model, not external to it. Site 2 carries Company 1 domain visibility, Company 1 web delivery, Company 1 client validation, Company 1 administrative reachability, and Company 1 storage adjacency. Without that Company 1 layer, the documented behavior of Site 2 would be incomplete.

**Figure 5. Company 1 service integration from the Site 2 management path.**  
Description: Insert a screenshot showing Company 1 reachability from the Site 2 management path, such as cross-site port checks, Company 1 DNS records on Company 2 identity services, or the Company 1 web hostname responding from Site 2.  

| Figure 5 Placeholder |
|---|
| Insert the Company 1 cross-site evidence here before final issue. |
|  |
|  |
|  |

## 3.5 Company 2 Identity, Shared Forest Context, DNS, and DHCP

### Identity Service Health

The identity layer is one of the strongest and most operationally important parts of Site 2. Read-only checks on `C2IdM1` and `C2IdM2` showed:

- `samba-ad-dc` active on both nodes
- `isc-dhcp-server` active on both nodes
- valid DNS records for both Company 1 and Company 2 web services on both nodes

These checks directly satisfy multiple project requirements. Company 2 requires directory services, DNS, and fault-tolerant DHCP. The live environment demonstrates that those services were not only built, but remain queryable and usable through the approved bastion path.

### Namespace and Forest Design

Available environment evidence indicates that `c1.local` and `c2.local` share a forest. That forest relationship was not reconfigured during testing, so it is treated as environment design evidence. The live results are consistent with that design because both Company 1 and Company 2 web namespaces are visible on Company 2 identity servers and are reachable from both clients.

**Table 9. Company 2 identity, DNS, and DHCP summary**

| Validation Item | `C2IdM1` | `C2IdM2` |
|---|---|---|
| Samba AD service state | Active | Active |
| DHCP service state | Active | Active |
| `c1-webserver.c1.local` A records | `172.30.64.162`, `172.30.65.162` | `172.30.64.162`, `172.30.65.162` |
| `c2-webserver.c2.local` A records | `172.30.64.170`, `172.30.65.170` | `172.30.64.170`, `172.30.65.170` |
| Cross-domain namespace significance | Company 1 name present | Company 1 name present |

The presence of Company 1 records on the Company 2 identity servers is especially important. It shows that Site 2 was designed to support cross-site internal web delivery rather than keeping each company's namespace invisible from the other side.

**Figure 6. `C2IdM1` Active Directory, DNS, and DHCP proof.**  
Description: Insert a screenshot from `C2IdM1` showing active Samba AD, active DHCP, and DNS query output for the two web hostnames.  

| Figure 6 Placeholder |
|---|
| Insert the `C2IdM1` AD, DNS, and DHCP evidence here before final issue. |
|  |
|  |
|  |

**Figure 7. `C2IdM2` Active Directory, DNS, and DHCP proof.**  
Description: Insert a screenshot from `C2IdM2` showing active Samba AD, active DHCP, and DNS query output for the two web hostnames.  

| Figure 7 Placeholder |
|---|
| Insert the `C2IdM2` AD, DNS, and DHCP evidence here before final issue. |
|  |
|  |
|  |

**Figure 8. Shared-forest and cross-domain DNS proof.**  
Description: Insert a screenshot that best demonstrates the shared-forest or cross-domain namespace design, such as dual web records on Company 2 identity services or a domain-management view that shows both domains.  

| Figure 8 Placeholder |
|---|
| Insert the shared-forest or cross-domain namespace evidence here before final issue. |
|  |
|  |
|  |

## 3.6 Storage, File Services, and Isolated SAN Design

The storage layer is one of the clearest indicators that Site 2 was engineered rather than improvised. The environment uses isolated SAN connectivity, mounted block storage, structured share presentation, and synchronization behavior in a way that aligns cleanly with the project's storage objectives.

### File-Service State

Read-only inspection of `C2FS` showed:

- `smbd` active
- `/mnt/c2_public` mounted from `/dev/sdb`
- an active iSCSI session to `172.30.65.194:3260` using target `iqn.2024-03.org.clearroots:c2san`
- `C2_Public` and `C2_Private` share definitions in Samba
- successful synchronization from Site 1 to Site 2 in the current log

### SAN Isolation Model

The SAN evidence adds an architectural layer that CLI testing on `C2FS` alone would not fully explain. Two isolated SAN servers are present in the design:

- `C1SAN` at `172.30.65.186/29`, gateway `172.30.65.185`
- `C2SAN` at `172.30.65.194/29`, gateway `172.30.65.193`

Those SAN systems are isolated and bridged only to the corresponding file servers. That is a strong design choice because it keeps storage traffic off the tenant LAN and DMZ segments while still satisfying the iSCSI requirement in a supportable way. The March 24 read-only checks from `MSPUbuntuJump` did not expose the SAN endpoints as general-purpose management services, which is consistent with the intended isolated-storage model rather than a flat routed design.

**Table 10. Storage and isolated SAN summary**

| Item | Evidence |
|---|---|
| `C2FS` mounted data path | `/mnt/c2_public` |
| `C2FS` mounted device | `/dev/sdb` |
| `C2FS` transport | `iscsi` |
| Active Company 2 iSCSI session | `172.30.65.194:3260`, target `iqn.2024-03.org.clearroots:c2san` |
| Company 2 public share | `[C2_Public] -> /mnt/c2_public/Public` |
| Company 2 private share | `[C2_Private] -> /mnt/c2_public/Private/%U` |
| Latest Company 2 sync result | `Sync completed successfully` |
| Company 1 SAN evidence | `C1SAN 172.30.65.186/29`, gateway `172.30.65.185`, environment screenshot evidence |
| Company 2 SAN evidence | `C2SAN 172.30.65.194/29`, gateway `172.30.65.193`, environment screenshot evidence |
| Architectural interpretation | Two isolated storage bridges support the two file-service domains without flattening storage into routed user segments |

This is one of the strongest sections of the Site 2 design because the architecture, the supporting evidence, and the live validation all reinforce the same conclusion.

**Figure 9. `C2FS` iSCSI-backed storage and mounted volume proof.**  
Description: Insert a screenshot showing the active iSCSI session and the mounted `/mnt/c2_public` storage on `C2FS`.  

| Figure 9 Placeholder |
|---|
| Insert the `C2FS` iSCSI and mount evidence here before final issue. |
|  |
|  |
|  |

**Figure 10. `C2FS` SMB share definitions and synchronization proof.**  
Description: Insert a screenshot showing the `C2_Public` and `C2_Private` share definitions and the successful synchronization log entries.  

| Figure 10 Placeholder |
|---|
| Insert the `C2FS` share-definition and sync-log evidence here before final issue. |
|  |
|  |
|  |

**Figure 11. `C1SAN` isolated storage interface proof.**  
Description: Insert the PowerShell screenshot that shows the `C1SAN` IP configuration and demonstrates the isolated Company 1 storage segment.  

| Figure 11 Placeholder |
|---|
| Insert the `C1SAN` interface evidence here before final issue. |
|  |
|  |
|  |

**Figure 12. `C2SAN` isolated storage interface proof.**  
Description: Insert the Ubuntu screenshot that shows the `C2SAN` IP configuration and demonstrates the isolated Company 2 storage segment.  

| Figure 12 Placeholder |
|---|
| Insert the `C2SAN` interface evidence here before final issue. |
|  |
|  |
|  |

## 3.7 Client Access, Identity Validation, and Dual-Hostname Web Delivery

Client-side validation is essential because a service environment is only credible when directory, web, and file outcomes are visible from real consumer systems. For Site 2, the client perspective proves that the design is not only correctly configured on servers, but also usable from both company contexts.

### Client Validation Perspectives

Two different client perspectives were available:

- `S2-Ubuntu-Client`, identified in the environment evidence as the Company 1 client role
- `C2LinuxClient`, the Company 2 Linux client

Both clients were able to resolve and reach both internal web hostnames. That result matters because it proves the same named services can be consumed consistently from both company perspectives:

- `https://c1-webserver.c1.local`
- `https://c2-webserver.c2.local`

`S2-Ubuntu-Client` additionally showed Company 1 realm membership and identified itself under `c1.local`, while `C2LinuxClient` showed valid `C2.LOCAL` realm membership and valid domain-user lookups for `employee1@c2.local` and `employee2@c2.local`.

**Table 11. Client-side validation summary**

| Validation Item | `S2-Ubuntu-Client` | `C2LinuxClient` |
|---|---|---|
| Host role | Company 1 client role | Company 2 client role |
| Domain context | `c1.local` / `C1.LOCAL` | `c2.local` / `C2.LOCAL` |
| Domain-user proof | `administrator@c1.local` active session | `employee1@c2.local` and `employee2@c2.local` resolved by `getent passwd` |
| `c1-webserver.c1.local` | Resolved and returned `HTTP 200` | Resolved and returned `HTTP 200` |
| `c2-webserver.c2.local` | Resolved and returned `HTTP 200` | Resolved and returned `HTTP 200` |
| Operational significance | Proves Company 1 can consume both tenant web names | Proves Company 2 can consume both tenant web names |

### Hostname-Based Web Publishing Behavior

The bastion-side curl tests also showed a hardened web pattern:

- `c1-webserver.c1.local` returned `HTTP 200`
- `https://172.30.65.162` returned `HTTP 404`
- `c2-webserver.c2.local` returned `HTTP 200`
- `https://172.30.65.170` returned `HTTP 404`

That hostname-first behavior shows that the services are published intentionally, not exposed as loose IP-based pages.

**Table 12. Internal web delivery summary**

| Validation | Observed Result |
|---|---|
| `https://c1-webserver.c1.local` pinned to `172.30.65.162` | `HTTP/2 200` |
| `https://172.30.65.162` | `HTTP/2 404` |
| `https://c2-webserver.c2.local` pinned to `172.30.65.170` | `HTTP/1.1 200 OK` |
| `https://172.30.65.170` | `HTTP/1.1 404 Not Found` |
| Company 1 client to both hostnames | Success |
| Company 2 client to both hostnames | Success |

**Figure 13. `S2-Ubuntu-Client` Company 1 client dual-web proof.**  
Description: Insert a screenshot from `S2-Ubuntu-Client` showing `c1.local` membership plus successful access to both `c1-webserver.c1.local` and `c2-webserver.c2.local`.  

| Figure 13 Placeholder |
|---|
| Insert the `S2-Ubuntu-Client` dual-web evidence here before final issue. |
|  |
|  |
|  |

**Figure 14. `C2LinuxClient` domain identity and dual-web proof.**  
Description: Insert a screenshot from `C2LinuxClient` showing `realm list`, domain-user lookup, and successful access to both required web hostnames.  

| Figure 14 Placeholder |
|---|
| Insert the `C2LinuxClient` identity and dual-web evidence here before final issue. |
|  |
|  |
|  |

## 3.8 Backup, Recovery, and Offsite Protection

### Backup Design Basis

Backup and recovery must be documented at the same level of care as identity or networking because they define whether the environment is supportable after failure. In Site 2, the available design evidence and the live validation complement each other well.

According to the available backup design evidence:

- Veeam backs up 10 machines
- those backups are written to a Site 2 dedicated disk on the Veeam server
- a file-share backup also exists on the Veeam server
- the environment also sends offsite backup data to Site 1

### Inter-Site Backup Path

The OPNsense XML supports that overall story by defining:

- `S2_VEEAM = 172.30.65.180`
- `SITE1_VEEAM = 192.168.64.20`
- `VEEAM_COPY_PORTS = 135, 445, 6160, 6162, 2500:3000, 10005, 10006`
- an inter-site OpenVPN rule allowing `SITE1_VEEAM -> S2_VEEAM` on `VEEAM_COPY_PORTS`
- a static route for `192.168.64.20/32` via the Site 1 OpenVPN gateway

### Current Operational Proof

The live validation corroborated the management and control plane by confirming that `S2Veeam` was reachable from the approved admin path on:

- TCP `445`
- TCP `3389`
- TCP `9392`
- TCP `5985`
- TCP `10005`
- TCP `10006`

**Table 13. Backup and offsite-protection summary**

| Backup Area | Evidence Basis | Current Interpretation |
|---|---|---|
| `S2Veeam` host identity | OPNsense alias plus live port checks | Backup server exists at `172.30.65.180` and is reachable |
| Veeam control paths | Live read-only validation | Management and agent ports are healthy from the bastion path |
| Site 2 backup repository | Environment design note | Site 2 has a dedicated Veeam backup disk |
| File-share backup | Environment design note | File-share backup exists on the Veeam server |
| Offsite copy to Site 1 | Environment design note plus OPNsense XML route and rule | Offsite backup design is part of the deployed architecture |
| Protected workload count | Environment design note | 10 machines are included in Veeam protection |

This is enough to document a strong backup architecture, but not enough to overstate GUI evidence such as exact job names or repository labels. Those should be closed with one Veeam console screenshot in the final package.

**Figure 15. `S2Veeam` repository, backup jobs, and offsite-copy proof.**  
Description: Insert a screenshot from the Veeam console showing the protected machines, the Site 2 repository or disk, the file-share backup entry, and the offsite-copy relationship to Site 1.  

| Figure 15 Placeholder |
|---|
| Insert the Veeam console or repository evidence here before final issue. |
|  |
|  |
|  |

## 3.9 Requirement-to-Implementation Traceability

### Requirement Coverage

Requirement traceability is what separates a persuasive technical report from a simple build summary. In Site 2, each major requirement needs to be tied to a concrete implementation choice and to live or documentary evidence that proves it was delivered.

**Table 14. Requirement-to-implementation traceability matrix**

| Requirement Area | Site 2 Implementation | Current Evidence | Status | Final Submission Note |
|---|---|---|---|---|
| Secure remote access | `Jump64`, `MSPUbuntuJump`, approved remote operator access, and OPNsense WAN NAT only for jump systems | Bastion reachability checks plus XML NAT review | Proven | Edge exposure remains limited to jump services only |
| Segmented multi-network design | OPNsense interfaces for `MSP`, `C1LAN`, `C1DMZ`, `C2LAN`, `C2DMZ`, plus isolated SAN bridges | XML interface and alias review plus live path testing | Proven | Support with one OPNsense GUI screenshot |
| Site-to-site connectivity | `SITE1_OVPN`, `C1_REMOTE`, `C2_REMOTE`, Veeam route, and cross-site rules | XML route/rule review plus Company 1 reachability from Site 2 | Proven | Use rule screenshots if a reviewer asks how traffic is controlled |
| Company 2 identity, DNS, and DHCP | `C2IdM1` and `C2IdM2` running Samba AD, DNS, and DHCP | `systemctl` checks plus DNS query results | Proven | Pair with screenshots from both nodes |
| Company 2 internal web service | `C2WebServer` and dual A-record publishing for `c2-webserver.c2.local` | Bastion and client curl checks returning `200` by hostname | Proven | Show hostname, not raw IP |
| Company 1 service stack inside Site 2 | `C1DC1`, `C1DC2`, `C1FS`, `C1WebServer`, `C1WindowsClient`, `S2-Ubuntu-Client`, `C1SAN`, and shared namespace visibility | Inventory evidence, cross-site checks, client validation, DNS visibility, and SAN evidence | Proven | Demonstrates that Company 1 is a first-class part of the Site 2 operating model |
| File services and share isolation | `C2FS` with `C2_Public` and `C2_Private` share definitions | `testparm -s`, sync log, and mount evidence | Proven | Add one interactive share screenshot for maximum polish |
| iSCSI design | `C2SAN` target, `C2FS` initiator, isolated storage network, mirrored storage logic | `iscsiadm -m session`, `findmnt`, SAN screenshots | Proven | Distinguish storage transport from user LAN traffic in the technical explanation |
| Client-side service consumption | `S2-Ubuntu-Client` and `C2LinuxClient` resolving and reaching both required hostnames | Direct client-side web and identity checks | Proven | This is one of the strongest cross-site validation results |
| Backup, file-share backup, and offsite copy | `S2Veeam`, Site 2 repository disk, file-share backup, and Site 1 offsite-copy design | Live port checks, XML Veeam route or rules, and available backup design detail | Strongly supported | Needs one Veeam GUI screenshot for full closure |
| Linux-client SSH accessibility requirement | Linux client reachable through the approved management path | Internal SSH/admin path proven from Site 2 | Partially evidenced | If a reviewer requests explicit external-edge proof, provide a current live test or screenshot from that access path |

This matrix is valuable because it shows that the environment was not only built, but also consciously audited against its stated service requirements.

## 3.10 Service Dependency, Failure Domains, and Access Model

### Dependency View

A senior-level handover must make dependencies obvious. Site 2 contains several distinct service planes, and each one fails differently. Mapping those dependencies makes troubleshooting faster and reduces the risk of treating a symptom as though it were the root cause.

**Table 15. Service dependency and failure-domain view**

| Service Plane | Primary Components | Downstream Dependencies | Main Failure Symptom | Fastest Health Check |
|---|---|---|---|---|
| Entry and management | `Jump64`, `MSPUbuntuJump`, OPNsense MSP interface | Every other administrative workflow | Team cannot reach consoles or internal hosts quickly | Approved remote-access verification and bastion reachability checks |
| Identity and naming | `C2IdM1`, `C2IdM2`, Samba AD, DNS, DHCP | Client logon, hostname resolution, share access, cross-domain name visibility | User lookup fails or hostnames do not resolve | `systemctl`, `realm list`, and `samba-tool dns query` |
| Web delivery | `C1WebServer`, `C2WebServer`, DNS records, cross-site OPNsense rules | Demo visibility for both companies | Hostname fails or wrong content is served | `curl -k -I` by hostname and raw IP |
| File and storage | `C2FS`, `C2SAN`, iSCSI session, share configuration | Public/private shares and sync visibility | Shares disappear or `/mnt/c2_public` is missing | `findmnt`, `iscsiadm -m session`, `testparm -s` |
| Recovery and backup | `S2Veeam`, Site 1 route, OpenVPN rule path | VM recovery, file-share backup, offsite resilience | Backup copy or restore confidence drops | Port checks plus Veeam console screenshot |
| Company 1 service stack | `C1DC1`, `C1DC2`, `C1FS`, `C1WebServer`, `C1WindowsClient`, `S2-Ubuntu-Client`, `C1SAN`, and Site 1 remote aliases | Cross-site reachability, client behavior, and environment inventory evidence | Company 1 appears absent from the Site 2 model | `nc` checks, hostname curl, inventory review, and client-side validation |

**Table 16. Authentication and authorization model**

| Actor / Role | Identity Source | Primary Access Path | Scope of Access | Control Rationale |
|---|---|---|---|---|
| MSP administrators | MSP and local administrative paths | Jump hosts, OPNsense, Veeam, and approved internal admin path | Full support and service operations | Centralizes privileged access through bastion systems |
| Company 1 administrators | `c1.local` domain context | Company 1 systems and cross-site validation path | Company 1 infrastructure and Company 1 web proof | Preserves tenant scoping while allowing cross-site service visibility |
| Company 2 administrators | `c2.local` domain context | `C2IdM1`, `C2IdM2`, `C2FS`, `C2WebServer`, `C2LinuxClient` | Company 2 service administration | Keeps tenant administration aligned to Company 2 services |
| Company 2 end users | `c2.local` user accounts | `C2LinuxClient` and SMB access | User authentication and share consumption | Demonstrates that directory services produce real client outcomes |
| File-share users | `c2_file_users` and `%U` mapping | `C2_Public` and `C2_Private` shares | Group-based public access and per-user private isolation | Reinforces least privilege and private-home-folder behavior |
| Web consumers | DNS and HTTPS hostname path | `c1-webserver.c1.local` and `c2-webserver.c2.local` | Read-only web consumption | Hostname-based delivery prevents accidental raw-IP exposure |
| Backup operators | Veeam administrative path | `S2Veeam` console and offsite-copy workflows | Backup monitoring, repository review, and recovery operations | Recovery should be manageable without logging into every tenant server |

### Access Model Interpretation

This view improves the handover quality because it explains not only where services live, but which identities are meant to operate them.

## 3.11 Storage, Backup, and Recovery Flow

### Data-Protection Layers

The data-protection model in Site 2 should be read as three different but related mechanisms: synchronized file content, SAN-backed storage delivery, and Veeam-based backup with offsite copy. Keeping those flows distinct is important because each solves a different operational problem and each requires different evidence.

**Table 17. Storage, backup, and recovery data-flow summary**

| Data Set or Flow | Source | Intermediate Path | Destination | Protection Method | Recovery Interpretation |
|---|---|---|---|---|---|
| Company 2 public share data | Site 1 synchronized content and local file operations | Sync workflow and mounted iSCSI-backed volume | `/mnt/c2_public/Public` | Sync plus Veeam protection | Useful for operational data continuity and backup-backed restore |
| Company 2 private share data | Site 1 synchronized private content and local per-user changes | Sync workflow and `%U` private folder structure | `/mnt/c2_public/Private/%U` | Sync plus access control plus backup | Preserves per-user isolation during restore scenarios |
| Company 2 block storage | `C2SAN` at `172.30.65.194/29` | iSCSI session to `C2FS` | `/dev/sdb` mounted at `/mnt/c2_public` | Isolated SAN transport | Base dependency for all file-service presentation |
| Company 1 block storage | `C1SAN` at `172.30.65.186/29` | Isolated bridge to Company 1 file services | Company 1 storage path | Isolated SAN transport | Keeps Company 1 storage domain separate from Company 2 |
| VM and system backups | 10 protected machines per available backup design | Veeam job processing on `S2Veeam` | Site 2 dedicated Veeam disk | Backup repository | Supports recovery beyond what sync alone can provide |
| File-share backup data | File services included in backup plan | Veeam processing on `S2Veeam` | Site 2 Veeam backup storage | File-share backup workflow | Distinct from live share synchronization |
| Offsite protection | Site 2 backup data | OpenVPN path, static route, and `VEEAM_COPY_PORTS` | Site 1 backup destination | Offsite copy | Provides resilience against a Site 2-local loss event |

### Sync Versus Backup

The key operational lesson is that synchronization is not the same thing as backup. The sync job helps keep file content aligned between sites, while Veeam provides recovery-oriented protection and offsite resilience. Both need to be present in the final explanation.

## 3.12 Maintenance and Daily Duties

### Routine Operational Checks

Operations guidance is part of technical completeness, not an optional appendix. A supportable Site 2 report has to identify which routine checks actually preserve service continuity and why those checks matter.

**Table 18. Operational maintenance checks**

| Daily or Routine Check | Why It Matters |
|---|---|
| Confirm access to `Jump64` and `MSPUbuntuJump` | Without the bastion path, many healthy services become slow to prove |
| Review OPNsense interface and tunnel status | Routing and inter-site access are central to the Site 2 story |
| Confirm `samba-ad-dc` and `isc-dhcp-server` on `C2IdM1` and `C2IdM2` | Identity and DHCP are foundational for Company 2 |
| Reconfirm Company 1 and Company 2 DNS records on Company 2 identity nodes | Cross-domain name visibility is central to the Site 2 service narrative |
| Confirm both clients can still resolve both web hostnames | This is one of the most visible cross-site service behaviors |
| Confirm `C2FS` iSCSI session and mount remain present | Storage issues can break both file access and service validation |
| Review `c2_site1_sync.log` | Cross-site synchronization is part of the Site 2 narrative |
| Confirm `S2Veeam` control ports and last repository/offsite state | Backup readiness depends on stable control and copy paths |
| Confirm Company 1 and Company 2 hostnames still return `200`, while raw IPs return `404` | Reinforces hostname-based publishing and catches unexpected web-path regressions |
| Maintain an up-to-date evidence set for OPNsense, storage, and Veeam | Keeps the handover package ready for audit and operational review |

## 3.13 Troubleshooting and Fast Triage Guide

### Fast Triage Principles

A professional technical report should not stop at describing the happy path. It should also identify the first systems and checks that matter when a fault appears. The following triage guide is intentionally optimized for fast operational diagnosis.

**Table 19. Troubleshooting and fast triage guide**

| Symptom | First System to Inspect | Fastest Command or Evidence | Healthy Expectation | Likely Fault Domain if Unhealthy |
|---|---|---|---|---|
| Cannot enter Site 2 | Approved remote-access path and jump hosts | Jump-service reachability checks | Jump systems are reachable | Authorized remote-access path, edge publication, or jump-host issue |
| `c1-webserver.c1.local` or `c2-webserver.c2.local` does not resolve | `C2IdM1` or `C2IdM2` | `samba-tool dns query` or client `nslookup` | Dual A records are returned | DNS service, record replication, or client resolver issue |
| Domain user lookup fails on `C2LinuxClient` | `C2LinuxClient` | `realm list` and `getent passwd` | Realm visible and user entries returned | SSSD, domain join, or identity-service issue |
| Shares appear unavailable | `C2FS` | `systemctl is-active smbd`, `findmnt`, `iscsiadm -m session`, `testparm -s` | SMB active, mount present, iSCSI session visible | SMB service, mount loss, or SAN transport issue |
| Web page returns `404` by hostname | Client, jump host, and DNS path | `curl -k -I` by hostname and by raw IP | Hostname returns `200`; raw IP returns `404` | Wrong hostname, DNS mismatch, or web virtual-host issue |
| Company 1 no longer appears reachable from Site 2 | `MSPUbuntuJump` and OPNsense rules | `nc` checks plus Company 1 hostname curl | Ports and Company 1 web path succeed | OpenVPN/rule path or remote Company 1 service issue |
| Backup or offsite-copy confidence is low | `S2Veeam` and OPNsense | Port checks, static-route review, and Veeam GUI | Veeam reachable and copy path defined | Veeam service, repository, or inter-site route/rule issue |

## 3.14 Limitations, Risks, and Remaining Evidence Gaps

This source-based report is intentionally honest about what has and has not been fully proven through current read-only testing.

**Table 20. Current limitations and evidence gaps**

| Item | Current State |
|---|---|
| Veeam console inventory | Architecture and control-path evidence are strong, but a final GUI screenshot is still recommended |
| Interactive share-access proof | `C2LinuxClient` identity proof is strong, but an interactive screenshot of share access would further strengthen the test package |
| Shared-forest administrative screenshot | Forest relationship is strongly supported by naming behavior and DNS visibility, but a GUI or domain-management screenshot would make it even stronger |
| OPNsense GUI capture | XML evidence is strong, but one GUI screenshot will communicate the design faster to a reviewer |
| Linux-client external-edge proof | Internal and admin-path evidence are strong, but a specific external-edge SSH proof was not separately re-run in this pass |

These are acceptable limitations for a read-only validation pass. They do not weaken the strong evidence already collected for segmentation, identity, DNS, storage, client behavior, internal web delivery, backup-path design, and requirement traceability.

## 3.15 Integrated Design Assurance View

A complete Site 2 technical report should be able to satisfy three different senior reviews at the same time. A project lead needs to see that scope, deliverables, and service outcomes align. A network lead needs to see that segmentation, exposure control, and cross-site traffic behavior are deliberate and supportable. A systems-administration lead needs to see that identity, storage, clients, backup, and recovery paths are operationally coherent. Site 2 is strongest when it is defended through all three perspectives together rather than through isolated server descriptions.

### Project Delivery Perspective

From a project-delivery standpoint, Site 2 is successful because it consolidates multiple required outcomes into one managed site model: controlled administrative access, tenant-aware service delivery for Company 1 and Company 2, isolated storage presentation, internal hostname-based web publishing, and backup with offsite protection. The value of the design is not just that these parts exist, but that they support one another in a way that is visible, testable, and explainable. That is why this report treats Site 2 as a complete operating environment rather than as a collection of disconnected machines.

### Network Engineering Perspective

From a network-engineering standpoint, the design shows clear intent. OPNsense separates MSP, Company 1, Company 2, DMZ, SAN-adjacent, and inter-site traffic concerns instead of flattening them into a single trust boundary. Only the jump systems are published at the edge, cross-site traffic is rule-driven, DNS visibility is deliberate, and internal web delivery is tied to hostname-based behavior instead of raw-IP exposure. The resulting network story is defensible because routing, NAT, alias design, and rule scope all serve recognizable operational goals: controlled entry, bounded tenant communication, and recoverable service paths.

### Systems Administration Perspective

From a systems-administration standpoint, Site 2 also behaves as a coherent service stack. Identity services on `C2IdM1` and `C2IdM2` support name resolution, DHCP, and cross-domain awareness. `C2FS` consumes isolated SAN-backed storage through iSCSI and presents structured public or private shares. `S2-Ubuntu-Client` and `C2LinuxClient` confirm that the expected hostname and identity experience is visible from both company perspectives. `S2Veeam` adds a separate protection layer beyond synchronization, which is essential because storage presentation, synchronization, and backup are related but not interchangeable functions.

**Table 21. Integrated design assurance summary**

| Senior Perspective | Primary Question | Site 2 Position | Supporting Evidence | Residual Completion Item |
|---|---|---|---|---|
| Project management and delivery | Does Site 2 satisfy the intended scope as one complete service environment | Yes; management, tenant service delivery, storage, and protection workflows are all represented and traceable | Design inputs, inventory evidence, validation summaries, and requirement traceability | Final screenshots to complete presentation polish |
| Network engineering | Is the network design segmented, supportable, and exposure-controlled | Yes; OPNsense shows bounded entry, inter-site routing, DNS reachability, and service-specific policy intent | OPNsense XML, NAT mappings, interface definitions, aliases, route logic, and live reachability tests | One GUI firewall screenshot for visual confirmation |
| Systems administration | Are identity, client access, file services, and backup paths operationally coherent | Yes; active services, client outcomes, storage sessions, share definitions, and backup control paths all align with the intended design | Samba AD and DHCP state, DNS records, client validation, `C2FS` storage checks, and `S2Veeam` port validation | Final Veeam console and interactive share screenshots |

### Overall Assurance Position

Taken together, these perspectives support the same conclusion: Site 2 is not best explained by focusing on one tenant or one subsystem at a time. It is best explained as an integrated service platform in which management access, security boundaries, identity, storage, application delivery, and recovery planning reinforce one another. That is the level at which the final documentation should defend the environment, and it is the level this revision is intended to reach.

# 4. Conclusion

When the design inputs, environment evidence, official technical references, and live validation are read together, Site 2 is best understood as a complete operating environment supporting Company 1, Company 2, and MSP services together.

Site 2 currently shows strong evidence for:

- controlled entry through bastion hosts and tightly limited edge exposure
- deliberate OPNsense segmentation across MSP, Company 1, Company 2, DMZ, and inter-site paths
- a defined Company 1 service stack inside Site 2 including domain, file, web, client, and SAN roles
- healthy Company 2 identity, DNS, and DHCP services
- isolated SAN-backed storage with live iSCSI consumption and synchronized file services
- two-client validation proving that both required web hostnames work from both company perspectives
- Veeam-based backup design with Site 2 repository use and Site 1 offsite-copy intent
- explicit requirement traceability and troubleshooting context that make the environment easier to hand over and defend

Taken as a whole, Site 2 is defined less by any single tenant than by the way its management, identity, storage, web, and recovery layers operate together. That integrated behavior is the correct basis for the final technical narrative.

# 5. Appendices

## Appendix A. Observed Addressing, Gateways, and Endpoints

**Table A1. Observed addressing, gateways, and endpoints**

| Host / Service | Address or Mapping |
|---|---|
| OPNsense WAN | `172.20.64.1/16` |
| OPNsense MSP interface | `172.30.65.177/29` |
| `Jump64` | `172.30.65.178` |
| `MSPUbuntuJump` | `172.30.65.179` |
| `S2Veeam` | `172.30.65.180` |
| `C1DC1` | `172.30.65.2` |
| `C1DC2` | `172.30.65.3` |
| `C1FS` | `172.30.65.4` |
| `C1WindowsClient` | `172.30.65.11` |
| `S2-Ubuntu-Client` | `172.30.65.36` |
| `C1WebServer` | `172.30.65.162` |
| `C2IdM1` | `172.30.65.66` |
| `C2IdM2` | `172.30.65.67` |
| `C2FS` | `172.30.65.68` |
| `C2LinuxClient` | `172.30.65.70` |
| `C2WebServer` | `172.30.65.170` |
| `C1SAN` | `172.30.65.186/29`, gateway `172.30.65.185` |
| `C2SAN` | `172.30.65.194/29`, gateway `172.30.65.193` |
| Company 1 web DNS records | `172.30.64.162`, `172.30.65.162` |
| Company 2 web DNS records | `172.30.64.170`, `172.30.65.170` |
| Site 1 Veeam alias from OPNsense | `192.168.64.20` |

## Appendix B. Evidence and Reference Traceability

**Table B1. Evidence and reference traceability**

| Report Area | Primary Basis |
|---|---|
| Environment scope and service model | Internal service requirements, logical inventory record, and live validation |
| MSP entry, segmentation, and routing | OPNsense XML export plus official OPNsense firewall, NAT, and OpenVPN documentation |
| Company 1 and Company 2 identity model | Samba AD documentation, namespace evidence, and live validation |
| File services and share presentation | Ubuntu Server Samba documentation plus `C2FS` validation evidence |
| Isolated SAN and iSCSI transport | Ubuntu Server iSCSI documentation, SAN addressing evidence, and `C2FS` session validation |
| Internal web publication | Microsoft IIS binding documentation plus hostname and raw-IP validation results |
| Backup and offsite protection | Veeam documentation, OPNsense route or rule evidence, and internal backup-design records |
| Troubleshooting and operational guidance | Live validation outcomes, current environment evidence, and observed dependency relationships |

## Appendix C. Service Verification Matrix

**Table C1. Service verification and assurance matrix**

| Service or Control Area | Validation Method | Evidence Summary | Assurance Level |
|---|---|---|---|
| Administrative entry and bastion access | Controlled remote-access verification and jump-host reachability checks | Both jump systems were reachable and remained the intended administrative entry points | High |
| Segmented networking and limited edge exposure | OPNsense XML review plus management-path checks | Interfaces, aliases, NAT publication limits, and service-specific rules were all evidenced | High |
| Company 1 service stack within Site 2 | MSP-bastion reachability checks, hostname validation, DNS visibility, and client validation | Company 1 domain, file, web, client, and SAN roles were all evidenced within the Site 2 model | High |
| Company 2 identity, DNS, and DHCP | Read-only service-state checks and DNS queries on `C2IdM1` and `C2IdM2` | Samba AD, DHCP, and required hostname records were all present and consistent | High |
| Dual-hostname web delivery | Client-side and bastion-side HTTPS validation by hostname and by raw IP | Both required hostnames returned successful responses while raw IP access reflected hardened behavior | High |
| File services and share isolation | `C2FS` service checks, mount validation, `testparm`, and sync-log review | SMB service state, mounted storage, public/private shares, and successful synchronization were all evidenced | High |
| Isolated SAN transport | SAN addressing evidence plus iSCSI session validation on `C2FS` | Storage transport was evidenced as isolated from tenant LAN segments and correctly consumed by the file-service layer | High |
| Backup and offsite protection | Veeam host reachability, route or rule review, and backup-design evidence | Protection architecture is strongly supported, with final console screenshots recommended for visual closure | Medium-High |
| Shared-forest interpretation | DNS visibility, client behavior, and confirmed namespace relationship | Cross-domain naming behavior is consistent with the documented forest relationship | Medium-High |
| External Linux SSH expectation | Administrative-path testing only in the current pass | Internal and managed access paths are supported, but public-edge proof was not repeated in this revision | Medium |

# 6. References

[1] OPNsense Documentation, "Rules," [https://docs.opnsense.org/manual/firewall.html](https://docs.opnsense.org/manual/firewall.html), accessed Mar. 24, 2026.

[2] OPNsense Documentation, "Network Address Translation," [https://docs.opnsense.org/manual/nat.html](https://docs.opnsense.org/manual/nat.html), accessed Mar. 24, 2026.

[3] OPNsense Documentation, "Setup SSL VPN Road Warrior," [https://docs.opnsense.org/manual/how-tos/sslvpn_client.html](https://docs.opnsense.org/manual/how-tos/sslvpn_client.html), accessed Mar. 24, 2026.

[4] SambaWiki, "Setting up Samba as an Active Directory Domain Controller," [https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller](https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller), accessed Mar. 24, 2026.

[5] Ubuntu Server Documentation, "Set up Samba as a file server," [https://documentation.ubuntu.com/server/how-to/samba/file-server/](https://documentation.ubuntu.com/server/how-to/samba/file-server/), accessed Mar. 24, 2026.

[6] Ubuntu Server Documentation, "iSCSI initiator (or client)," [https://documentation.ubuntu.com/server/how-to/storage/iscsi-initiator-or-client/](https://documentation.ubuntu.com/server/how-to/storage/iscsi-initiator-or-client/), accessed Mar. 24, 2026.

[7] Microsoft Learn, "binding Element for bindings for site for sites [IIS Settings Schema]," [https://learn.microsoft.com/en-us/previous-versions/iis/settings-schema/ms691267(v=vs.90)](https://learn.microsoft.com/en-us/previous-versions/iis/settings-schema/ms691267%28v%3Dvs.90%29), accessed Mar. 24, 2026.

[8] Veeam Help Center, "Configuring Backup Repositories," [https://helpcenter.veeam.com/docs/vbr/userguide/sch_configure_repository.html](https://helpcenter.veeam.com/docs/vbr/userguide/sch_configure_repository.html), accessed Mar. 24, 2026.

[9] Site 2 infrastructure configuration export, `config-rp-msp-gateway.et.lab-20260323222847.xml`, Mar. 23, 2026.

[10] Site 2 environment inventory, SAN addressing record, and namespace design record, Mar. 24, 2026.

[11] Site 2 live validation and service verification record, Mar. 23-24, 2026.

