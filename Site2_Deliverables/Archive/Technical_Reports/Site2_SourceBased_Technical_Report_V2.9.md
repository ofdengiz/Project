---
title: "Site 2 Infrastructure Deployment"
subtitle: "Integrated Technical Design, Validation, and Handover Report"
---

Design, Validation, and Handover Narrative for the Site 2 Environment Supporting Company 1, Company 2, and MSP Operations

**Prepared For**

Company 1, Company 2, and MSP stakeholders

**Prepared By**

Site 2 Infrastructure Delivery Team

**Document Type**

Formal technical handover and operations report

**Environment Scope**

Site 2 services supporting Company 1, Company 2, and MSP operations

**Document Version**

3.0

**Document Date**

March 25, 2026

**Intended Audience**

Client IT staff, MSP support teams, and successor operators

**Engineering Contributors**

Bailey Kulla, Elyazid Sidelkheir, Ru Wang, Justin Rosseleve, Yiqin Huang, Omer Deniz

**Report Intent**

This document is written in a client/MSP handover style while retaining the formal structure expected in a formal technical handover document, including a title page, table of contents, executive summary, introduction, discussion, conclusion, appendices, and IEEE-style references.

\newpage

# Contents

<p>Executive Summary</p>
<p>1&#46; Introduction</p>
<p>2&#46; Background</p>
<p>&nbsp;&nbsp;&nbsp;2.1 Design inputs and environment evidence</p>
<p>&nbsp;&nbsp;&nbsp;2.2 Evidence classes used in this report</p>
<p>&nbsp;&nbsp;&nbsp;2.3 Evidence-based method used for this report</p>
<p>&nbsp;&nbsp;&nbsp;2.4 Observation method</p>
<p>3&#46; Discussion</p>
<p>&nbsp;&nbsp;&nbsp;3.1 Environment overview and service boundaries</p>
<p>&nbsp;&nbsp;&nbsp;3.2 Site 2 logical service inventory and platform roles</p>
<p>&nbsp;&nbsp;&nbsp;3.3 MSP entry, network segmentation, remote access, and security rationale</p>
<p>&nbsp;&nbsp;&nbsp;3.4 Company 1 services</p>
<p>&nbsp;&nbsp;&nbsp;3.5 Company 2 identity, shared forest context, DNS, and DHCP</p>
<p>&nbsp;&nbsp;&nbsp;3.6 Storage, file services, and isolated SAN design</p>
<p>&nbsp;&nbsp;&nbsp;3.7 Client access, identity validation, and dual-hostname web delivery</p>
<p>&nbsp;&nbsp;&nbsp;3.8 Backup, recovery, and offsite protection</p>
<p>&nbsp;&nbsp;&nbsp;3.9 Requirement-to-implementation traceability</p>
<p>&nbsp;&nbsp;&nbsp;3.10 Service dependency, failure domains, and access model</p>
<p>&nbsp;&nbsp;&nbsp;3.11 Storage, backup, and recovery flow</p>
<p>&nbsp;&nbsp;&nbsp;3.12 Maintenance and daily duties</p>
<p>&nbsp;&nbsp;&nbsp;3.13 Troubleshooting and fast triage guide</p>
<p>&nbsp;&nbsp;&nbsp;3.14 Integrated design summary</p>
<p>4&#46; Conclusion</p>
<p>5&#46; Appendices</p>
<p>&nbsp;&nbsp;&nbsp;Appendix A. Observed addressing, gateways, and endpoints</p>
<p>&nbsp;&nbsp;&nbsp;Appendix B. Evidence and reference traceability</p>
<p>&nbsp;&nbsp;&nbsp;Appendix C. Service verification matrix</p>
<p>6&#46; References</p>

\newpage

# List of Figures

**Figure 1.** Site 2 topology and service-role alignment  

**Figure 2.** Site 2 logical service inventory and platform role map  

**Figure 3.** OPNsense interfaces, aliases, and limited edge exposure  

**Figure 4.** OPNsense OpenVPN and inter-site rule mapping  

**Figure 5.** Company 1 services from the Site 2 management path  

**Figure 6.** `C2IdM1` Active Directory, DNS, and DHCP evidence  

**Figure 7.** `C2IdM2` Active Directory, DNS, and DHCP evidence  

**Figure 8.** Shared-forest and cross-domain DNS evidence  

**Figure 9.** `C2FS` iSCSI-backed storage and mounted volume evidence  

**Figure 10.** `C2FS` SMB share definitions and synchronization evidence  

**Figure 11.** `C1SAN` isolated storage interface evidence  

**Figure 12.** `C2SAN` isolated storage interface evidence  

**Figure 13.** `C1UbuntuClient` Company 1 client dual-web evidence  

**Figure 14.** `C2LinuxClient` domain identity and dual-web evidence  

**Figure 15.** `S2Veeam` repository, backup jobs, and offsite-copy evidence  

# List of Tables

**Table 1.** Design inputs and evidence basis for Site 2  

**Table 2.** Evidence classes used in this report  

**Table 3.** Observation vantage points  

**Table 4.** Observed Site 2 systems and service roles  

**Table 5.** Site 2 logical service inventory and role mapping  

**Table 5A.** Observed Linux VM platform baseline  

**Table 6.** Site 2 network segments and gateways  

**Table 7.** OPNsense exposure, routing, and firewall policy summary  

**Table 8.** Company 1 service summary  

**Table 9.** Company 2 identity, DNS, and DHCP summary  

**Table 10.** Storage and isolated SAN summary  

**Table 11.** Client access and identity summary  

**Table 12.** Internal web delivery summary  

**Table 13.** Backup and offsite-protection summary  

**Table 14.** Requirement-to-implementation traceability matrix  

**Table 15.** Service dependency and failure-domain view  

**Table 16.** Authentication and authorization model  

**Table 17.** Storage, backup, and recovery data-flow summary  

**Table 18.** Operational maintenance checks  

**Table 19.** Troubleshooting and fast triage guide  

**Table 20.** Integrated design summary  

**Table A1.** Observed addressing, gateways, and endpoints  

**Table B1.** Evidence and reference traceability  

**Table C1.** Service verification and assurance matrix

# Executive Summary

Site 2 operates as an integrated service environment that combines MSP administration, Company 1 services, Company 2 services, isolated storage, and backup or recovery workflows within a single managed design. Rather than being explained one server at a time, it is best understood as a coordinated platform in which routing, identity, storage, web delivery, and protection services all contribute to the final operating model.

This report is based on three evidence classes:

- design requirements and service objectives for the Site 2 environment
- the Site 2 environment evidence set, including gateway configuration evidence, logical inventory records, and SAN screenshots
- current operating observations and targeted low-impact service validation recorded on March 23, March 24, and March 25, 2026

Current analysis shows Site 2 operating through three tightly related service layers:

- MSP management through controlled jump hosts, OPNsense segmentation, and an OpenVPN-backed inter-site path
- Company 1 core services through `C1DC1`, `C1DC2`, `C1FS`, `C1WindowsClient`, `C1UbuntuClient`, `C1WebServer`, and `C1SAN`
- Company 2 core services through `C2IdM1`, `C2IdM2`, `C2FS`, `C2LinuxClient`, `C2WebServer`, and `C2SAN`

The most important technical findings are:

- the OPNsense configuration shows deliberate segmentation across MSP, `C1LAN`, `C1DMZ`, `C2LAN`, `C2DMZ`, and a Site 1 OpenVPN path, while exposing only the jump hosts at the WAN edge
- both `C2IdM1` and `C2IdM2` were healthy for Samba AD and DHCP, and both held the expected dual A records for `c1-webserver.c1.local` and `c2-webserver.c2.local`
- environment evidence indicates that `c1.local` and `c2.local` operate within a shared forest; the observed cross-domain DNS visibility and client behavior are consistent with that design
- `C2FS` showed a live iSCSI session to `172.30.65.194:3260`, a mounted data volume at `/mnt/c2_public`, valid `C2_Public` and `C2_Private` share definitions, and successful Site 1 to Site 2 synchronization
- `C2LinuxClient` now carries `c1.local` and `c2.local` in its active resolver scope, allowing both required web hostnames to resolve by name only without pinning raw IP addresses
- both `C1UbuntuClient` and `C2LinuxClient` resolved and reached `https://c1-webserver.c1.local` and `https://c2-webserver.c2.local`, confirming that the same hostnames work from both company perspectives
- hostname-based SMB validation from `C2LinuxClient` to `c2fs.c2.local` proved browse, public-share write or delete, and user-specific private-share access without relying on a client-side raw-IP shortcut
- the current Linux service nodes also show a stable VM hardware baseline, with consistent virtualized CPU, memory, disk, and network patterns that match their documented service roles
- available backup design evidence indicates that `S2Veeam` protects 10 machines to a Site 2 dedicated disk, stores file-share backup data, and copies those backups offsite to Site 1; current operating observations align with the expected management and control paths to the Veeam server
- current Veeam management evidence also identifies a local repository, an offsite SMB repository target, separate backup-job families for Linux, Windows, and file-share content, and explicit backup-copy handling toward Site 1

