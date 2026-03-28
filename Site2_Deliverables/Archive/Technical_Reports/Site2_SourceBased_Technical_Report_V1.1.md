---
title: "Public Cloud Infrastructure Deployment"
subtitle: "Source-Based Technical Report for Site 2"
author:
  - "Bailey Kulla"
  - "Elyazid Sidelkheir"
  - "Ru Wang"
  - "Justin Rosseleve"
  - "Yiqin Huang"
  - "Omer Deniz"
date: "March 23, 2026"
toc: true
toc-title: "Contents"
---

# Public Cloud Infrastructure Deployment

## CST8248 - Emerging Technologies Technical Report

**Design, Validation, and Handover Narrative for the Site 2 Environment Supporting Company 1, Company 2, and MSP Demo Operations**

| Field | Value |
|---|---|
| Course | CST8248 - Emerging Technologies |
| Professor | Denis Latremouille |
| Team Name | Raspberry Pioneers |
| Submission Type | Group Submission |
| Due Date | March 30, 2026 |
| Program | Computer Systems Technology - Networking |
| Institution | Algonquin College |
| Document Version | 1.0 |
| Document Date | March 23, 2026 |
| Intended Audience | Client IT staff, MSP support teams, and Level 4 graduates assuming operations support |

**Team Members:** Bailey Kulla, Elyazid Sidelkheir, Ru Wang, Justin Rosseleve, Yiqin Huang, Omer Deniz

> Report intent: this document is written in a client/MSP handover style while preserving the formal technical report structure required by CST8248. It was rebuilt from the source documents supplied in the current request and from live read-only Site 2 validation, not from earlier Site 2 draft documentation.

\newpage

# List of Figures

**Figure 1.** Site 2 topology and service block alignment  
**Figure 2.** OPNsense management and routed-path proof  
**Figure 3.** `C2IdM1` Active Directory, DNS, and DHCP proof  
**Figure 4.** `C2IdM2` Active Directory, DNS, and DHCP proof  
**Figure 5.** Company 1 and Company 2 DNS records on the Company 2 identity nodes  
**Figure 6.** Company 1 cross-site presence on the Site 2 admin path  
**Figure 7.** `C2FS` iSCSI-backed storage and mount proof  
**Figure 8.** `C2FS` SMB share definitions and sync-log proof  
**Figure 9.** `C2LinuxClient` domain identity and name-resolution proof  
**Figure 10.** Company 1 internal web proof on the Site 2 path  
**Figure 11.** Company 2 internal web proof on the Site 2 path  
**Figure 12.** `S2Veeam` backup and recovery evidence  
**Figure 13.** Public cloud or browser-based external evidence for the Site 2 deliverable  

# List of Tables

**Table 1.** Source-document expectations mapped to Site 2  
**Table 2.** Site 2 observed systems and roles  
**Table 3.** Service block interpretation for Site 2  
**Table 4.** Approved live validation vantage points  
**Table 5.** Company 2 identity, DNS, and DHCP summary  
**Table 6.** Company 1 presence within the Site 2 demo scope  
**Table 7.** Storage and SAN summary  
**Table 8.** Internal web validation summary  
**Table 9.** Backup and recovery validation summary  
**Table 10.** Demo readiness and probable instructor scenarios  
**Table 11.** Operational maintenance checks  
**Table 12.** Current limitations and evidence gaps  
**Table A1.** Observed network addressing and endpoints  
**Table B1.** Source-to-section traceability  
**Table C1.** Screenshot and figure capture guide  

# Executive Summary

The source document set supplied for this project makes two points clear. First, Site 2 is not a Company 2-only environment. The term project PDF places Site 2 in the public-cloud role for the MSP, the Service Blocks handout distributes both Company 1 and Company 2 responsibilities across multiple demo hotseats, and the Site 1 final report demonstrates that the final submission must explain cross-site behavior rather than treating each site as an isolated island. Second, the final report is expected to read like a handover document for support staff, not like a short build log.

Based on those source expectations, a fresh read-only validation of Site 2 was performed from the local workstation, the approved Ubuntu jump path, and direct read-only SSH to Company 2 Linux systems. That validation confirmed that Site 2 currently supports three major operational roles:

- Company 2 core services including identity, DNS, DHCP, Linux client authentication, file services, and synchronized storage
- Company 1 cross-site and mirrored demo services including Company 1 DNS presence on Company 2 identity servers, Company 1 internal web reachability on the Site 2 path, and cross-site administrative access to Company 1 systems
- MSP operational workflows including bastion-based management, OPNsense validation, Veeam control-path reachability, and demo-oriented service block testing

The most important technical findings are:

- `C2IdM1` and `C2IdM2` were both healthy for Samba AD and DHCP, and both held the expected dual A records for Company 1 and Company 2 internal web names
- `C2LinuxClient` successfully resolved `c1-webserver.c1.local` and `c2-webserver.c2.local` and returned valid domain-user identities for `employee1@c2.local` and `employee2@c2.local`
- `C2FS` showed a live iSCSI session to `172.30.65.194:3260`, a mounted Company 2 data volume at `/mnt/c2_public`, valid `C2_Public` and `C2_Private` share definitions, and successful Site 1 to Site 2 synchronization in the latest log
- Company 1 and Company 2 internal web validation both followed the same hardened pattern on the Site 2 path: hostname-based requests returned `200`, while raw IP requests returned `404`
- `S2Veeam` responded on `445`, `3389`, `9392`, `5985`, `10005`, and `10006` from the approved Site 2 admin path

One limitation remained outside the core internal path: current CLI-based external DNS tests could not resolve `clearroots.omerdengiz.com`. Because the project brief still positions Site 2 as the public-cloud site, this report leaves a specific placeholder for browser- and console-based external evidence rather than overstating what the current CLI probe could prove.

# 1. Introduction

The purpose of this document is to describe Site 2 in a form that supports academic submission, operational handover, and live demo execution. This report does not assume that Site 2 exists only for Company 2. Instead, it treats Site 2 as the public-cloud and cross-site side of the project, where MSP management, Company 2 service delivery, Company 1 mirrored or cross-site demo paths, and backup-related operations all intersect.

The report was written using the same broad structure demonstrated in the provided Site 1 final document:

- title page and table of contents
- executive summary, introduction, background, discussion, and conclusion
- appendices and references
- explicit lists of figures and tables

That structure matters because the week 9 technical report slides explicitly require a handover-oriented tone, explanations of services and how they connect, specifications and rationale, service stacking discussion, and platform-choice rationale.

# 2. Background

## 2.1 Project expectations from the supplied source set

The supplied source set establishes the expectations for Site 2 very clearly.

The term project PDF defines Site 2 as the location for the MSP public-cloud equipment and requires the MSP to provide service to both Company 1 and Company 2. It also requires separate isolated networks, secure site-to-site connectivity, remote access for all machines, storage through SMB or NFS plus iSCSI, offsite backup, jump servers, Veeam-based protection, and best-practice deployment for the company services.

The Service Blocks handout gives the practical demo model for the environment. It distributes responsibility across five service blocks and shows that both Company 1 and Company 2 remain visible in the final hotseat structure. That is the most direct evidence that Site 2 must be documented as part of a larger multi-company demonstration flow rather than as a single-tenant lab island.

The week 3 to week 7 notes add the instructor's operating philosophy:

- jump boxes are bastion hosts and should be the trusted management path
- documentation should explain how services are kept reachable during demo and support operations
- iSCSI is a required part of the storage story and should be shown over a dedicated or intentional path
- Veeam and storage are not just build items; they are demo-week validation targets
- the technical report should onboard another team member and be interesting enough to read

Finally, the provided Site 1 test workbook and Site 1 final report establish the expected evidence density. The Site 1 materials use structured test rows, expected results, figure captions, tables, and operations-oriented prose. This Site 2 report intentionally follows that example.

### Table 1. Source-document expectations mapped to Site 2

