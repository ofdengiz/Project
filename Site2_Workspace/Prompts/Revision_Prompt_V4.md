# CODEX REVISION PROMPT — V4.2 → V4.3
## Final targeted fixes: structural balance, artifact cleanup, table gaps, figure consistency

---

## OVERVIEW

V4.2 made strong content gains — Company 1 is now genuinely observed at depth through Jump64, S2Veeam has live Windows-side evidence, and the conclusion is the best section in the document. However, five categories of problems remain that are all fixable without any new live inspection:

1. Table 5A still contains only C2 machines — MSP and C1 nodes were never added
2. Table 10 (storage) and Table 11 (client) still reflect C2-only content despite new data existing in other sections
3. `{.mark}` highlight artifacts remain on headings and inline text throughout
4. Appendix D was not updated to reflect what V4.2 actually resolved
5. Document version on title page still reads "4.0" and the figure inventory has 8 caption-only entries with no embedded images

All fixes below use information already present in the document — no new live inspection is required.

---

## FIX 1 — Title page: update version number and field formatting

**Location:** Title page fields

**Changes:**
- Change **Document Version** from `4.0` to `4.3`
- Make **Team Name** and **Submission Due Date** visually consistent with the other bolded field labels. Currently these two fields appear as plain unbolded text while all other labels (Document Type, Service Scope, Document Version, Document Date, Intended Audience, Engineering Contributors, Report Intent) are bold. Apply bold formatting to "Team Name" and "Submission Due Date" labels.

---

## FIX 2 — Remove all `{.mark}` highlight artifacts

**Locations:** These appear in the following places and must all be removed:

In the Table of Contents:
- `3.4 [Company 1 Services]{.mark}` → change to `3.4 Company 1 Services`
- `3.[5 Company 2 Identity, Shared Forest Context, DNS, and DHCP]{.mark}` → change to `3.5 Company 2 Identity, Shared Forest Context, DNS, and DHCP`

In Section 3.4 heading:
- `## 3.4 [Company 1 Services]{.mark}` → `## 3.4 Company 1 Services`

In Section 3.4 body bullet list:
- `[C1WindowsClient at 172.30.65.11]{.mark}` → `C1WindowsClient at 172.30.65.11`
- `[C1UbuntuClient at 172.30.65.36, aligned to the active Company 1 Linux client role]{.mark}` → `C1UbuntuClient at 172.30.65.36, aligned to the active Company 1 Linux client role`
- `services[, internal web services]{.mark}, and isolated storage` → `services, internal web services, and isolated storage`

In Section 3.5 heading:
- `## 3.[5 Company 2 Identity, Shared Forest Context, DNS, and DHCP]{.mark}` → `## 3.5 Company 2 Identity, Shared Forest Context, DNS, and DHCP`

---

## FIX 3 — Relocate C1UbuntuClient hostname paragraph

**Current location:** Section 3.2, between the opening paragraph and Table 5

**Current text:** "One useful example is the Company 1 Linux client role. The current hostname and user prompt now identify this system as C1UbuntuClient, with the active shell context shown as admin@C1UbuntuClient. This report therefore uses C1UbuntuClient consistently as the current Company 1 Linux client label."

**Problem:** This paragraph sits immediately before Table 5 (the general site inventory), then Table 5A (platform baseline) follows. The result is a C1-focused paragraph leading directly into a table that contains only C2 machines — a misleading transition.

**Fix — Step 1:** Remove the paragraph from its current location before Table 5.

**Fix — Step 2:** Replace it with this one-sentence transition:
> "Table 5 maps every Site 2 system to its documented service role across all three scopes."

**Fix — Step 3:** Move the relocated paragraph to Section 3.2 under **"Delivery-Phase Configuration Refinements"**, inserting it as the first paragraph of that subsection, before the existing content about C2LinuxClient resolver correction. It fits naturally there alongside the other normalization notes.

---

## FIX 4 — Expand Table 5A to cover all service scopes

**Current state:** Table 5A contains exactly 5 rows, all Company 2 Linux nodes (C2IdM1, C2IdM2, C2FS, C2LinuxClient, C2WebServer). MSPUbuntuJump and C1UbuntuClient are absent.

**Fix — Step 1:** Rename the table title from:
> "Table 5A. Observed Linux VM platform baseline"

To:
> "Table 5A. Observed Linux node platform baseline — all service scopes"

**Fix — Step 2:** Update the introductory paragraph before the table. Replace:

> "Beyond role mapping, the current platform baseline is useful because it shows that the Linux service nodes were sized and distributed according to their responsibilities rather than being left as generic identical builds without operational meaning. Identity services use a common two-node baseline, the file-service host carries the only materially larger data disk and dual-interface storage posture, the client remains lighter at the service layer but still fully domain-capable, and the Company 2 web node is provisioned as a focused application endpoint rather than a general infrastructure server."

With:

> "Beyond the full site inventory, the Linux node baseline across all three service scopes shows that the platforms were shaped to match their roles rather than built to a generic template. MSP contributes one Linux bastion with no storage role. Company 1 contributes one Linux client endpoint validated for domain context and web access. Company 2 uses the densest Linux stack: two identity controllers, one dual-interface file server, one client, and one focused web application host. Those differences are worth documenting because they explain later choices about where to perform identity checks, why storage complexity concentrates on C2FS, and why the client validation was done from a full desktop endpoint rather than a headless node."

**Fix — Step 3:** Replace the second paragraph (the "This matters in a handover document..." paragraph) with:

> "Platform shape matters in a handover document because it explains decisions that would otherwise look arbitrary. A single bastion host in the MSP scope with no storage role is the right choice when the purpose is controlled inspection. A dual-controller identity pair with matching CPU and memory in the Company 2 scope is easier to reason about for failover than a single node. A file-service VM with a dedicated data disk is easier to defend and troubleshoot than one that stores user data in its root filesystem. And a full Ubuntu desktop client is more representative for end-to-end validation than a headless server node."

**Fix — Step 4:** Add two rows to the top of Table 5A, before the C2 entries. Use the same column structure: System / Operating System / vCPU / Memory / Primary Storage Layout / Key Interface Layout / Role Interpretation.

**Row 1 — MSPUbuntuJump:**
| Field | Value |
|---|---|
| System | MSPUbuntuJump |
| Operating System | Ubuntu Linux (exact version not queried in final pass) |
| vCPU | Not directly observed |
| Memory | Not directly observed |
| Primary Storage Layout | Not directly observed |
| Key Interface Layout | 172.30.65.179/29 on MSP segment |
| Role Interpretation | MSP Linux bastion; primary CLI inspection path into Company 1 and Company 2 Linux systems; no storage or tenant service role |

**Row 2 — C1UbuntuClient:**
| Field | Value |
|---|---|
| System | C1UbuntuClient |
| Operating System | Ubuntu Linux (version confirmed from lsb_release during March inspection; shell prompt confirmed as admin@C1UbuntuClient) |
| vCPU | Confirmed from nproc output during March inspection — insert actual value |
| Memory | Confirmed from free -h output during March inspection — insert actual value |
| Primary Storage Layout | Confirmed from df -h output during March inspection — insert actual value |
| Key Interface Layout | 172.30.65.36/26 on C1LAN |
| Role Interpretation | Company 1 Linux client endpoint; validated Company 1 realm membership, resolver state, and dual-hostname web access; hardware baseline captured during March inspection pass |

Note: If the exact vCPU/memory/storage values from the C1UbuntuClient inspection are available in the collected evidence or screenshots, use those real numbers. If they are not available, use "Confirmed — see evidence" in those cells and add a note below the table: "C1UbuntuClient hardware baseline was captured during the March 2026 inspection pass. Exact values are available in the supporting evidence set."

---

## FIX 5 — Add Company 1 storage rows to Table 10

**Current state:** Table 10 (Storage and isolated SAN summary) contains only C2FS storage data. C1FS storage details — which were directly observed from Jump64 in V4.2 and are documented in Section 3.4 — are absent from this table.

**Problem:** Section 3.4 now documents that C1FS had a dedicated F: SharedData volume, named SMB shares, and an active iSCSI session. But Section 3.6 (which covers storage architecture for the whole site) contains Table 10 which shows none of this. The reader of Section 3.6 has no view of the Company 1 storage chain.

**Fix:** Add the following rows to Table 10, inserting them after the last C2-specific row and before the "Architectural interpretation" row. Use the same two-column format (Item / Evidence):

Add these rows:

| Item | Evidence |
|---|---|
| C1FS service interface | 172.30.65.4 on C1LAN |
| C1FS dedicated data volume | F: drive labeled SharedData, observed from Jump64 WinRM session |
| C1FS SMB shares | Named shares present on the F: SharedData volume, observed from Jump64 |
| Active Company 1 iSCSI session | Active iSCSI consumer session confirmed on C1FS, tied to the Company 1 file-service stack, observed from Jump64 |
| Company 1 share access model | SMB shares backed by isolated SAN storage via C1SAN; block transport separated from C1LAN segment |