Taken together, the available configuration evidence, observed service behavior, and vendor-supported design characteristics present a coherent and supportable Site 2 operating model.

Operationally, the environment can be read as a sequence of dependent layers. MSP-controlled entry establishes the support boundary, segmented networking governs how service paths are allowed to form, Company 1 and Company 2 systems deliver the tenant-facing workloads, isolated SAN links support file presentation without flattening storage into routed space, and Veeam extends the design beyond live service delivery into recoverability. The discussion that follows keeps that same sequence so that the report reads as one continuous technical narrative rather than as a set of disconnected findings.

# 1. Introduction

The purpose of this document is to describe Site 2 in a form that supports operational handover, ongoing support, and formal service review.

This version is grounded in the available design inputs, the current Site 2 evidence set, official vendor documentation for the deployed technologies, and current operating observations recorded on March 23, March 24, and March 25, 2026.

The report deliberately follows a formal handover structure so that it can be reviewed by technical leads, client stakeholders, and successor operators without requiring a separate explanatory walkthrough. The emphasis is on design rationale, operating state, and service relationships rather than on build notes alone.

The document is also ordered to mirror the way a senior operator would normally read the environment in practice: administrative entry first, then network control, then tenant service layers, followed by storage and file presentation, and finally protection or recovery. That ordering is intended to preserve narrative clarity while still using dense technical tables where they add precision.

For web-service discussion, the report is intentionally limited to the internal service hostnames used by the environment:

- `https://c1-webserver.c1.local`
- `https://c2-webserver.c2.local`

The previously discussed external hostname is intentionally excluded from the technical narrative because it is outside the required scope of this package.

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

- gateway configuration evidence containing the OPNsense interface, NAT, alias, routing, and firewall configuration
- a platform inventory record identifying the Site 2 system set and service roles
- a PowerShell screenshot showing `C1SAN` at `172.30.65.186/29` with gateway `172.30.65.185`
- an Ubuntu screenshot showing `C2SAN` at `172.30.65.194/29` with gateway `172.30.65.193`
- a confirmed role mapping that identifies `C1UbuntuClient` as the Company 1 client role for Site 2
- a confirmed namespace relationship showing that `c1.local` and `c2.local` operate within a shared forest
- a confirmed backup-design note stating that Veeam protects 10 machines to a Site 2 disk, retains file-share backup data, and copies that protected set offsite to Site 1

**Table 1. Design inputs and evidence basis for Site 2**

| Evidence or Input Type | What It Establishes | Site 2 Implication |
|---|---|---|
| Service requirements definition | Site 2 must support MSP operations, Company 1, Company 2, storage, backup, and secure connectivity | Site 2 must be documented as an integrated multi-service environment rather than as a single workload |
| Service-role mapping | Company 1, Company 2, and MSP responsibilities coexist inside one operating site | The technical narrative must explain how all three scopes interact |
| OPNsense configuration evidence | Real interface, NAT, alias, route, and firewall logic for Site 2 | Network and security sections can be evidence-based rather than inferred |
| Environment inventory record | Current system set and service-role distribution | The system inventory and role mapping can be presented without exposing hypervisor tooling |
| SAN addressing screenshots | Exact isolated-storage addressing and gateway structure | The storage architecture can be explained as a deliberate transport design |
| Namespace and client-role confirmations | Shared-forest interpretation and Company 1 client-role mapping | Cross-domain reachability and client behavior can be described accurately |
| Backup design summary | Protected workload count, file-share backup, and offsite-copy intent | The protection narrative can distinguish backup from synchronization and live service delivery |
| Current operating observations | Actual observed behavior through approved administrative paths | The final conclusions can be supported by current operational evidence |

## 2.2 Evidence classes used in this report

This report separates evidence by source so that claims remain accurate and supportable.

**Table 2. Evidence classes used in this report**

| Evidence Class | What It Includes | How It Is Used |
|---|---|---|
| Internal design inputs | Service requirements, service-role mapping, confirmed role notes, and backup design summary | Defines intended scope, operating model, and service expectations |
| Site 2 environment evidence | Gateway configuration evidence, platform inventory record, SAN screenshots, and confirmed environment notes | Provides architecture details that are valid even when not always directly queryable over CLI |
| Official vendor documentation | OPNsense, Samba, Ubuntu Server, Microsoft IIS, and Veeam documentation | Supports the rationale for network policy, identity, storage, web delivery, and protection design |
| Current operating observations | March 23, March 24, and March 25, 2026 observations from the approved remote path, jump hosts, MSP bastion, and low-impact CLI review | Describes current operating state and confirms the final deployed service behavior |

## 2.3 Evidence-based method used for this report

This report was rebuilt using only:

- the available Site 2 design inputs and evidence records
- official documentation for the core technologies deployed in Site 2
- current operating observations recorded on March 23, March 24, and March 25, 2026

That combination matters because no single evidence source could explain Site 2 adequately on its own. Design inputs define intent, environment records anchor the architecture, official references explain why the chosen mechanisms are supportable, and current observations show how those mechanisms behave under the documented operating path and after targeted low-impact corrections.


## 2.4 Observation method

The observation approach followed a management-first bastion model. `MSPUbuntuJump` was treated as the primary bastion for low-risk CLI review into Company 1 and Company 2 paths. The Windows jump and local workstation were used only where they added practical reachability context. Most CLI review against selected Linux systems was limited to state confirmation; where a current service behavior had drifted from the intended hostname-based design, the final pass also included a narrowly scoped corrective update followed immediately by revalidation.

**Table 3. Observation vantage points**

| Vantage Point | Why It Was Used |
|---|---|
| Approved remote management path | To verify controlled access to Site 2 jump services through the authorized operator path |
| `MSPUbuntuJump` | To perform low-risk CLI review from the MSP management plane into Company 1 and Company 2 paths |
| `Jump64` and local workstation | To add Windows-jump reachability context and external operator perspective where needed |
| Low-impact CLI review of Linux systems | To confirm service state without configuration changes |
| Targeted low-impact client correction and retest | To restore intended name-based resolution where current client behavior had drifted and to confirm the final service state |
| Environment screenshots and configuration evidence | To fill architecture details that are accurate but not always directly queryable from CLI |

This method is important because Site 2 is not just a list of hosts. Administrative reachability leads into network control, network control enables name resolution and tenant service delivery, storage paths support file presentation, and the protection layer sits beyond the live service path. Keeping that chain intact is what makes the rest of the document readable as a true handover narrative.

# 3. Discussion

## 3.1 Environment Overview and Service Boundaries

Site 2 should be read as a complete service site, not as a loose grouping of servers. It combines MSP administrative control, Company 1 cross-site service delivery, Company 2 core tenant services, isolated storage transport, and backup or recovery functions inside one routed operating model. That whole-site view matters because the design only makes sense when those layers are evaluated together.

The current operating observations and the configuration evidence support that whole-site reading clearly. MSP control is represented by OPNsense, the jump systems, and Veeam. Company 1 is represented by its directory, file, client, web, and storage services. Company 2 is represented by its identity, file, client, and web services. Together, those components define the real operating boundary of Site 2.

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
| `172.30.65.36` | `C1UbuntuClient`, identified in the environment evidence as the Company 1 client role |
| `172.30.65.162` | `C1WebServer` internal Company 1 web service on the Site 2 path |
| `172.30.65.66` | `C2IdM1` Company 2 identity, DNS, and DHCP |
| `172.30.65.67` | `C2IdM2` Company 2 identity, DNS, and DHCP |
| `172.30.65.68` | `C2FS` Company 2 file service and storage consumer |
| `172.30.65.70` | `C2LinuxClient` Company 2 Linux client |
| `172.30.65.170` | `C2WebServer` internal Company 2 web service |
| `172.30.65.186` | `C1SAN`, isolated storage segment for Company 1 file services |
| `172.30.65.194` | `C2SAN`, isolated storage segment for Company 2 file services |

Viewed together, these systems form a layered operating boundary rather than separate technical islands. Administrative control begins on the MSP side, tenant services sit behind segmented interfaces, storage remains deliberately detached from routed tenant segments, and backup occupies its own protection role. That layered reading is what allows the rest of the report to move from inventory into operational meaning.

**Figure 1. Site 2 topology and service-role alignment.**  
Description: This figure presents the major Site 2 service domains, including MSP jump paths, OPNsense, Company 1 services, Company 2 services, isolated SAN paths, and `S2Veeam`.  

![](Fig01_Topology.png){ width=95% }

## 3.2 Site 2 Logical Service Inventory and Platform Roles

The system inventory matters because it demonstrates planned platform structure rather than ad-hoc implementation. Site 2 was built as a separated service estate with clear roles for MSP control, Company 1 delivery, Company 2 operations, storage transport, and protection services. That role-mapping view is the foundation for understanding dependency, failure domain, and support ownership.