| Source | What It Establishes | Site 2 Implication |
|---|---|---|
| `25F-Project (1).pdf` | Site 2 is the MSP public-cloud site; both companies must be serviced; remote access, storage, backup, and secure connectivity are mandatory | Site 2 must be documented as multi-role, not Company 2-only |
| `09 - CST8248 – Emerging Technologies (2).pdf` | Technical report must use a handover tone and include formal sections, rationale, and operations context | Site 2 report must explain not only what exists, but why it matters |
| `ServiceBlocks.pdf` | Demo is organized into service blocks shared across Company 1, Company 2, and MSP roles | Site 2 testing must include Company 1 and MSP paths |
| `Site1_Final_Documentation_V3.0.docx` | Final report style, depth, and sectioning expected by the course | Site 2 should mirror the same professional structure |
| `Site1_test_V0.1.xlsx` | Practical test-document format using phased tests and expected results | Site 2 test package should be matrix-driven and demo-ready |
| Week 3-7 class notes | Jump boxes, SAN, Veeam, demo-week timing, and handover writing approach | Site 2 report must emphasize bastion access, storage, backup, and fast demo proof |

## 2.2 Source-based method used for this report

This report was intentionally rebuilt using only:

- the source documents named in the current request
- live read-only Site 2 validation performed on March 23, 2026
- internal observations directly gathered from the approved bastion path during that validation

Earlier Site 2 draft documents were not used as source content for this version. This matters because the user explicitly requested a fresh report that respects the supplied project brief, the Service Blocks model, the instructor's notes, and the actual observed Site 2 state.

## 2.3 Live validation method

The live validation approach followed the jump-host philosophy described in the class notes. The Ubuntu jump was treated as the authoritative bastion because the notes explicitly describe jump boxes as the management platform that should reduce exposed edge ports and centralize control. A smaller set of local workstation tests was also used to check current teacher-edge or Tailscale reachability.

### Table 2. Site 2 observed systems and roles

| System / Endpoint | Observed Role |
|---|---|
| `100.97.37.83` | Windows jump / GUI-oriented bastion path |
| `100.82.97.92` | Ubuntu jump / preferred CLI bastion path |
| `172.30.65.177` | OPNsense management and routing point |
| `172.30.65.66` | `C2IdM1` Company 2 identity, DNS, DHCP |
| `172.30.65.67` | `C2IdM2` Company 2 identity, DNS, DHCP |
| `172.30.65.68` | `C2FS` Company 2 file service, SMB, synchronized storage |
| `172.30.65.70` | `C2LinuxClient` Company 2 Linux client |
| `172.30.65.162` | Company 1 internal web presence on the Site 2 path |
| `172.30.65.170` | Company 2 internal web presence on the Site 2 path |
| `172.30.65.180` | `S2Veeam` backup and recovery host |

### Table 3. Service block interpretation for Site 2

| Service Block | Source-Handout Focus | Site 2 Interpretation |
|---|---|---|
| 1 | Remote Access, DHCP, Account Administration | Jump paths plus Company 2 identity and client onboarding |
| 2 | DNS, HTTPS | Company 1 and Company 2 internal web names, DNS records, and hostname behavior |
| 3 | Site 1 Hypervisor, vRouter | Cross-site reachability and routing through the Site 2 bastion path |
| 4 | Replicated File Server, iSCSI | `C2FS` storage, SAN evidence, SMB shares, and synchronization |
| 5 | VEEAM, Misc | `S2Veeam`, demo support evidence, and remaining GUI-only proof points |

### Table 4. Approved live validation vantage points

| Vantage Point | Why It Was Used |
|---|---|
| Local workstation | To verify Tailscale and teacher-edge reachability into Site 2 |
| Ubuntu jump | To perform low-risk, repeatable CLI checks inside Site 2 |
| Direct SSH to Company 2 Linux systems | To confirm service state without changing configuration |
| Browser or console placeholders | To reserve final figure locations for GUI-only demo evidence |

# 3. Discussion

## 3.1 Environment Overview and Topology

The source documents imply a layered Site 2 story rather than a single-purpose deployment. Site 2 must support MSP access, Company 2 tenant services, Company 1 cross-site or mirrored demo paths, backup operations, and public-cloud expectations.

The live validation reinforces that interpretation. Company 2 is clearly present through the identity nodes, Linux client, file server, and internal Company 2 web presence. Company 1 is also clearly present through the Company 1 DNS records stored on the Company 2 identity servers, the Company 1 internal web service reachable on the Site 2 path, and the cross-site reachability from Site 2 to Company 1 systems such as `C1DC1`, `C1DC2`, `C1FS`, and `C1LinuxClient`.