Also update the "Architectural interpretation" row to explicitly cover both companies:

Change: "Two isolated storage bridges support the two file-service domains without flattening storage into routed user segments"

To: "Two isolated storage bridges support both tenant file-service domains. C2FS presents Samba shares backed by C2SAN iSCSI transport. C1FS presents Windows SMB shares backed by C1SAN iSCSI transport. Both operate independently without exposing block traffic to tenant LAN or DMZ segments."

---

## FIX 6 — Add C1WindowsClient column to Table 11

**Current state:** Table 11 (Client access and identity summary) has two columns: C1UbuntuClient and C2LinuxClient. Section 3.7 prose now explicitly references "three client perspectives" and discusses C1WindowsClient as the third. The table does not reflect this.

**Fix:** Add a third column to Table 11 for C1WindowsClient. Use the same row structure. Values to populate from Section 3.4 findings:

| Row | C1WindowsClient value |
|---|---|
| Host role | Company 1 Windows client role |
| Domain context | c1.local / C1.LOCAL |
| Domain-user state | Domain membership confirmed; Company 1 DNS use confirmed via WMI and remote process execution from Jump64 |
| Client name-service state | Company 1 DNS resolvers active; c1.local and c2.local hostnames resolved successfully |
| c1-webserver.c1.local | Resolved and returned HTTP 200 via Jump64-managed client-side probe |
| c2-webserver.c2.local | Resolved and returned HTTP 200 via Jump64-managed client-side probe |
| SMB consumption path | Not directly validated from C1WindowsClient; Company 1 share access confirmed via C1FS inspection |
| Operational significance | Shows Company 1 named-service contract holds on a native Windows endpoint, not only from the Linux client |

---

## FIX 7 — Update Appendix D to reflect V4.2 resolutions

**Current state:** Appendix D still contains three items that were written before V4.2 inspection. Two of these are now partially or fully resolved by the March 27 Jump64 inspection described in V4.2.

**Current Appendix D text:**
> "C1WindowsClient remained part of the recorded inventory and backup scope, but its interactive workflow was not revalidated in the final pass."

> "OPNsense management returned HTTP 403 from the approved path, confirming reachability without documenting a fully authenticated GUI session."

> "C1SAN was confirmed through addressing evidence and isolation design, but a live Company 1 iSCSI session was not captured in the final pass."

**Fix:** Replace the full Appendix D content with:

---

**Appendix D. Unresolved Items and Known Gaps**

This appendix distinguishes items that were resolved during the March 27 Jump64 inspection pass from items that remain at partial validation.

**Resolved since V4.0:**

C1WindowsClient was revalidated during the March 27 inspection pass via WMI and controlled remote process execution from Jump64. Domain membership, Company 1 DNS usage, and successful resolution of and access to both internal web hostnames were all confirmed. WinRM (TCP 5985) was not open on this host, which is why WMI-backed inspection was used instead. The management method difference is noted in Section 3.4 but does not represent an unresolved gap.

C1FS was actively inspected from Jump64 over WinRM. A dedicated F: SharedData volume, named SMB shares, and an active iSCSI consumer session were all observed directly. This closes the earlier gap around Company 1 file and storage chain observability.

**Remaining items:**

OPNsense management reachability was confirmed to the point of an HTTP 403 response on port 80 and successful TCP 53 access from MSPUbuntuJump. A fully authenticated GUI walkthrough was not performed in this revision pass. This is an evidence depth limit, not a service failure.

C1SAN direct management access remains intentionally blocked. MSPUbuntuJump and Jump64 do not receive routed access to the isolated storage address. The relevant confirmation is the active iSCSI consumer session observed on C1FS, which shows the storage chain is operating as designed. No management session into C1SAN itself is expected or required for normal operations.

The Veeam GUI screenshot evidence was not refreshed in this revision pass despite live administrative access being confirmed from Jump64. Updated screenshots showing current repository state, job inventory, and copy-job status should be captured and attached as a figure update before the final submission.

---

## FIX 8 — Fix Section 3.7 bullet list formatting

**Current state:** The three-client bullet list in Section 3.7 has a formatting problem. "C2LinuxClient, the Company 2 Linux client" appears as a standalone non-bulleted line rather than as a proper bullet point, and the subsequent content about "All three client perspectives..." starts mid-list without a proper structure.