One useful example is the Company 1 Linux client role. The current hostname and user prompt now identify this system as `C1UbuntuClient`, with the active shell context shown as `admin@C1UbuntuClient`. This report therefore uses `C1UbuntuClient` consistently as the current Company 1 Linux client label.

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
| `C1UbuntuClient` | Company 1 Linux client role |
| `C2IdM1` | Company 2 identity, DNS, and DHCP |
| `C2IdM2` | Company 2 identity, DNS, and DHCP |
| `C2FS` | Company 2 file server |
| `C2LinuxClient` | Company 2 Linux client |
| `C2WebServer` | Company 2 web service |
| `C2SAN` | Company 2 isolated storage server |

### Observed Linux VM Platform Baseline

Beyond role mapping, the current platform baseline is useful because it shows that the Linux service nodes were sized and distributed according to their responsibilities rather than being left as generic identical builds without operational meaning. Identity services use a common two-node baseline, the file-service host carries the only materially larger data disk and dual-interface storage posture, the client remains lighter at the service layer but still fully domain-capable, and the Company 2 web node is provisioned as a focused application endpoint rather than a general infrastructure server.

This matters in a handover document because platform shape often explains later design decisions. A dual-controller identity pair with matching CPU and memory is easier to reason about for failover and naming consistency. A file-service VM with a separate mounted data disk is easier to defend than a host that stores user data in its root filesystem. A client with an up-to-date Ubuntu desktop stack explains why identity and end-user experience were validated there instead of on a headless server.

**Table 5A. Observed Linux VM platform baseline**

| System | Operating System | vCPU | Memory | Primary Storage Layout | Key Interface Layout | Role Interpretation |
|---|---|---|---|---|---|---|
| `C2IdM1` | Ubuntu 22.04.5 LTS | 4 | 7.8 GiB | `32 GB` system disk, `15 GB` root LV | `172.30.65.66/26` on `ens18` | Primary Company 2 identity, DNS, and DHCP node with enterprise-sized baseline matching controller duties |
| `C2IdM2` | Ubuntu 22.04.5 LTS | 4 | 7.8 GiB | `32 GB` system disk, `15 GB` root LV | `172.30.65.67/26` on `ens18` | Secondary Company 2 identity, DNS, and DHCP node aligned to the same controller baseline |
| `C2FS` | Ubuntu 22.04.5 LTS | 4 | 7.8 GiB | `16 GB` system disk plus `160 GB` mounted data disk at `/mnt/c2_public` | `172.30.65.68/26` service NIC on `ens19` plus `172.30.65.195/29` storage-side NIC on `ens18` | File-service host intentionally separated into service and storage-facing paths |
| `C2LinuxClient` | Ubuntu 25.04 | 4 | 7.3 GiB | `32 GB` root disk | `172.30.65.70/26` on `ens18` | Domain-capable Linux endpoint used to validate user experience, web resolution, and hostname-based SMB access |
| `C2WebServer` | Ubuntu 22.04.5 LTS | 4 | 7.8 GiB | `32 GB` system disk, `30 GB` root LV | `172.30.65.170/29` on `ens18` | Focused HTTPS application endpoint with hostname-driven `nginx` publication |

### Service Placement Rationale

Service placement within Site 2 follows a clear operational logic. MSP systems occupy the management plane so that privileged access, gateway control, and recovery tooling remain centralized. Company 1 and Company 2 retain their own directory, file, client, and web roles so that tenant functions stay understandable and support ownership remains bounded. Storage is kept off the routed tenant path and consumed only through the file-service layer, which prevents block transport from being treated like a general infrastructure network.

This placement model also reduces ambiguity during support. If an issue begins with identity, the first systems to inspect are the tenant identity nodes. If it begins with file presentation, the path naturally narrows to the file server, its mounted storage, and the isolated SAN link underneath. If it begins with recovery, the correct administrative focus is the Veeam platform and the inter-site rule set rather than the tenant hosts themselves.

This platform layout is useful because it demonstrates role separation, shows intentional infrastructure design, and makes the environment easier to understand for an operations handoff without exposing the underlying training or hosting platform.

Seen in that light, the inventory is not merely a host list. It is the service map of the entire site: MSP systems govern entry and recovery, Company 1 and Company 2 systems provide tenant-facing capability, and isolated SAN nodes exist only to feed the file-service layer. That is why later sections repeatedly return to the same systems when explaining dependencies, user-visible behavior, and recovery posture.

### Technology and Service-Stack Rationale

The underlying technology choices also follow a clear operational logic. OPNsense sits at the center because Site 2 depends on one authoritative point for segmentation, NAT, inter-site control, and limited edge publication. That decision is less about product preference than about keeping the network boundary legible. When remote access, tenant separation, cross-site reachability, and backup copy rules all terminate on the same policy platform, the environment becomes easier to hand over, audit, and change safely.

The identity layer intentionally uses two different service models without compromising readability. Company 1 follows a Windows-centered model that is appropriate for traditional domain, file, and client administration. Company 2 uses Samba AD on Ubuntu to deliver AD-compatible behavior in a Linux service stack. Together, those choices demonstrate that the site can support mixed-platform tenant requirements while still presenting a coherent naming, routing, and operational model to the receiving support team.

Storage and protection were also placed deliberately. File presentation remains on dedicated file-service hosts instead of being merged into the identity layer, which keeps user data handling separate from directory control. The isolated SAN paths keep block transport out of the general routed networks, and `S2Veeam` remains on the MSP side so that recovery oversight does not depend on logging into tenant systems during an incident. The result is a cleaner service stack: policy at the boundary, tenant services in their own domains, storage beneath file presentation, and backup above the live service path.

### Delivery-Phase Configuration Refinements

The final Site 2 state also reflects a small number of deliberate service refinements that improved operational coherence without changing the intended architecture. The Company 1 Linux endpoint was normalized to the `C1UbuntuClient` identity so that hostname, shell context, and documentation all refer to the same service role. On the Company 2 side, dual-record publication for `c2-webserver.c2.local` was restored so that the documented hostname model again reflects the intended two-site web path rather than a partially reduced DNS view.

The most visible refinement occurred on `C2LinuxClient`. Its resolver state was brought back into alignment with the design by applying `c1.local` and `c2.local` as the active search-domain scope through the client network configuration rather than by pinning ad-hoc raw-IP host entries. That adjustment matters because Site 2 is intentionally documented as a name-driven environment. The web and file-service paths should therefore succeed because the service namespaces are correct, not because individual clients are forced to bypass them.

The Linux client layer also now presents stable per-user home-directory behavior for `employee1@c2.local` and `employee2@c2.local`, which removes degraded shell-session behavior after domain-user login and brings the endpoint into line with the directory-backed user model described elsewhere in the report. These refinements did not change the architecture; they completed it by making the endpoint behavior match the design narrative more faithfully.

**Figure 2. Site 2 logical service inventory and platform role map.**  
Description: This figure maps the major Site 2 systems to their service roles without exposing underlying hypervisor-management tooling.  

![](Fig02_RoleMap.png){ width=95% }

## 3.3 MSP Entry, Network Segmentation, Remote Access, and Security Rationale

### Interface and Segment Design

The network layer is the controlling discipline of Site 2. If routing, segmentation, and exposure control are not well designed, then identity, storage, web delivery, and backup quickly become difficult to defend. The available OPNsense configuration evidence shows that Site 2 applies a disciplined bastion-first model rather than relying on broad edge exposure.

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

Each segment also has a distinct architectural purpose. The MSP network concentrates privileged tooling, the company LANs preserve tenant locality, the DMZ networks constrain published web services, and the isolated storage bridges keep block transport out of user-facing routed space. The network design is therefore not only a security measure; it is also the mechanism that makes the entire site understandable and supportable.

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

The firewall and alias design is equally instructive. The configuration evidence defines aliases for `C1_Nets`, `C2_Nets`, `C1_REMOTE`, `C2_REMOTE`, `ALL_WEBS`, `ALL_DNS`, `C1_DCs`, `C2_DCs`, `S2_VEEAM`, `SITE1_VEEAM`, and `VEEAM_COPY_PORTS`. That alias-driven style makes the policy easier to maintain and easier to explain in a handover report.

**Table 7. OPNsense exposure, routing, and firewall policy summary**

| Area | Configuration Evidence | Operational Meaning |
|---|---|---|
| Edge exposure | WAN NAT exposes only `Jump64` RDP and `MSPUbuntuJump` SSH | Reduces attack surface and matches bastion-host guidance |
| Inter-site tunnel | OpenVPN interface plus Site 1 route for `192.168.64.20/32` | Supports cross-site service reachability and backup copy flow |
| Company 1 policy | `C1LAN` allowed to `C1_GLOBAL`, `ALL_WEBS`, and `ALL_DNS`, with a block to `C2_GLOBAL` | Company 1 can reach shared services without flat access to Company 2 networks |
| Company 2 policy | `C2LAN` allowed to `C2_GLOBAL`, `ALL_WEBS`, and `ALL_DNS`, with a block to `C1_GLOBAL` | Company 2 can reach shared services without flat access to Company 1 networks |
| Cross-site web rule | `C1_REMOTE -> 172.30.65.170/32` on HTTP/HTTPS and `C2_REMOTE -> 172.30.65.162/32` on HTTP/HTTPS | Each site can reach the other site's web service using the expected hostname path |
| DNS reachability | `ALL_DNS` combines `C1_DCs` and `C2_DCs` | Supports shared name resolution across the service environment |
| Backup copy | `SITE1_VEEAM -> S2_VEEAM` on `VEEAM_COPY_PORTS` | Supports offsite backup transfer between the two sites |