That is why Site 2 should be presented as a cross-site service-delivery and demo site rather than a Company 2-only site.

**Figure 1. Site 2 topology and service block alignment.**  
Description: Insert a topology or diagram view showing MSP jump paths, OPNsense, Company 2 core systems, Company 1 mirrored or cross-site paths, `S2Veeam`, and the Service Block mapping.  

| Figure 1 Placeholder |
|---|
| Insert the Site 2 topology or service-block diagram here before final submission. |
|  |
|  |
|  |

## 3.2 Network Design, Remote Access, and Security Rationale

The week 3 notes describe the jump box as a bastion host and explicitly warn against exposing many management ports at the edge. That concept fits the observed Site 2 design well. The cleanest current management path is not arbitrary direct access to every server. It is controlled entry through the jump systems and then targeted validation from inside the approved management network.

The live results supported this model:

- Tailscale RDP to the Windows jump was reachable
- Tailscale SSH to the Ubuntu jump was reachable
- teacher-edge access to the Windows and Ubuntu jumps was reachable
- OPNsense management returned `HTTP 403` instead of exposing an anonymous dashboard
- OPNsense TCP `53` was reachable, showing the management plane was present

This is a strong operational design for demo week because it lets the team open the right consoles in advance and then move quickly to the required proof points.

**Figure 2. OPNsense management and routed-path proof.**  
Description: Insert the OPNsense management page, route-status view, or firewall/rule screen that shows how the Site 2 management and cross-site path is controlled.  

| Figure 2 Placeholder |
|---|
| Insert the OPNsense management or route evidence here before final submission. |
|  |
|  |
|  |

## 3.3 Company 2 Identity, DNS, and DHCP Services

Company 2 identity services are one of the clearest fully validated parts of Site 2. Read-only checks on `C2IdM1` and `C2IdM2` showed:

- `samba-ad-dc` active on both nodes
- `isc-dhcp-server` active on both nodes
- valid DNS records for both Company 1 and Company 2 internal web services on both nodes

This directly satisfies multiple parts of the project brief. Company 2 requires Active Directory or LDAP, local and recursive DNS, and fault-tolerant DHCP. The live environment demonstrates that those services were not only built, but also remain queryable and usable from the current bastion path.

### Table 5. Company 2 identity, DNS, and DHCP summary

| Validation Item | `C2IdM1` | `C2IdM2` |
|---|---|---|
| Samba AD service state | Active | Active |
| DHCP service state | Active | Active |
| `c1-webserver.c1.local` A records | `172.30.64.162`, `172.30.65.162` | `172.30.64.162`, `172.30.65.162` |
| `c2-webserver.c2.local` A records | `172.30.64.170`, `172.30.65.170` | `172.30.64.170`, `172.30.65.170` |

The presence of Company 1 records on the Company 2 identity servers is especially important. It shows that Site 2 was designed to support the cross-site internal web demo rather than keeping each company's internal namespace completely isolated from the demo path.

**Figure 3. `C2IdM1` Active Directory, DNS, and DHCP proof.**  
Description: Insert a screenshot from `C2IdM1` showing active Samba AD, active DHCP, and the relevant DNS query output.  

| Figure 3 Placeholder |
|---|
| Insert the `C2IdM1` AD/DNS/DHCP evidence here before final submission. |
|  |
|  |
|  |

**Figure 4. `C2IdM2` Active Directory, DNS, and DHCP proof.**  
Description: Insert a screenshot from `C2IdM2` showing active Samba AD, active DHCP, and the relevant DNS query output.  

| Figure 4 Placeholder |
|---|
| Insert the `C2IdM2` AD/DNS/DHCP evidence here before final submission. |
|  |
|  |
|  |

**Figure 5. Company 1 and Company 2 DNS records on the Company 2 identity nodes.**  
Description: Insert a combined DNS proof showing dual A records for `c1-webserver.c1.local` and `c2-webserver.c2.local` from one or both Company 2 identity nodes.  

| Figure 5 Placeholder |
|---|
| Insert the Company 1 and Company 2 DNS record evidence here before final submission. |
|  |
|  |
|  |

## 3.4 Company 1 Presence Within the Site 2 Scope

