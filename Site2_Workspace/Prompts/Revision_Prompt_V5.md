# CODEX REVISION PROMPT — V4.4 → V4.5
## Complete fix list: formatting errors, missing table content, cross-scope gaps

---

## CONTEXT

V4.4 scores 93/100. The remaining 7 points come from three categories:
1. Formatting errors introduced during editing (broken bullet list, duplicate hostname, HTML comment artifacts)
2. Missing or empty table content (Appendix C body, TOC title mismatch)
3. Systematic gaps where Company 1 and MSP systems are absent from tables that document the whole site (Tables 15, 17, 18, 20, B1, and Section 3.6)

All fixes below use information already present in the document — no new live inspection is needed.

---

## CATEGORY 1 — FORMATTING ERRORS (fix first, these are most visible)

### FIX 1.1 — Section 3.7: Fix broken bullet list and duplicated hostname

**Location:** Section 3.7, "Client Validation Perspectives" subsection

**Problem:** The bullet list has orphaned HTML comment tags (`{=html}<!-- -->`) between items, making C2LinuxClient appear separated from the main list. Immediately after, the hostname list shows `https://c2-webserver.c2.local` twice — `https://c1-webserver.c1.local` is completely missing.

**Current broken state:**
```
Three different client perspectives were available:

-   C1UbuntuClient, identified in the environment evidence as the Company 1 Linux client role

-   C1WindowsClient, the Company 1 Windows client, observed from Jump64 through WMI and controlled remote process execution

{=html}<!-- -->
-   C2LinuxClient, the Company 2 Linux client

{=html}<!-- -->
-   All three client perspectives were able to resolve...

{=html}<!-- -->
-   https://c2-webserver.c2.local

{=html}<!-- -->
-   https://c2-webserver.c2.local
```

**Fix — replace the entire block with:**
```
Three different client perspectives were available:

-   C1UbuntuClient, identified in the environment evidence as the Company 1 Linux client role
-   C1WindowsClient, the Company 1 Windows client, observed from Jump64 through WMI and controlled remote process execution
-   C2LinuxClient, the Company 2 Linux client

All three client perspectives were able to resolve and consume the required internal web hostnames through name-based access. C1UbuntuClient and C2LinuxClient did so directly from their own shells. C1WindowsClient did so through a Jump64-managed client-side probe because WinRM on the client itself was not available:

-   https://c1-webserver.c1.local
-   https://c2-webserver.c2.local
```

Remove all `{=html}<!-- -->` comment artifacts from this section. They are Word-to-Markdown conversion artifacts and should not appear in the final document.

---

### FIX 1.2 — TOC / List of Tables: Update Table 5A title to match body

**Location:** List of Tables (near top of document)

**Problem:** The List of Tables entry reads:
> "Table 5A. Observed Linux VM platform baseline .... 14"

But the actual table in the document body is titled:
> "Table 5A. Observed Linux node platform baseline — all service scopes"

**Fix:** Update the List of Tables entry to:
> "Table 5A. Observed Linux node platform baseline — all service scopes .... 14"

---

### FIX 1.3 — Appendix C: Restore missing table body

**Location:** Appendix C, after "Table C1. Service verification and assurance matrix"

**Problem:** The section heading and table caption exist but the table body is completely absent. The table was present in V4.2 and appears to have been lost during editing.

**Fix:** Restore the full Table C1 body. The content below matches the table that was present in V4.2 and aligns with the V4.4 evidence state. Update the Company 1 row to reflect V4.4 Jump64 findings:

| Service or Control Area | Review Method | Evidence Summary | Assurance Level |
|---|---|---|---|
| Administrative entry and bastion access | Controlled remote-access verification and jump-host reachability checks | Both jump systems were reachable and remained the intended administrative entry points | High |
| Segmented networking and limited edge exposure | OPNsense configuration review plus management-path checks | Interfaces, aliases, NAT publication limits, and service-specific rules were all evidenced | High |
| Company 1 services | MSP-bastion checks, Jump64 remoting or WMI inspection, hostname review, DNS visibility, and client access checks | Company 1 directory, file, web, client, and SAN roles were all revalidated, with direct Windows-side observation from Jump64 now covering the previously thin areas | High |
| Company 2 identity, DNS, and DHCP | Service-state checks and DNS queries on C2IdM1 and C2IdM2 | Samba AD, DHCP, and required hostname records were all present and consistent | High |
| Dual-hostname web delivery | Client-side and bastion-side HTTPS checks by hostname and by raw IP | Both required hostnames returned successful responses while raw IP access reflected hardened behavior | High |
| File services and share isolation | C2FS service checks, mount review, testparm, sync-log review, and hostname-based SMB validation; C1FS inspected via Jump64 WinRM | SMB service state, mounted storage, shares, synchronization, and named share access confirmed for C2FS; F: SharedData volume, named shares, and active iSCSI session confirmed for C1FS | High |
| Isolated SAN transport | SAN addressing evidence plus iSCSI session review on C2FS and C1FS | Storage transport confirmed as isolated from tenant LAN segments and correctly consumed by both file-service layers | High |
| Backup and offsite protection | Veeam host reachability, Jump64 administrative session, repository evidence, job inventory, copy-job inventory, route or rule review, and backup-design evidence | Protection architecture, local backup handling, file-share backup scope, offsite-copy design, and Windows administrative access to S2Veeam were all consistent with the documented operating model | High |
| Shared-forest interpretation | DNS visibility, client behavior, and confirmed namespace relationship | Cross-domain naming behavior is consistent with the documented forest relationship | Medium-High |
| Administrative Linux SSH access | Administrative-path testing within the documented operating scope | Managed SSH access paths aligned with the documented operating scope | Medium |

---

## CATEGORY 2 — TABLE CONTENT GAPS

### FIX 2.1 — Table 15: Add Company 1 file and storage to the failure domain view

**Location:** Table 15 "Service dependency and failure-domain view" in Section 3.10

**Problem:** The "File and storage" row lists only C2 components (C2FS, C2SAN, iSCSI session). Now that C1FS storage was directly observed in V4.2/V4.4, the Company 1 file and storage chain also has a defined failure domain with known triage steps.

**Fix:** Rename the existing "File and storage" row to "Company 2 file and storage" and add a new parallel row for Company 1:

New row to add after the existing "File and storage" row:

| Service Plane | Primary Components | Downstream Dependencies | Main Failure Symptom | Fastest Health Check |
|---|---|---|---|---|
| Company 1 file and storage | C1FS, C1SAN, iSCSI session, SMB share configuration | Company 1 share access and file-service availability | Shares unavailable or C1FS iSCSI session gone | Jump64 WinRM to C1FS: Get-SmbShare, Get-IscsiSession, Get-Volume |

---

### FIX 2.2 — Table 17: Add Company 1 SMB share data flows

**Location:** Table 17 "Storage, backup, and recovery data-flow summary" in Section 3.11

**Problem:** Table 17 has a "Company 1 block storage" row (C1SAN iSCSI transport) but no row for Company 1 SMB share data — the actual user-visible data layer that sits on top of that block storage. C2 has two share rows (public and private). C1 has none.

**Fix:** Add two rows to Table 17 after the "Company 1 block storage" row:

Row 1:
| Data Set or Flow | Source | Intermediate Path | Destination | Protection Method | Recovery Interpretation |
|---|---|---|---|---|---|
| Company 1 public shares | Local file operations on C1FS | SMB over C1LAN | Named share on F: SharedData volume | Veeam C1_FileShare backup job | File-level restore from Veeam without requiring full-host recovery |

Row 2:
| Data Set or Flow | Source | Intermediate Path | Destination | Protection Method | Recovery Interpretation |
|---|---|---|---|---|---|
| Company 1 Windows file shares | C1SAN iSCSI transport | Mounted to C1FS F: SharedData | SMB share presented to C1LAN clients | Veeam file-share backup plus VM backup | Both the share layer and the underlying host are protected independently |

---

### FIX 2.3 — Table 18: Add Company 1 service health checks

**Location:** Table 18 "Operational maintenance checks" in Section 3.12

**Problem:** Table 18 has 10 maintenance checks. None of them mention C1DC1, C1DC2, C1FS, C1WebServer, or C1WindowsClient directly. The table mentions "both clients can still resolve both web hostnames" (which implicitly covers C1UbuntuClient) and "Company 1 and Company 2 hostnames still return 200" (which covers C1WebServer indirectly). But there is no check for Company 1 domain controller health, C1FS service state, or C1FS iSCSI session — all of which are now directly observable via Jump64.

**Fix:** Add three new rows to Table 18, inserting them after the "Review OPNsense interface and tunnel status" row so they appear in control-plane order:

| Daily or Routine Check | Why It Matters |
|---|---|
| Confirm C1DC1 and C1DC2 are reachable from Jump64 on WinRM (TCP 5985) and that NTDS, DNS, KDC, and Netlogon services are running | Company 1 domain controller health is the foundation of all Company 1 identity, authentication, and name resolution; if either DC is unhealthy, client logon and hostname resolution will degrade |
| Confirm C1FS F: SharedData volume is mounted and SMB shares are accessible; confirm active iSCSI session to C1SAN | Storage transport issues on the Company 1 file service will appear as share unavailability; separating volume, share, and iSCSI checks makes the fault domain immediately visible |
| Confirm C1WebServer IIS service is running and c1-webserver.c1.local returns HTTP 200 while the raw IP returns 404 | Confirms that Company 1 web delivery continues to follow the hostname-only publication model and that IIS has not been reconfigured to answer raw IP requests |

---

### FIX 2.4 — Table 20: Update Systems administration row to include C1 and Jump64

**Location:** Table 20 "Integrated design summary" in Section 3.14

**Problem:** The "Systems administration" row in Table 20 currently reads:
> Summary: "Identity, client access, file services, storage transport, and backup paths are aligned with the documented operating model"
> Supporting Basis: "Samba AD and DHCP state, DNS records, client access, C2FS storage checks, and S2Veeam port reachability"

This supporting basis only mentions C2 systems and C2FS. It omits Jump64 Windows inspection, C1DC1/C1DC2 WinRM sessions, C1FS storage confirmation, and C1WebServer IIS binding — all of which are now part of the documented evidence.

**Fix:** Update the "Systems administration" row:

| Perspective | Summary | Supporting Basis |
|---|---|---|
| Systems administration | Identity, client access, file services, storage transport, Windows-side inspection, and backup paths are aligned with the documented operating model across both tenant scopes | Samba AD and DHCP state, DNS records, three-client web access validation, C2FS and C1FS storage checks, Jump64 WinRM sessions confirming C1DC1/C1DC2/C1FS/C1WebServer/C1WindowsClient service state, and S2Veeam administrative access from Jump64 |

---

### FIX 2.5 — Table B1: Update file services and isolated SAN rows to include C1

**Location:** Table B1 "Evidence and reference traceability" in Appendix B

**Problem:** Two rows in Table B1 reference only C2:
- "File services and share presentation" → "Ubuntu Server Samba documentation plus **C2FS** service-state evidence"
- "Isolated SAN and iSCSI transport" → "Ubuntu Server iSCSI documentation, SAN addressing evidence, and **C2FS** session state"

C1FS now has its own direct evidence (Jump64 WinRM: F: SharedData volume, named SMB shares, active iSCSI session). C1 uses Windows Server SMB and Windows iSCSI initiator — not Ubuntu Samba. The evidence basis should reflect both.

**Fix:** Update these two rows:

Row 1:
| Report Area | Primary Basis |
|---|---|
| File services and share presentation | Ubuntu Server Samba documentation plus C2FS service-state evidence; Windows Server SMB documentation plus C1FS share and volume evidence from Jump64 WinRM inspection |

Row 2:
| Report Area | Primary Basis |
|---|---|
| Isolated SAN and iSCSI transport | Ubuntu Server iSCSI documentation, SAN addressing evidence, and C2FS session state; Windows iSCSI initiator evidence from C1FS Get-IscsiSession output observed via Jump64 |

---

### FIX 2.6 — Section 3.6 Share Presentation: Add Company 1 share validation paragraph

**Location:** Section 3.6, "Share Presentation Model" subsection, after the paragraph ending "...closes the loop between storage architecture and actual user-visible SMB behavior."

**Problem:** The Share Presentation Model subsection ends with client-side validation for C2FS only (employee1@c2.local, employee2@c2.local, c2fs.c2.local). The C1FS share validation — which was directly observed via Jump64 in V4.2 — is described in Section 3.4 but never integrated into Section 3.6's share presentation narrative. A reader of Section 3.6 gets the full C2 share chain but only addressing-level evidence for C1.

**Fix:** Add the following paragraph at the end of the "Share Presentation Model" subsection, after the existing C2 validation paragraph:

> "The Company 1 file service follows the same separation principle on a Windows platform. C1FS presents its shares from a dedicated F: SharedData volume rather than from a system drive, which keeps user data on a volume that can be managed, resized, or backed up independently of the operating system. The active iSCSI session confirmed on C1FS during the March 27 inspection shows that block storage is arriving from C1SAN through the same isolated-bridge model used on the Company 2 side. The difference is platform: where C2FS exposes Samba shares to Linux and Windows clients over c2fs.c2.local, C1FS exposes Windows SMB shares to Company 1 clients. Both designs keep storage transport invisible to users and keep the troubleshooting path clear: a share problem stays in SMB configuration, a mounted-volume problem stays at the file-service host layer, and a block-transport problem stays in the iSCSI session."

---

## CATEGORY 3 — MINOR REMAINING ITEMS

### FIX 3.1 — Remove orphaned TCP 10006 bullet in Section 3.8

**Location:** Section 3.8 "Current Operational State" subsection

**Problem:** The Veeam port list ends with a standalone bullet:
> "- TCP 10006"

This appears to be a duplicate/orphaned bullet. TCP 10006 was already mentioned in the earlier sentence "TCP 5985, TCP 10005, and TCP 10006 were also reachable from MSPUbuntuJump." The standalone bullet at the end adds nothing and looks like an editing artifact.

**Fix:** Remove the final standalone `- TCP 10006` bullet entirely.

---

### FIX 3.2 — Section 3.6 File-Service State: Add C1FS equivalent of C2FS inspection list

**Location:** Section 3.6, "File-Service State" subsection

**Problem:** The section opens with a bullet list of C2FS observations (smbd active, /mnt/c2_public mounted, iSCSI session, share definitions, sync result). C1FS findings are only described in Section 3.4. A reader of Section 3.6 — which is supposed to cover the storage architecture for the whole site — never sees an equivalent list for C1FS.

**Fix:** After the existing C2FS bullet list and its explanatory paragraph, add:

> "Inspection of C1FS from Jump64 showed:
>
> - Windows SMB service active
> - F: drive labeled SharedData present as a dedicated data volume
> - Named SMB shares visible on the F: SharedData volume
> - Active iSCSI initiator session tied to the Company 1 file-service stack
>
> The same layered reading applies: C1SAN delivers the block device, C1FS mounts it as the F: drive, Windows SMB presents named shares above it, and Company 1 clients consume those shares by name. The file-service architecture is equivalent across both tenants even though the platform stack differs."

---

## COMPLETE CHANGE SUMMARY

| Fix | Location | Issue | Action |
|---|---|---|---|
| 1.1 | Section 3.7 bullet list | HTML comment artifacts, C2 hostname duplicated, C1 hostname missing | Remove artifacts; fix list structure; replace duplicate with both hostnames |
| 1.2 | List of Tables | Table 5A title mismatch with body | Update TOC entry to match body title |
| 1.3 | Appendix C | Table C1 body completely absent | Restore full table with V4.4-accurate content |
| 2.1 | Table 15 | File/storage failure domain C2-only | Add Company 1 file and storage row with Jump64 triage commands |
| 2.2 | Table 17 | C1 SMB share data flows missing | Add two Company 1 share data flow rows |
| 2.3 | Table 18 | No C1 system maintenance checks | Add three rows: C1DC health, C1FS iSCSI/share, C1WebServer IIS |
| 2.4 | Table 20 | Systems admin supporting basis C2-only | Update to include Jump64 C1 Windows inspection evidence |
| 2.5 | Table B1 | File/SAN evidence basis C2-only | Update both rows to reference C1FS Windows evidence |
| 2.6 | Section 3.6 Share Presentation | Only C2 client validation paragraph | Add C1FS share chain validation paragraph |
| 3.1 | Section 3.8 | Orphaned TCP 10006 bullet | Remove duplicate bullet |
| 3.2 | Section 3.6 File-Service State | C1FS inspection not listed here | Add C1FS bullet list matching C2FS format |

---

## DO NOT CHANGE

- Executive Summary — correct as-is
- Introduction — correct as-is
- Table 5A — correctly updated in V4.4 with MSPUbuntuJump and C1UbuntuClient rows
- Table 10 — correctly updated in V4.4 with C1FS storage rows
- Table 11 — correctly updated in V4.4 with C1WindowsClient column
- Table 12 — correctly updated in V4.4 with all three client rows
- Section 3.4 — Company 1 content is strong; do not modify
- Conclusion — do not change
- Appendix D — correctly updated in V4.4
- Appendix E — correct as-is
- References — correct as-is

---

*Revision prompt for V4.4 → V4.5. All fixes use evidence already present in V4.4. Estimated score after applying all fixes: 96–97/100.*