From a documentation standpoint, this policy model explains several otherwise separate observations in one place: why only jump systems appear at the edge, why inter-tenant reachability is bounded, why dual-hostname web access works across sites, and why Veeam can use a specific inter-site path without collapsing the rest of the segmentation model.

The segmented model also creates a cleaner support contract between network and systems functions. Routing and policy determine which conversations are allowed to exist, but the tenant systems remain responsible for the services carried over those paths. That separation is one reason the environment can be documented clearly: the firewall defines the boundaries, while the tenant platforms define the workloads inside them.

The same design choice improves change control. Adjustments to remote access, inter-site reachability, or backup transport can be reasoned about at the policy layer without rewriting the tenant-service sections of the document. For handover purposes, that is a significant strength because it preserves a stable explanation even as individual service instances evolve.

### Operational Interpretation

Current operating observations matched this design well:

- Approved remote management access to both jump services was successful
- OPNsense management returned `HTTP 403`, which is consistent with a present but non-anonymous management plane
- OPNsense TCP `53` was reachable from `MSPUbuntuJump`

**Figure 3. OPNsense interfaces, aliases, and limited edge exposure.**  
Description: This figure shows the OPNsense interface model, selected aliases, and the limited WAN publication of the two jump-host entry points.  

![](Fig03_OPNsense_Interfaces.png){ width=95% }

**Figure 4. OPNsense OpenVPN and inter-site rule mapping.**  
Description: This figure shows the OpenVPN-backed inter-site rule set that supports cross-site web access and backup-copy transport between Site 1 and Site 2.  

![](Fig04_OPNvpn.png){ width=95% }

## 3.4 Company 1 Services

### Service Overview

The available evidence identifies the following Company 1 components in the environment:

- `C1DC1` at `172.30.65.2`
- `C1DC2` at `172.30.65.3`
- `C1FS` at `172.30.65.4`
- `C1WindowsClient` at `172.30.65.11`
- `C1UbuntuClient` at `172.30.65.36`, aligned to the active Company 1 Linux client role
- `C1WebServer` at `172.30.65.162`
- `C1SAN` at `172.30.65.186/29`, gateway `172.30.65.185`

These components cover directory services, file services, client services, internal web services, and isolated storage.

Together they form a complete Company 1 service stack. Directory services establish identity and name resolution, the file server turns storage into user-facing shares, clients show that the service experience is usable from endpoints, and the web service presents the internally named application path. The isolated SAN link beneath that stack keeps storage transport separate from the user and server networks that consume the final service.

The Company 1 section is therefore documented in the same terms as the rest of the report: service role, reachable administrative path, observed operating state, and architectural meaning. That keeps the narrative focused on how the service set behaves within the site model rather than reducing Company 1 to a single cross-site dependency.

### Architectural Rationale

The Company 1 service arrangement is deliberate rather than incidental. Two domain controllers keep authentication and naming from collapsing into a single point of operational concentration, while also providing a recognizable enterprise identity pattern for a receiving support team. `C1FS` remains separate from the domain-controller role so that file-service activity, share administration, and storage consumption do not compete directly with directory duties. That separation is especially valuable in a handover context because it keeps user-data operations, identity operations, and storage operations understandable as different support concerns.

The same logic applies to the remaining Company 1 systems. `C1WebServer` is placed on the web-facing path and behaves as a hostname-based internal application endpoint rather than a general-purpose server landing page. `C1WindowsClient` and `C1UbuntuClient` show that the Company 1 service contract is consumable from more than one endpoint context, which strengthens the credibility of the overall tenant model. `C1SAN` stays isolated underneath the file-service layer so that block transport remains a controlled dependency rather than a visible part of the ordinary user network.

### Observed Operating State

- Company 1 DNS records were visible on both Company 2 identity nodes
- `MSPUbuntuJump` reached `C1DC1` and `C1DC2` on `53`, `88`, `389`, `445`, `3389`, and `5985`
- `MSPUbuntuJump` reached `C1FS` on `445` and `3389`, and `C1UbuntuClient` on `22`
- `MSPUbuntuJump` reached `C1WebServer` on `443`, `3389`, and `5985`
- `c1-webserver.c1.local` was resolved through `C2IdM1` and returned `HTTP 200`, while raw-IP access returned `HTTP 404`
- `C1UbuntuClient` successfully resolved and reached both required web hostnames

**Table 8. Company 1 service summary**

| Company 1 Component | Function | Observed State | Notes |
|---|---|---|---|
| `C1DC1` and `C1DC2` | Company 1 directory services | Reachable from `MSPUbuntuJump` on `53`, `88`, `389`, `445`, `3389`, and `5985` | Directory, DNS, and management paths were visible from the approved administrative path |
| `C1FS` | Company 1 file services | Reachable from `MSPUbuntuJump` on `445` and `3389` | File-service and management access paths were available |
| `C1WebServer` | Company 1 internal web service | `c1-webserver.c1.local` returned `200`; raw IP returned `404`; `443`, `3389`, and `5985` reachable from `MSPUbuntuJump` | Current behavior is consistent with hostname-based publication |
| `C1WindowsClient` | Company 1 Windows client service role | Present in the environment inventory evidence | Included in the documented service inventory |
| `C1UbuntuClient` | Company 1 Linux client service role | Resolved both required web hostnames and showed Company 1 domain context | Client-side service access was visible from the Company 1 domain context |
| `C1SAN` | Company 1 isolated storage transport | Addressing and gateway confirmed by environment evidence; not exposed to the MSP management plane as a general-purpose routed service | Storage remains separated from routed tenant segments |
| `c1.local` namespace relationship | Cross-domain naming and namespace visibility | Design evidence plus Company 1 DNS visibility on Company 2 identity nodes | Naming behavior is consistent across the two company contexts |

### Service Composition and Operational Reading

Company 1 is best understood as a composed service path rather than a flat host list. The domain controllers provide the naming and identity base, the file server provides structured data access, the client systems show how those services are consumed in practice, the web server carries the internal application endpoint, and the SAN bridge supports storage transport underneath the file-service layer. Each role has a distinct technical purpose, but the overall value comes from the way those roles reinforce one another.

That composed reading also matters for support ownership. A directory issue, a share issue, a hostname issue, and a storage-transport issue may all appear to an end user as general service instability, yet they belong to different technical layers. Writing Company 1 in layered form keeps the eventual support response aligned to the actual architecture.

From an end-to-end service perspective, the Company 1 path can be read in a simple sequence: domain services establish identity and namespace, clients consume those names, the web tier responds only under the intended hostname, the file tier exposes structured access, and the SAN tier remains beneath that file tier as a transport dependency rather than a user-facing service. That sequence is important because it explains not only what exists, but why the Company 1 layer behaves predictably when approached from MSP administration or from Company 1 endpoints.

The table is intentionally multi-layered. It does not stop at listing systems; it connects component function, reachable path, and operational meaning so that the relationship between Company 1 services and the documented site model remains visible.

**Figure 5. Company 1 services from the Site 2 management path.**  
Description: This figure captures Company 1 service visibility from the Site 2 management path, including cross-site reachability and Company 1 web response behavior.  

![](Fig05_CompanyServices_From_Ubuntu_Jump.png){ width=95% }

## 3.5 Company 2 Identity, Shared Forest Context, DNS, and DHCP

### Identity Service Health

The identity layer is one of the strongest and most operationally important parts of Site 2. Current observations on `C2IdM1` and `C2IdM2` showed:

- `samba-ad-dc` active on both nodes
- `isc-dhcp-server` active on both nodes
- valid DNS records for both Company 1 and Company 2 web services on both nodes

These checks directly satisfy multiple service requirements. Company 2 requires directory services, DNS, and fault-tolerant DHCP. The current operating state shows that those services remain queryable and usable through the approved bastion path.

That combination of service state and namespace visibility is central to the rest of the environment. Without stable identity and DNS behavior, the dual-hostname web model, share access, and cross-domain client behavior described later in the document would all become much harder to defend.

### Namespace and Forest Design

Available environment evidence indicates that `c1.local` and `c2.local` share a forest. That forest relationship was not reconfigured during testing, so it is treated as environment design evidence. The live results are consistent with that design because both Company 1 and Company 2 web namespaces are visible on Company 2 identity servers and are reachable from both clients.

**Table 9. Company 2 identity, DNS, and DHCP summary**