The user correctly pointed out that Site 2 is not limited to Company 2. The source and live evidence both support that.

From the supplied source set:

- the Service Blocks matrix assigns Company 1 and Company 2 responsibilities across the Site 2 demo model
- the term project defines Site 2 as the MSP public-cloud site rather than a single-company tenant segment
- the Site 1 final report structure expects Company 1, Company 2, and cross-site behavior to be documented together

From the live validation:

- Company 1 records existed on both Company 2 identity nodes
- `c1-webserver.c1.local` was reachable from the Site 2 admin path
- cross-site connectivity from the Ubuntu jump to `C1DC1`, `C1DC2`, `C1FS`, and `C1LinuxClient` was healthy

### Table 6. Company 1 presence within the Site 2 demo scope

| Observed Company 1 Element | Evidence |
|---|---|
| Company 1 DNS on Company 2 identity services | `c1-webserver.c1.local` dual A records on both `C2IdM1` and `C2IdM2` |
| Company 1 internal web on the Site 2 path | Hostname-based HTTPS to `172.30.65.162` returned `200`; raw IP returned `404` |
| Company 1 administrative reachability from Site 2 | `C1DC1`, `C1DC2`, `C1FS`, and `C1LinuxClient` ports reachable from the Ubuntu jump |

This section matters because it corrects the common misunderstanding that Site 2 should be documented as if Company 1 disappears there. In the actual demo logic, Company 1 remains part of the Site 2 narrative.

**Figure 6. Company 1 cross-site presence on the Site 2 admin path.**  
Description: Insert a screenshot showing Company 1 reachability from the Site 2 admin path, such as cross-site port checks or the Company 1 internal web path.  

| Figure 6 Placeholder |
|---|
| Insert the Company 1 cross-site evidence here before final submission. |
|  |
|  |
|  |

## 3.5 Storage, File Services, and SAN Evidence

The week 4 and week 7 notes make storage and iSCSI explicit demo-week concerns. That expectation is satisfied strongly by the current `C2FS` state.

Read-only inspection of `C2FS` showed:

- `smbd` active
- `/mnt/c2_public` mounted from `/dev/sdb`
- an active iSCSI session to `172.30.65.194:3260` with target `iqn.2024-03.org.clearroots:c2san`
- `C2_Public` and `C2_Private` share definitions in the Samba configuration
- successful Site 1 to Site 2 synchronization in the latest log

This is one of the best examples of how the source expectations, live design, and demo proof all line up. The project brief requires fault-tolerant or replicated file service, access control, iSCSI target and initiator, and cross-site connectivity. The current `C2FS` inspection shows exactly those elements converging in a supportable design.

### Table 7. Storage and SAN summary

| Item | Observed State |
|---|---|
| Mounted data path | `/mnt/c2_public` |
| Mounted device | `/dev/sdb` |
| Transport | `iscsi` |
| Active iSCSI session | `172.30.65.194:3260`, target `iqn.2024-03.org.clearroots:c2san` |
| Public share definition | `[C2_Public] -> /mnt/c2_public/Public` |
| Private share definition | `[C2_Private] -> /mnt/c2_public/Private/%U` |
| Latest sync result | `Sync completed successfully` in the current log |

**Figure 7. `C2FS` iSCSI-backed storage and mount proof.**  
Description: Insert a screenshot showing the active iSCSI session and the mounted `/mnt/c2_public` storage.  

| Figure 7 Placeholder |
|---|
| Insert the `C2FS` iSCSI and mount evidence here before final submission. |
|  |
|  |
|  |

**Figure 8. `C2FS` SMB share definitions and sync-log proof.**  
Description: Insert a screenshot showing the `C2_Public` and `C2_Private` share definitions and the successful sync-log tail.  

| Figure 8 Placeholder |
|---|
| Insert the `C2FS` share-definition and sync-log evidence here before final submission. |
|  |
|  |
|  |

## 3.6 Company 2 Client Access and User Validation

`C2LinuxClient` is the best end-user proof point currently available in the read-only path. It showed:

- valid realm membership in `C2.LOCAL`
- valid `getent passwd` results for `employee1@c2.local` and `employee2@c2.local`
- correct name resolution for Company 1 and Company 2 internal web names