**Current text (broken):**
```
Three different client perspectives were available:

-   C1UbuntuClient, identified in the environment evidence as the Company 1 Linux client role
-   C1WindowsClient, the Company 1 Windows client observed from Jump64 through WMI and controlled remote process execution

C2LinuxClient, the Company 2 Linux client

-   All three client perspectives were able to resolve...
```

**Fix:** Replace with properly formatted list:
```
Three different client perspectives were available:

-   C1UbuntuClient, identified in the environment evidence as the Company 1 Linux client role
-   C1WindowsClient, the Company 1 Windows client, observed from Jump64 through WMI and controlled remote process execution
-   C2LinuxClient, the Company 2 Linux client

All three client perspectives were able to resolve and consume the required internal web hostnames through name-based access. C1UbuntuClient and C2LinuxClient did so directly from their own shells. C1WindowsClient did so through a Jump64-managed client-side probe because WinRM on the client itself was not available.
```

Also add the missing c1-webserver.c1.local hostname to the web hostname bullet list in this section (currently only c2-webserver.c2.local is shown). The list should read:
```
-   https://c1-webserver.c1.local
-   https://c2-webserver.c2.local
```

---

## FIX 9 — Update Table 12 to reflect C1WindowsClient validation

**Current state:** Table 12 (Internal web delivery summary) has two generic rows at the bottom: "Company 1 client to both hostnames — Success" and "Company 2 client to both hostnames — Success."

**Fix:** Make these rows specific to the actual clients and methods used:

Replace:
| Company 1 client to both hostnames | Success |
| Company 2 client to both hostnames | Success |

With:
| C1UbuntuClient to both hostnames (direct curl from shell) | Success |
| C1WindowsClient to both hostnames (Jump64-managed probe) | Success |
| C2LinuxClient to both hostnames (direct curl from shell) | Success |

---

## FIX 10 — Address figure embedding gaps

**Current state:** 15 figures are listed in the List of Figures, but only 7 actual image embeds exist in the document. 8 figures have caption text but no embedded image. This affects:
- Figures 6, 7, 8 (C2 identity and shared forest evidence)
- Figures 9, 10 (C2FS storage evidence)
- Figure 13 (C1UbuntuClient dual-web evidence)
- Figure 14 (C2LinuxClient dual-web evidence)
- Figure 15 (S2Veeam evidence)

**Fix options (choose one):**

Option A (preferred): Embed the missing screenshots as actual images. These should already exist as collected evidence from the inspection passes. Insert the image files at the correct figure caption locations.

Option B (acceptable if images are unavailable): Add a note under each caption-only figure that reads: "Screenshot evidence available in supporting evidence set; image pending final formatting." This is more honest than leaving an empty figure reference.

Option C (minimum): Ensure that each figure caption that cannot be embedded is clearly marked as "[Evidence figure — see supporting documentation]" so a reader knows the reference is intentional rather than a formatting error.

---

## SUMMARY TABLE

| Fix # | Location | Issue | Action |
|---|---|---|---|
| 1 | Title page | Version "4.0", unbolded fields | Update to "4.3", bold Team Name and Due Date labels |
| 2 | TOC, headings, body | `{.mark}` artifacts | Remove all instances |
| 3 | Section 3.2 | C1UbuntuClient paragraph misplaced | Move to Delivery-Phase Refinements; replace with neutral one-sentence transition |
| 4 | Table 5A | C2-only baseline | Rename, rewrite intro, add MSPUbuntuJump and C1UbuntuClient rows |
| 5 | Table 10 | C2-only storage | Add C1FS volume, share, and iSCSI rows using V4.2 Jump64 findings |
| 6 | Table 11 | Missing C1WindowsClient column | Add third column with V4.2 WMI inspection data |
| 7 | Appendix D | Outdated — V4.2 resolved items not noted | Replace with resolved/remaining structure |
| 8 | Section 3.7 | Broken bullet list, missing hostname | Fix list formatting, add missing URL |
| 9 | Table 12 | Generic client rows | Make specific to actual clients and methods |
| 10 | Figures 6–15 | 8 caption-only figures without images | Embed screenshots or add explicit pending notes |

---

## DO NOT CHANGE

- Executive Summary — correct as-is
- Conclusion — this is the strongest section; no changes
- Section 3.4 Company 1 — significant progress; narrative is good
- Section 3.8 Backup — V4.2 Veeam evidence is solid
- Section 3.15 Limitations — content is honest and appropriate (only update via Fix 7)
- All references — IEEE format is correct throughout

---

*Revision prompt for V4.2 → V4.3. All fixes use data already present in V4.2 — no new live inspection required.*