| Service Item | `C2IdM1` | `C2IdM2` | Operational Interpretation |
|---|---|---|---|
| Samba AD service state | Active | Active | Directory and Kerberos-compatible identity services are healthy on both nodes |
| DHCP service state | Active | Active | Address assignment remains available across the Company 2 LAN |
| DHCP failover role | Primary | Secondary | Lease resilience is intentionally split between the two nodes rather than concentrated on one host |
| Primary AD-integrated zones | `c2.local`, `c1.local`, `_msdcs.c2.local` | `c2.local`, `c1.local`, `_msdcs.c2.local` | Both nodes carry the authoritative namespace set required for the documented service model |
| Observed directory principals | `Administrator`, `admin`, `employee1`, `employee2`, `c2_file_users` present | `Administrator`, `admin`, `employee1`, `employee2`, `c2_file_users` present | Identity services are backing both privileged and end-user access paths |
| `c1-webserver.c1.local` A records | `172.30.64.162`, `172.30.65.162` | `172.30.64.162`, `172.30.65.162` | Company 1 web naming is visible inside the Company 2 identity plane |
| `c2-webserver.c2.local` A records | `172.30.64.170`, `172.30.65.170` | `172.30.64.170`, `172.30.65.170` | Company 2 web naming preserves the intended dual-site hostname model |
| Cross-domain namespace significance | Company 1 name present | Company 1 name present | Shared naming is an operating feature, not an incidental cache artifact |

The presence of Company 1 records on the Company 2 identity servers is especially important. It shows that Site 2 was designed to support cross-site internal web delivery rather than keeping each company's namespace invisible from the other side.

The currently observed DHCP configuration adds further maturity to that picture. `C2IdM1` is carrying the primary failover role while `C2IdM2` carries the secondary role for the Company 2 subnet, which means address control follows the same dual-node discipline as identity and DNS. That is a stronger operational model than simply running DHCP on two hosts without a clear coordination pattern.

Taken together, the two identity nodes do more than answer DNS queries. They stabilize the naming and authorization layer that later sections rely on for client access, hostname-based web delivery, and consistent cross-domain interpretation.

In operational terms, `C2IdM1` and `C2IdM2` are each carrying more than a single directory function. They are part of the authorization model, the internal naming model, and the address-assignment model at the same time. That concentration of responsibility is why this section must be read before the client, web, and file-service sections that follow.

The dual-node design also improves the overall readability of the environment. It separates Company 2 identity duties into a recognizable enterprise pattern instead of treating DNS, DHCP, and directory behavior as one-off services. For a receiving support team, that makes normal health expectations much clearer.

**Figure 6. `C2IdM1` Active Directory, DNS, and DHCP evidence.**  
Description: This figure shows `C2IdM1` with active Samba AD, active DHCP, and DNS query output for both required web hostnames.  

![](Fig06.png){ width=90% }

**Figure 7. `C2IdM2` Active Directory, DNS, and DHCP evidence.**  
Description: This figure shows `C2IdM2` with active Samba AD, active DHCP, and DNS query output for both required web hostnames.  

![](Fig07.png){ width=90% }

**Figure 8. Shared-forest and cross-domain DNS evidence.**  
Description: This figure summarizes the cross-domain naming model by showing how both Company 1 and Company 2 web namespaces are carried within the Company 2 identity plane.  

![](Fig08_CrossDomain_DNS.png){ width=90% }

## 3.6 Storage, File Services, and Isolated SAN Design

The storage layer is one of the clearest indicators that Site 2 was engineered rather than improvised. The environment uses isolated SAN connectivity, mounted block storage, structured share presentation, and synchronization behavior in a way that aligns cleanly with the project's storage objectives.

### File-Service State

Inspection of `C2FS` showed:

- `smbd` active
- `/mnt/c2_public` mounted from `/dev/sdb`
- an active iSCSI session to `172.30.65.194:3260` using target `iqn.2024-03.org.clearroots:c2san`
- `C2_Public` and `C2_Private` share definitions in Samba
- successful synchronization from Site 1 to Site 2 in the current log

That sequence is operationally important: storage is presented over isolated transport, mounted on the file-service host, structured into public and private paths, and then surfaced through Samba. Writing the section in that order makes it clear where responsibility changes from storage delivery to file presentation.

### SAN Isolation Model

The SAN evidence clarifies an architectural layer that CLI testing on `C2FS` alone would not fully explain. Two isolated SAN servers are present in the design:

- `C1SAN` at `172.30.65.186/29`, gateway `172.30.65.185`
- `C2SAN` at `172.30.65.194/29`, gateway `172.30.65.193`

Those SAN systems are isolated and bridged only to the corresponding file servers. That is a strong design choice because it keeps storage traffic off the tenant LAN and DMZ segments while still satisfying the iSCSI requirement in a supportable way. Administrative-path checks from `MSPUbuntuJump` did not expose the SAN endpoints as general-purpose management services, which is consistent with the intended isolated-storage model rather than a flat routed design.

**Table 10. Storage and isolated SAN summary**

| Item | Evidence |
|---|---|
| `C2FS` service interface | `172.30.65.68/26` on `ens19` |
| `C2FS` storage interface | `172.30.65.195/29` on `ens18` |
| `C2FS` mounted data path | `/mnt/c2_public` |
| `C2FS` mounted device | `/dev/sdb` |
| `C2FS` transport | `iscsi` |
| Active Company 2 iSCSI session | `172.30.65.194:3260`, target `iqn.2024-03.org.clearroots:c2san` |
| Company 2 public share | `[C2_Public] -> /mnt/c2_public/Public` |
| Company 2 private share | `[C2_Private] -> /mnt/c2_public/Private/%U` |
| Hostname-based share access path | `//c2fs.c2.local/C2_Public` and `//c2fs.c2.local/C2_Private` validated from `C2LinuxClient` |
| Latest Company 2 sync result | `Sync completed successfully` |
| Company 1 SAN evidence | `C1SAN 172.30.65.186/29`, gateway `172.30.65.185`, environment screenshot evidence |
| Company 2 SAN evidence | `C2SAN 172.30.65.194/29`, gateway `172.30.65.193`, environment screenshot evidence |
| Architectural interpretation | Two isolated storage bridges support the two file-service domains without flattening storage into routed user segments |

This is one of the strongest sections of the Site 2 design because the architecture, the supporting evidence, and the current operating observations all reinforce the same conclusion.

The strength of this section comes from the fact that it documents an actual service chain rather than isolated data points. The evidence shows how block storage reaches the file-service host, how that host structures the resulting data into public and private shares, and how synchronization activity fits on top of that base layer.

### Share Presentation Model

The file-service model distinguishes clearly between transport, mount, share publication, and user experience. `C2SAN` supplies block storage, `C2FS` consumes and mounts it, Samba converts that mounted space into named shares, and users finally encounter those shares as public or private destinations. Each step belongs to a different technical layer, which is why storage issues do not have to be described in the same language as share-permission or client-authentication issues.

This separation is also one of the design's strongest operational characteristics. End users and routine support processes never need to interact with the SAN endpoints directly. The file-service hosts absorb the storage complexity and present stable SMB paths above it, which is the more supportable model for day-to-day operations and formal handover.

Current client-side validation reinforced that point by consuming the shares through `c2fs.c2.local` rather than through an address-only path. `employee1@c2.local` and `employee2@c2.local` were both able to browse their expected destinations, and the public-share write or delete check succeeded without bypassing the documented naming model. That is valuable because it closes the loop between storage architecture and actual user-visible SMB behavior.

**Figure 9. `C2FS` iSCSI-backed storage and mounted volume evidence.**  
Description: This figure shows the active iSCSI session and the mounted `/mnt/c2_public` volume on `C2FS`.  

![](Fig09.png){ width=90% }

**Figure 10. `C2FS` SMB share definitions and synchronization evidence.**  
Description: This figure shows the `C2_Public` and `C2_Private` share definitions together with successful synchronization evidence.  

![](Fig10.png){ width=90% }

**Figure 11. `C1SAN` isolated storage interface evidence.**  
Description: This figure shows the `C1SAN` interface configuration for the isolated Company 1 storage segment.  

![](Fig11.png){ width=80% }

**Figure 12. `C2SAN` isolated storage interface evidence.**  
Description: This figure shows the `C2SAN` interface configuration for the isolated Company 2 storage segment.  

![](Fig12.png){ width=80% }

## 3.7 Client Access, Identity Validation, and Dual-Hostname Web Delivery

Client-side observation is essential because a service environment is only meaningful when directory, web, and file outcomes are visible from real consumer systems. For Site 2, the client perspective shows that the design is not only correctly configured on servers, but also usable from both company contexts.

### Client Validation Perspectives

Two different client perspectives were available:

- `C1UbuntuClient`, identified in the environment evidence as the Company 1 client role
- `C2LinuxClient`, the Company 2 Linux client

Both clients were able to resolve and reach both internal web hostnames. That result matters because it proves the same named services can be consumed consistently from both company perspectives:

- `https://c1-webserver.c1.local`
- `https://c2-webserver.c2.local`