That is important because the Site 1 test workbook does not stop at service-state checks. It expects actual client-side outcomes. In the same spirit, Site 2 should not claim that identity is healthy merely because a domain controller service is running. The client-side identity lookup must work too, and in the current environment it does.

One limitation remains: no persistent CIFS or NFS mount entries were visible in the current non-interactive `C2LinuxClient` context. That does not disprove file access, but it means the final package still benefits from one interactive screenshot showing the mounted or accessed company shares under a user session.

**Figure 9. `C2LinuxClient` domain identity and name-resolution proof.**  
Description: Insert a screenshot showing `realm list`, successful domain-user lookup, and `nslookup` results for the Company 1 and Company 2 internal web names.  

| Figure 9 Placeholder |
|---|
| Insert the `C2LinuxClient` identity and DNS evidence here before final submission. |
|  |
|  |
|  |

## 3.7 Internal Web Services and Hostname-Based Hardening

Internal web validation is one of the most demo-relevant parts of Site 2 because it shows that Company 1 and Company 2 are both represented in the same environment. The current behavior was consistent for both services:

- Company 1 hostname on the Site 2 path returned `HTTP 200`
- Company 1 raw IP on the Site 2 path returned `HTTP 404`
- Company 2 hostname on the Site 2 path returned `HTTP 200`
- Company 2 raw IP on the Site 2 path returned `HTTP 404`

This is strong evidence of intentional hostname-based publishing rather than accidental flat web exposure. It also means the demo team should always use the expected tenant hostname, not a raw IP, when presenting internal web services.

### Table 8. Internal web validation summary

| Validation | Observed Result |
|---|---|
| `https://c1-webserver.c1.local` pinned to `172.30.65.162` | `HTTP/2 200` |
| `https://172.30.65.162` | `HTTP/2 404` |
| `https://c2-webserver.c2.local` pinned to `172.30.65.170` | `HTTP/1.1 200 OK` |
| `https://172.30.65.170` | `HTTP/1.1 404 Not Found` |

**Figure 10. Company 1 internal web proof on the Site 2 path.**  
Description: Insert a screenshot showing the Company 1 hostname-based success and raw-IP `404` behavior on the Site 2 path.  

| Figure 10 Placeholder |
|---|
| Insert the Company 1 internal web evidence here before final submission. |
|  |
|  |
|  |

**Figure 11. Company 2 internal web proof on the Site 2 path.**  
Description: Insert a screenshot showing the Company 2 hostname-based success and raw-IP `404` behavior on the Site 2 path.  

| Figure 11 Placeholder |
|---|
| Insert the Company 2 internal web evidence here before final submission. |
|  |
|  |
|  |

## 3.8 Backup, Recovery, and Veeam Readiness

The project brief requires Veeam-based VM, file-share, and client protection plus offsite storage for backups. The Service Blocks model also reserves a full block for VEEAM and miscellaneous operational proof. In the live read-only pass, the strongest defensible evidence for `S2Veeam` was management-path reachability from the approved jump path.

The Ubuntu jump successfully reached:

- TCP `445`
- TCP `3389`
- TCP `9392`
- TCP `5985`
- TCP `10005`
- TCP `10006`

That is enough to state that the backup host is present and reachable on the expected control and management ports. It is not enough to over-claim specific job history without a GUI or console capture, so the final package should include a Veeam screenshot for full completeness.

### Table 9. Backup and recovery validation summary

| Check | Observed State |
|---|---|
| SMB reachability to `S2Veeam` | Reachable |
| RDP reachability to `S2Veeam` | Reachable |
| Veeam console/API path `9392` | Reachable |
| WinRM/management path `5985` | Reachable |
| Agent-control ports `10005` and `10006` | Reachable |

**Figure 12. `S2Veeam` backup and recovery evidence.**  
Description: Insert a screenshot from the Veeam console or server that shows the final job, repository, and recovery evidence needed for the demo.  

| Figure 12 Placeholder |
|---|
| Insert the Veeam console or repository evidence here before final submission. |
|  |
|  |
|  |

## 3.9 Public Cloud or External Publication Evidence

The project brief explicitly says that Site 2 houses the MSP public-cloud equipment. That means the final package should reserve space for external or browser-based public-cloud evidence when the team includes that deliverable in demo week.