`C1UbuntuClient` additionally showed Company 1 realm membership and the current shell identity `admin@C1UbuntuClient`, while `C2LinuxClient` showed valid `C2.LOCAL` realm membership and valid domain-user lookups for `employee1@c2.local` and `employee2@c2.local`.

These client observations are the clearest expression of end-to-end service success. They show that routing, naming, identity, and web publication all converge into a predictable user-visible result instead of remaining separate server-side claims.

### Client Resolver and Share-Consumption Alignment

The final client state is particularly important on `C2LinuxClient` because this endpoint now reflects the intended Site 2 name-resolution model without falling back to address-based shortcuts. Its active DNS servers remain the Company 2 identity nodes, while its resolver search domains now include both `c1.local` and `c2.local`. That means the client consumes the environment as a multi-namespace tenant endpoint while still relying on the authoritative Company 2 directory services for resolution.

The Linux client also now presents fully formed home directories for `employee1@c2.local` and `employee2@c2.local`, which makes domain-user sessions behave like first-class endpoint sessions rather than partial identity lookups. Combined with the hostname-based SMB access to `c2fs.c2.local`, that gives Site 2 a cleaner end-user story: directory users can authenticate, land in the expected home context, resolve the expected service names, browse named file services, and consume the internal web applications entirely through the documented namespace model.

**Table 11. Client access and identity summary**

| Validation Item | `C1UbuntuClient` | `C2LinuxClient` |
|---|---|---|
| Host role | Company 1 client role | Company 2 client role |
| Domain context | `c1.local` / `C1.LOCAL` | `c2.local` / `C2.LOCAL` |
| Domain-user state | `administrator@c1.local` active session | `employee1@c2.local` and `employee2@c2.local` resolved by `getent passwd` and validated as interactive users |
| Client name-service state | Company 1 membership plus successful cross-domain FQDN consumption | Active DNS servers `172.30.65.66`, `172.30.65.67` with `c1.local` and `c2.local` in current resolver scope |
| `c1-webserver.c1.local` | Resolved and returned `HTTP 200` | Resolved and returned `HTTP 200` |
| `c2-webserver.c2.local` | Resolved and returned `HTTP 200` | Resolved and returned `HTTP 200` |
| SMB consumption path | Not the primary Company 1 proof point in the current pass | `c2fs.c2.local` used successfully for browse, public-share write or delete, and private-share access |
| Operational significance | Proves Company 1 can consume both tenant web names | Proves Company 2 can consume both tenant web names |

### Hostname-Based Web Publishing Behavior

The bastion-side curl tests also showed a hardened web pattern:

- `c1-webserver.c1.local` returned `HTTP 200`
- `https://172.30.65.162` returned `HTTP 404`
- `c2-webserver.c2.local` returned `HTTP 200`
- `https://172.30.65.170` returned `HTTP 404`

That hostname-first behavior shows that the services are published intentionally, not exposed as loose IP-based pages.

From an architectural standpoint, that distinction matters because it aligns the web layer to named service delivery rather than opportunistic address-based exposure. It is the more defensible model for an internal enterprise service environment and it reinforces the idea that DNS, routing, and web configuration were designed to operate together.

The current `nginx` evidence on `C2WebServer` reinforces that interpretation. The host is not simply listening on `443`; it is configured to answer the `c2-webserver.c2.local` virtual host specifically, and it returns `404` when the same service is addressed by raw IP without the expected host header. That behavior is precisely what the final Site 2 narrative should describe, because it proves the web layer is bound to the documented namespace rather than to incidental addressing.

**Table 12. Internal web delivery summary**

| Validation | Observed Result |
|---|---|
| `https://c1-webserver.c1.local` pinned to `172.30.65.162` | `HTTP/2 200` |
| `https://172.30.65.162` | `HTTP/2 404` |
| `https://c2-webserver.c2.local` pinned to `172.30.65.170` | `HTTP/1.1 200 OK` |
| `https://172.30.65.170` | `HTTP/1.1 404 Not Found` |
| Company 1 client to both hostnames | Success |
| Company 2 client to both hostnames | Success |

### Client-Service Interpretation

The client perspective has additional value beyond web validation. It confirms that directory, DNS, routing, and HTTPS behavior align from the viewpoint that matters most: the endpoint that consumes the service. When both company contexts resolve the same named services successfully, the environment shows a predictable internal application model rather than a set of isolated server-side checks.

That consistency also improves future support and change planning. As long as the named service contract remains stable, underlying address changes, certificate updates, or back-end maintenance can be managed without rewriting how users and administrators are expected to reach the services.

**Figure 13. `C1UbuntuClient` Company 1 client dual-web evidence.**  
Description: This figure shows `C1UbuntuClient` in its Company 1 context with successful access to both internal web hostnames.  

![](Fig13.png){ width=90% }

**Figure 14. `C2LinuxClient` domain identity and dual-web evidence.**  
Description: This figure shows `C2LinuxClient` domain identity state together with successful access to both required web hostnames.  

![](Fig14.png){ width=90% }

## 3.8 Backup, Recovery, and Offsite Protection

### Backup Design Basis

Backup and recovery must be documented at the same level of care as identity or networking because they define whether the environment is supportable after failure. In Site 2, the available design evidence and the current operating observations complement each other well.

According to the available backup design evidence:

- Veeam backs up 10 machines
- those backups are written to a Site 2 dedicated disk on the Veeam server
- a file-share backup also exists on the Veeam server
- the environment also sends offsite backup data to Site 1

This protection model is intentionally broader than a simple virtual-machine backup statement. It combines workload protection, file-share protection, repository separation, and offsite copy so that failure handling does not depend on a single recovery mechanism.

### Inter-Site Backup Path

The OPNsense configuration evidence supports that overall story by defining:

- `S2_VEEAM = 172.30.65.180`
- `SITE1_VEEAM = 192.168.64.20`
- `VEEAM_COPY_PORTS = 135, 445, 6160, 6162, 2500:3000, 10005, 10006`
- an inter-site OpenVPN rule allowing `SITE1_VEEAM -> S2_VEEAM` on `VEEAM_COPY_PORTS`
- a static route for `192.168.64.20/32` via the Site 1 OpenVPN gateway

### Current Operational State

Management-path checks corroborated the management and control plane by showing that `S2Veeam` was reachable from the approved admin path on:

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
| Veeam control paths | Current operating observations | Management and agent ports are healthy from the bastion path |
| Site 2 backup repository | Current repository evidence plus environment design note | A dedicated local repository is present as `Site2Veeam` on `Z:\\Site2AgentBackups` |
| Offsite backup repository target | Current repository evidence plus inter-site route or rule evidence | An SMB target to Site 1 is defined as `Site1OffsiteSmbShare` at `\\\\192.168.64.20\\Site2OffsiteFromSite2` |
| File-share backup | Current job inventory plus environment design note | Separate `C1_FileShare` and `C2_FileShare` backup jobs preserve file-service content independently of VM-agent jobs |
| Workload backup job families | Current job inventory | Linux and Windows backup-job families are separated as `Ubuntu_Servers` and `Windows_Servers` |
| Offsite copy orchestration | Current copy-job inventory plus OPNsense route and rule evidence | Copy workflows exist for file-share and server-backup families, extending local retention into Site 1 |
| Protected workload count | Environment design note and Veeam inventory evidence | 10 machines are included in Veeam protection |

Documented this way, the protection layer can be explained at both the architectural and operational levels. Repository placement, workload count, file-share coverage, and inter-site copy path all align to the same recovery narrative, which is the main requirement of the technical report.

### Recovery Role in the Overall Site Design

Recovery occupies a distinct governance role within Site 2. Live services may be carried by Company 1 and Company 2 systems, but recoverability is centered on `S2Veeam` and the approved inter-site path. That placement is valuable because it allows backup administration and recovery oversight to remain available even when the issue being investigated affects a tenant workload.

The result is a layered protection posture. Synchronization supports content continuity, file-service structure preserves organized data access, local repository storage provides immediate backup retention, and the Site 1 copy extends that posture beyond a single-site failure boundary. Documenting those layers together is essential because each one contributes a different part of the recovery story.

**Figure 15. `S2Veeam` repository, backup jobs, and offsite-copy evidence.**  
Description: This figure consolidates the Veeam repository, backup-job, and backup-copy views that support the documented Site 2 and Site 1 protection relationship.  

![](Fig15_Composite_Clean.png){ width=95% }

## 3.9 Requirement-to-Implementation Traceability

### Requirement Coverage

Requirement traceability is what separates a persuasive technical report from a simple build summary. In Site 2, each major requirement needs to be tied to a concrete implementation choice and to live or documentary evidence that proves it was delivered.

**Table 14. Requirement-to-implementation traceability matrix**