However, the current read-only CLI evidence could not prove the public external name path. Local queries to `8.8.8.8` and `1.1.1.1` for `clearroots.omerdengiz.com` returned `Query refused`, and a direct local `curl` request could not resolve the hostname. Because the goal of this report is to be accurate, this section does not overstate the current CLI result.

The correct way to finish this section is with an external browser capture, cloud-console proof, or another screenshot-backed demonstration artifact prepared by the team.

**Figure 13. Public cloud or browser-based external evidence for the Site 2 deliverable.**  
Description: Insert a browser or cloud-console screenshot proving the public Site 2 deliverable that your team intends to show in the final demo.  

| Figure 13 Placeholder |
|---|
| Insert the public cloud or external browser evidence here before final submission. |
|  |
|  |
|  |

## 3.10 Demo Readiness and Probable Instructor Scenarios

The week 6 notes warn that demo week operates on a short timer and that important consoles should already be open on the jump box or other management systems. The best Site 2 demo therefore is not a random walk through servers. It is a prepared sequence aligned to the Service Blocks model.

### Table 10. Demo readiness and probable instructor scenarios

| Probable Scenario | Best Proof Path |
|---|---|
| Show how you enter Site 2 securely | Tailscale or teacher-edge access to the jump systems |
| Show that Company 2 identity is healthy | `C2IdM1` / `C2IdM2` service state plus DNS records |
| Show that Company 1 still exists in Site 2 scope | Company 1 DNS records on C2 identity servers and Company 1 internal web on the Site 2 path |
| Show storage and SAN | `C2FS` iSCSI session, mount, share definitions, and sync log |
| Show client authentication | `C2LinuxClient` domain-user lookups |
| Show internal tenant web services | Company 1 and Company 2 hostname-based HTTPS proof |
| Show backup readiness | `S2Veeam` ports plus Veeam console screenshot |
| Show public-cloud deliverable | Browser or console screenshot added to Figure 13 |

The practical takeaway is simple: keep the bastion path, web proof, storage proof, and backup proof ready in advance.

## 3.11 Maintenance and Daily Duties

The Site 1 final report includes maintenance and daily duties, and the week 9 technical report slides explicitly ask what maintenance or daily duties matter. Site 2 therefore needs an operations section as well.

### Table 11. Operational maintenance checks

| Daily or Routine Check | Why It Matters |
|---|---|
| Confirm bastion access to jump systems | Without the jump path, many healthy services become hard to prove |
| Confirm `samba-ad-dc` and `isc-dhcp-server` on `C2IdM1` and `C2IdM2` | Identity and DHCP are foundational for Company 2 |
| Confirm `C2LinuxClient` can still resolve tenant names and users | Prevents silent identity regressions |
| Confirm `C2FS` iSCSI session and mount remain present | Storage issues can break both file access and demo proof |
| Review `c2_site1_sync.log` | Cross-site synchronization is part of the Site 2 story |
| Confirm `S2Veeam` ports remain reachable from the approved admin path | Backup readiness depends on stable control paths |
| Confirm Company 1 and Company 2 internal web hostnames still return `200` | Prevents demo-day web surprises |

## 3.12 Limitations, Risks, and Remaining Evidence Gaps

This source-based report is intentionally accurate about what has and has not been fully proven by current read-only testing.

### Table 12. Current limitations and evidence gaps

| Item | Current State |
|---|---|
| Public-cloud external name proof | CLI DNS resolution did not succeed; requires screenshot-based evidence |
| Interactive client share proof | `C2LinuxClient` did not show persistent CIFS/NFS mounts in the non-interactive context; interactive screenshot recommended |
| Veeam console inventory | Port reachability proved; final console screenshot still recommended |
| Windows-jump WMI collector return path | Failed in the live toolkit; treated as tooling-path issue, not core service failure |

These are acceptable limits for a read-only validation pass. They do not erase the strong evidence already collected for identity, DNS, storage, internal web, cross-site behavior, and backup-host reachability. They simply identify where GUI or browser evidence should complete the final submission package.

# 4. Conclusion

When the supplied source documents are read together, Site 2 must be documented as a multi-role environment supporting Company 1, Company 2, and MSP operations. The live validation agrees with that interpretation.