| Requirement Area | Site 2 Implementation | Current Evidence | Status | Operational Interpretation |
|---|---|---|---|---|
| Secure remote access | `Jump64`, `MSPUbuntuJump`, approved remote operator access, and OPNsense WAN NAT only for jump systems | Bastion reachability checks plus gateway NAT review | Established | Bastion-first entry remains the defining administrative access model |
| Segmented multi-network design | OPNsense interfaces for `MSP`, `C1LAN`, `C1DMZ`, `C2LAN`, `C2DMZ`, plus isolated SAN bridges | Configuration review plus current path checks | Established | Network separation and isolated storage transport form the main control boundary of the site |
| Site-to-site connectivity | `SITE1_OVPN`, `C1_REMOTE`, `C2_REMOTE`, Veeam route, and cross-site rules | Route or rule review plus Company 1 reachability from Site 2 | Established | Inter-site connectivity supports cross-site web reachability and backup transport without flattening tenant boundaries |
| Company 2 identity, DNS, and DHCP | `C2IdM1` and `C2IdM2` running Samba AD, DNS, and DHCP | `systemctl` checks plus DNS query results | Established | Identity and naming services provide the control plane required for tenant access and service resolution |
| Company 2 internal web service | `C2WebServer` and dual A-record publishing for `c2-webserver.c2.local` | Bastion and client curl checks returning `200` by hostname | Established | Web delivery aligns to hostname-based publication and internal service consumption |
| Company 1 services | `C1DC1`, `C1DC2`, `C1FS`, `C1WebServer`, `C1WindowsClient`, `C1UbuntuClient`, `C1SAN`, and shared namespace visibility | Inventory evidence, administrative-path checks, client access, DNS visibility, and SAN evidence | Established | Company 1 contributes a complete directory, file, client, web, and storage service set within the site operating model |
| File services and share isolation | `C2FS` with `C2_Public` and `C2_Private` share definitions | `testparm -s`, sync log, mount evidence, and hostname-based SMB validation from `C2LinuxClient` | Established | Share presentation remains structured around public access and per-user private isolation |
| iSCSI design | `C2SAN` target, `C2FS` initiator, isolated storage network, mirrored storage logic | `iscsiadm -m session`, `findmnt`, SAN screenshots | Established | Storage transport stays separate from routed tenant traffic and is consumed by the file-service layer |
| Client-side service consumption | `C1UbuntuClient` and `C2LinuxClient` resolving and reaching both required hostnames | Direct client-side web and identity checks | Established | Client observations confirm that named services are consumable from both company contexts |
| Backup, file-share backup, and offsite copy | `S2Veeam`, Site 2 repository disk, file-share backup, and Site 1 offsite-copy design | Live port checks, route or rule review, and available backup design detail | Established | Backup, file-share protection, and offsite copy provide a recovery layer distinct from live synchronization |
| Linux-client SSH accessibility requirement | Linux client reachable through the approved management path | Internal SSH/admin path visible from Site 2 | Established within scope | Administrative SSH behavior aligns to the documented management-path model |

What the matrix shows is that major requirements were not satisfied independently of one another. The same design choices, especially OPNsense segmentation, stable identity services, isolated storage transport, client-visible hostname behavior, and Veeam protection, support multiple requirement areas at the same time.

## 3.10 Service Dependency, Failure Domains, and Access Model

### Dependency View

Site 2 contains several distinct service planes, and each one fails differently. Mapping those dependencies makes troubleshooting faster and reduces the risk of treating a symptom as though it were the root cause.

**Table 15. Service dependency and failure-domain view**

| Service Plane | Primary Components | Downstream Dependencies | Main Failure Symptom | Fastest Health Check |
|---|---|---|---|---|
| Entry and management | `Jump64`, `MSPUbuntuJump`, OPNsense MSP interface | Every other administrative workflow | Team cannot reach consoles or internal hosts quickly | Approved remote-access verification and bastion reachability checks |
| Identity and naming | `C2IdM1`, `C2IdM2`, Samba AD, DNS, DHCP | Client logon, hostname resolution, share access, cross-domain name visibility | User lookup fails or hostnames do not resolve | `systemctl`, `realm list`, and `samba-tool dns query` |
| Web delivery | `C1WebServer`, `C2WebServer`, DNS records, cross-site OPNsense rules | Demo visibility for both companies | Hostname fails or wrong content is served | `curl -k -I` by hostname and raw IP |
| File and storage | `C2FS`, `C2SAN`, iSCSI session, share configuration | Public/private shares and sync visibility | Shares disappear or `/mnt/c2_public` is missing | `findmnt`, `iscsiadm -m session`, `testparm -s` |
| Recovery and backup | `S2Veeam`, Site 1 route, OpenVPN rule path | VM recovery, file-share backup, offsite resilience | Backup copy or restore confidence drops | Port checks plus Veeam management-state evidence |
| Company 1 services | `C1DC1`, `C1DC2`, `C1FS`, `C1WebServer`, `C1WindowsClient`, `C1UbuntuClient`, `C1SAN`, and Site 1 remote aliases | Administrative-path reachability, client behavior, and environment inventory evidence | Company 1 service paths are unavailable from the expected operating flow | `nc` checks, hostname curl, inventory review, and client-side checks |

**Table 16. Authentication and authorization model**

| Actor / Role | Identity Source | Primary Access Path | Scope of Access | Control Rationale |
|---|---|---|---|---|
| MSP administrators | MSP and local administrative paths | Jump hosts, OPNsense, Veeam, and approved internal admin path | Full support and service operations | Centralizes privileged access through bastion systems |
| Company 1 administrators | `c1.local` domain context | Company 1 systems through the approved administrative path | Company 1 infrastructure and service administration | Preserves tenant scoping while allowing approved administrative access |
| Company 1 end users | `c1.local` user accounts | `C1WindowsClient`, `C1UbuntuClient`, and Company 1 service paths | User authentication and normal service consumption | Reflects normal tenant use of Company 1 services |
| Company 2 administrators | `c2.local` domain context | `C2IdM1`, `C2IdM2`, `C2FS`, `C2WebServer`, `C2LinuxClient` | Company 2 service administration | Keeps tenant administration aligned to Company 2 services |
| Company 2 end users | `c2.local` user accounts | `C2LinuxClient` and SMB access | User authentication and share consumption | Demonstrates that directory services produce real client outcomes |
| File-share users | `c2_file_users` and `%U` mapping | `C2_Public` and `C2_Private` shares | Group-based public access and per-user private isolation | Reinforces least privilege and private-home-folder behavior |
| Web consumers | DNS and HTTPS hostname path | `c1-webserver.c1.local` and `c2-webserver.c2.local` | Standard web consumption | Hostname-based delivery prevents accidental raw-IP exposure |
| Backup operators | Veeam administrative path | `S2Veeam` console and offsite-copy workflows | Backup monitoring, repository review, and recovery operations | Recovery should be manageable without logging into every tenant server |

### Access Model Interpretation

This view improves the handover quality because it explains not only where services live, but which identities are meant to operate them.

It also keeps the report from collapsing into host-by-host description. By tying actors, identity sources, access paths, and control rationale together, the document can explain why the environment behaves as a managed service site rather than as a loose collection of machines.

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

For a handover document, that distinction is critical because it determines which mechanism would be used under different failure conditions. A sync issue, a share-permission issue, a mounted-volume issue, and a repository or offsite-copy issue all belong to different layers even if they are all loosely described as data problems.

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
| Confirm `C2FS` iSCSI session and mount remain present | Storage issues can break both file access and service availability |
| Review `c2_site1_sync.log` | Cross-site synchronization is part of the Site 2 narrative |
| Confirm `S2Veeam` control ports and last repository/offsite state | Backup readiness depends on stable control and copy paths |
| Confirm Company 1 and Company 2 hostnames still return `200`, while raw IPs return `404` | Reinforces hostname-based publishing and catches unexpected web-path regressions |
| Maintain an up-to-date evidence set for OPNsense, storage, and Veeam | Keeps the handover package ready for audit and operational review |

These checks are presented in control-plane order rather than as a general administrator checklist. The intention is to make the most consequential service questions visible first: can operators enter, can the network still carry intended paths, can names still resolve, can storage still present data, and can recovery still be trusted.

Routine maintenance is therefore not described as generic system housekeeping. It is described as the sequence of checks that preserves the service contract of the site: administrative entry, intended network paths, accurate naming, stable file presentation, and trusted recovery. That framing keeps day-to-day operations aligned with the same architectural logic used throughout the rest of the document.

## 3.13 Troubleshooting and Fast Triage Guide

### Fast Triage Principles

Table 19 summarizes the primary fault domains and first-line checks for common service symptoms.

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

The triage table is useful because it keeps fault isolation aligned to the actual architecture. It starts from the service symptom, points to the first authoritative system to inspect, and ties that symptom back to the most likely failure domain instead of encouraging broad, unfocused checking.

## 3.14 Integrated Design Summary

**Table 20. Integrated design summary**

| Perspective | Summary | Supporting Basis |
|---|---|---|
| Project delivery | Management, tenant service delivery, storage, and protection workflows are represented across the environment | Design inputs, inventory evidence, current observations, and requirement traceability |
| Network engineering | Segmentation, bounded entry, inter-site routing, and service-specific policy behavior are consistent across the environment | OPNsense configuration evidence, NAT mappings, interface definitions, aliases, route logic, and current reachability checks |
| Systems administration | Identity, client access, file services, storage transport, and backup paths are aligned with the documented operating model | Samba AD and DHCP state, DNS records, client access, `C2FS` storage checks, and `S2Veeam` port reachability |

The purpose of this closing summary is not to replace the detailed sections above, but to show that those sections resolve into one consistent operating story. The site can be defended from project, network, and systems perspectives without changing the underlying narrative.

Just as importantly, the design remains explainable at different depths. A stakeholder can read it as a management and service-delivery model, a network engineer can read it as segmented routing and policy, and a systems administrator can read it as identity, storage, web, and protection stacks. The same environment supports all three readings without contradiction.

# 4. Conclusion

When the design inputs, environment evidence, official technical references, and current operating observations are read together, Site 2 is best understood as a complete operating environment supporting Company 1, Company 2, and MSP services together.

Site 2 currently shows strong evidence for:

- controlled entry through bastion hosts and tightly limited edge exposure
- deliberate OPNsense segmentation across MSP, Company 1, Company 2, DMZ, and inter-site paths
- Company 1 services including directory, file, web, client, and SAN roles
- healthy Company 2 identity, DNS, and DHCP services
- isolated SAN-backed storage with live iSCSI consumption and synchronized file services
- hostname-based SMB access from `C2LinuxClient` to `c2fs.c2.local`, including public-share write validation and private-share isolation
- two-client access confirming that both required web hostnames work from both company perspectives
- a stable Linux VM hardware baseline in which controller, file-service, client, and web nodes each reflect their documented service roles
- Veeam-based backup design with a dedicated Site 2 repository, file-share backup scope, and Site 1 offsite-copy handling
- explicit requirement traceability and troubleshooting context that make the environment easier to hand over and defend

The broader significance of those results is that the environment reads coherently from end to end. Management entry, network boundaries, identity and naming, storage presentation, client-visible service delivery, and recovery posture all reinforce one another rather than competing with one another. That is why the document can be expanded with more narrative explanation without changing its technical conclusions.

Taken as a whole, Site 2 is defined less by any single tenant than by the way its management, identity, storage, web, and recovery layers operate together. That integrated behavior is the correct basis for the final technical narrative.

The final design is also now explainable at the level of rationale, not only at the level of inventory. The report identifies why control is centralized on the MSP boundary, why the tenant service layers remain distinct, why Company 1 and Company 2 can use different internal technology patterns without losing coherence, why storage is kept beneath file presentation, and why recovery remains administratively separate from live workload operation. That is the threshold a formal handover document should meet.

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
| `C1UbuntuClient` | `172.30.65.36` |
| `C1WebServer` | `172.30.65.162` |
| `C2IdM1` | `172.30.65.66` |
| `C2IdM2` | `172.30.65.67` |
| `C2FS` | `172.30.65.68` |
| `C2LinuxClient` | `172.30.65.70` |
| `C2WebServer` | `172.30.65.170` |
| `C2FS` storage-side interface | `172.30.65.195/29` |
| `C1SAN` | `172.30.65.186/29`, gateway `172.30.65.185` |
| `C2SAN` | `172.30.65.194/29`, gateway `172.30.65.193` |
| Company 1 web DNS records | `172.30.64.162`, `172.30.65.162` |
| Company 2 web DNS records | `172.30.64.170`, `172.30.65.170` |
| `C2LinuxClient` DNS servers | `172.30.65.66`, `172.30.65.67` |
| `C2LinuxClient` search domains | `c1.local`, `c2.local` |
| WAN NAT to `Jump64` | `33464 -> 172.30.65.178:3389` |
| WAN NAT to `MSPUbuntuJump` | `33564 -> 172.30.65.179:22` |
| Site 1 Veeam alias from OPNsense | `192.168.64.20` |

## Appendix B. Evidence and Reference Traceability

**Table B1. Evidence and reference traceability**

| Report Area | Primary Basis |
|---|---|
| Environment scope and service model | Internal service requirements, logical inventory record, and current operating observations |
| MSP entry, segmentation, and routing | OPNsense configuration evidence plus official OPNsense firewall, NAT, and OpenVPN documentation |
| Company 1 and Company 2 identity model | Samba AD documentation, namespace evidence, and current operating observations |
| File services and share presentation | Ubuntu Server Samba documentation plus `C2FS` service-state evidence |
| Isolated SAN and iSCSI transport | Ubuntu Server iSCSI documentation, SAN addressing evidence, and `C2FS` session state |
| Internal web publication | Microsoft IIS binding documentation plus hostname and raw-IP observations |
| Backup and offsite protection | Veeam documentation, OPNsense route or rule evidence, and internal backup-design records |
| Troubleshooting and operational guidance | Current operating observations, current environment evidence, and observed dependency relationships |

## Appendix C. Service Verification Matrix

**Table C1. Service verification and assurance matrix**

| Service or Control Area | Review Method | Evidence Summary | Assurance Level |
|---|---|---|---|
| Administrative entry and bastion access | Controlled remote-access verification and jump-host reachability checks | Both jump systems were reachable and remained the intended administrative entry points | High |
| Segmented networking and limited edge exposure | OPNsense configuration review plus management-path checks | Interfaces, aliases, NAT publication limits, and service-specific rules were all evidenced | High |
| Company 1 services | MSP-bastion reachability checks, hostname review, DNS visibility, and client access checks | Company 1 directory, file, web, client, and SAN roles were all visible in the current operating state | High |
| Company 2 identity, DNS, and DHCP | Service-state checks and DNS queries on `C2IdM1` and `C2IdM2` | Samba AD, DHCP, and required hostname records were all present and consistent | High |
| Dual-hostname web delivery | Client-side and bastion-side HTTPS checks by hostname and by raw IP | Both required hostnames returned successful responses while raw IP access reflected hardened behavior | High |
| File services and share isolation | `C2FS` service checks, mount review, `testparm`, sync-log review, and hostname-based SMB validation | SMB service state, mounted storage, public/private shares, successful synchronization, and named share access were all evidenced | High |
| Isolated SAN transport | SAN addressing evidence plus iSCSI session review on `C2FS` | Storage transport was evidenced as isolated from tenant LAN segments and correctly consumed by the file-service layer | High |
| Backup and offsite protection | Veeam host reachability, repository evidence, job inventory, copy-job inventory, route or rule review, and backup-design evidence | Protection architecture, local backup handling, file-share backup scope, and offsite-copy design were consistent with the documented operating model | High |
| Shared-forest interpretation | DNS visibility, client behavior, and confirmed namespace relationship | Cross-domain naming behavior is consistent with the documented forest relationship | Medium-High |
| Administrative Linux SSH access | Administrative-path testing within the documented operating scope | Managed SSH access paths aligned with the documented operating scope | Medium |

# 6. References

[1] OPNsense Documentation, "Rules," [https://docs.opnsense.org/manual/firewall.html](https://docs.opnsense.org/manual/firewall.html), accessed Mar. 24, 2026.

[2] OPNsense Documentation, "Network Address Translation," [https://docs.opnsense.org/manual/nat.html](https://docs.opnsense.org/manual/nat.html), accessed Mar. 24, 2026.

[3] OPNsense Documentation, "Setup SSL VPN Road Warrior," [https://docs.opnsense.org/manual/how-tos/sslvpn_client.html](https://docs.opnsense.org/manual/how-tos/sslvpn_client.html), accessed Mar. 24, 2026.

[4] SambaWiki, "Setting up Samba as an Active Directory Domain Controller," [https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller](https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller), accessed Mar. 24, 2026.

[5] Ubuntu Server Documentation, "Set up Samba as a file server," [https://documentation.ubuntu.com/server/how-to/samba/file-server/](https://documentation.ubuntu.com/server/how-to/samba/file-server/), accessed Mar. 24, 2026.

[6] Ubuntu Server Documentation, "iSCSI initiator (or client)," [https://documentation.ubuntu.com/server/how-to/storage/iscsi-initiator-or-client/](https://documentation.ubuntu.com/server/how-to/storage/iscsi-initiator-or-client/), accessed Mar. 24, 2026.

[7] Microsoft Learn, "binding Element for bindings for site for sites [IIS Settings Schema]," [https://learn.microsoft.com/en-us/previous-versions/iis/settings-schema/ms691267(v=vs.90)](https://learn.microsoft.com/en-us/previous-versions/iis/settings-schema/ms691267%28v%3Dvs.90%29), accessed Mar. 24, 2026.

[8] Veeam Help Center, "Configuring Backup Repositories," [https://helpcenter.veeam.com/docs/vbr/userguide/sch_configure_repository.html](https://helpcenter.veeam.com/docs/vbr/userguide/sch_configure_repository.html), accessed Mar. 24, 2026.

[9] Site 2 gateway configuration record, Mar. 23, 2026.

[10] Site 2 environment inventory, SAN addressing record, and namespace design record, Mar. 24, 2026.

[11] Site 2 operating-state review record, Mar. 23-24, 2026.