Site 2 currently shows strong evidence for:

- Company 2 identity, DNS, DHCP, client authentication, file service, and synchronized storage
- Company 1 cross-site presence through DNS records, mirrored internal web behavior, and administrative reachability
- MSP operations through bastion-based management, OPNsense validation, and backup-host control-path reachability

The most important correction to earlier assumptions is therefore conceptual rather than cosmetic: Site 2 is not Company 2-only. It is the public-cloud and cross-site side of the project, and the final report must say so clearly.

# 5. Appendices

## Appendix A. Observed Network Addressing

### Table A1. Observed network addressing and endpoints

| Host / Service | Address |
|---|---|
| Windows jump | `100.97.37.83` |
| Ubuntu jump | `100.82.97.92` |
| Teacher-edge Windows jump | `10.50.17.31:33464` |
| Teacher-edge Ubuntu jump | `10.50.17.31:33564` |
| Teacher-edge public web test port | `10.50.17.31:33465` |
| OPNsense | `172.30.65.177` |
| `C2IdM1` | `172.30.65.66` |
| `C2IdM2` | `172.30.65.67` |
| `C2FS` | `172.30.65.68` |
| `C2LinuxClient` | `172.30.65.70` |
| Company 1 internal web on Site 2 path | `172.30.65.162` |
| Company 2 internal web on Site 2 path | `172.30.65.170` |
| `S2Veeam` | `172.30.65.180` |
| Observed C2 SAN target | `172.30.65.194:3260` |

## Appendix B. Source-to-Section Traceability

### Table B1. Source-to-section traceability

| Report Area | Main Source Basis |
|---|---|
| Report structure | Week 9 technical report slides and Site 1 final report |
| Project scope | Term project PDF |
| Demo logic | Service Blocks PDF |
| Jump-host discussion | Week 3 notes |
| Storage and SAN emphasis | Week 4 and Week 7 notes |
| Backup emphasis | Week 5 notes |
| Demo timing and preparation | Week 6 notes |
| Live service state | March 23, 2026 read-only validation |

## Appendix C. Screenshot and Figure Capture Guide

### Table C1. Screenshot and figure capture guide

| Figure | What To Capture |
|---|---|
| Figure 1 | Final Site 2 topology or service block map |
| Figure 2 | OPNsense route, management, or rule evidence |
| Figure 3 | `C2IdM1` AD, DNS, and DHCP proof |
| Figure 4 | `C2IdM2` AD, DNS, and DHCP proof |
| Figure 5 | Company 1 and Company 2 DNS records on Company 2 identity services |
| Figure 6 | Company 1 cross-site reachability or internal web proof from Site 2 |
| Figure 7 | `C2FS` iSCSI session and mounted storage |
| Figure 8 | `C2FS` SMB share definitions and successful sync log |
| Figure 9 | `C2LinuxClient` realm and domain-user proof |
| Figure 10 | Company 1 hostname `200` and raw-IP `404` behavior |
| Figure 11 | Company 2 hostname `200` and raw-IP `404` behavior |
| Figure 12 | Veeam console, repository, or successful backup history |
| Figure 13 | External public-cloud or browser-based Site 2 proof |

# 6. References

[1] D. Latremouille, "CST8248 Term Project," course project brief, 2026.

[2] D. Latremouille, "Week 09 - Technical Report," course slide deck, 2026.

[3] D. Latremouille, "Service Blocks," course handout, 2026.

[4] D. Latremouille, week 3 course notes on jump hosts and remote access, 2026.

[5] D. Latremouille, week 4 course notes on storage area networking and iSCSI, 2026.

[6] D. Latremouille, week 5 course notes on Veeam backup concepts, 2026.

[7] D. Latremouille, week 6 course notes on technical report and demo preparation, 2026.

[8] D. Latremouille, week 7 course notes on iSCSI demo expectations and technical reporting, 2026.

[9] Raspberry Pioneers, "Site1 Final Documentation V3.0," internal project document, 2026.

[10] Raspberry Pioneers, "Site1 Test V0.1," internal test workbook, 2026.

[11] Raspberry Pioneers, "Site 2 read-only live validation logs," internal validation artifacts generated March 23, 2026.
