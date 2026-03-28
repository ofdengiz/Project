# CODEX REVISION PROMPT — Site 2 Technical Report
## Assessment Score and Detailed Revision Instructions

---

## PART 1 — SCORING AGAINST PDF RUBRIC

### Scoring Criteria (from CST8248 Week 09 Slides)

| Criterion | Max | Score | Notes |
|---|---|---|---|
| Title Page (layout, title prominence, names, team, due date) | 10 | 8 | Present and complete. "Due Date" is listed as March 26, 2026, which is the document date — not a submission due date. Team name is absent. |
| Table of Contents (major/minor headings, figures/tables, page numbers) | 10 | 9 | Comprehensive. List of Figures and List of Tables are both present. Page numbers shown. Minor: Executive Summary is missing from the ToC. |
| Executive Summary (short, key decision points, purpose-aware) | 10 | 6 | Extremely long and technically dense — reads more like a second introduction than an executive summary. Decision-makers cannot extract key points quickly. |
| Introduction (purpose, main content, scope) | 10 | 8 | Well-structured. Scope is clearly defined. Slightly over-explains methodology. |
| Background (reader prerequisites, intended audience) | 10 | 7 | Tables 1–3 are thorough but very heavy. The section front-loads technical tables before the reader understands the environment. Intended audience is stated on the title page but not restated here. |
| Discussion (services/platforms + rationale, networks/IPs, limitations, maintenance, daily duties, personal thoughts) | 30 | 22 | Technically strong. Rationale is consistently provided. Maintenance and daily duties are present. However: (a) the writing reads as AI-generated in many paragraphs — formulaic sentence rhythm, overuse of passive constructions, repetitive transitional phrases; (b) no honest acknowledgment of limitations or non-functioning equipment; (c) personal/team perspective is absent throughout; (d) section distribution is uneven — storage and backup sections are thin compared to identity. |
| Conclusion (summarizes, no new content, what was learned) | 10 | 5 | Introduces content not mentioned earlier (e.g., "the final design is explainable at the level of rationale, not only inventory" — this framing appears here for the first time). Does not state what the team learned. |
| Appendices (config files, unresolved troubleshooting) | 5 | 3 | Appendices A, B, C are tidy but lack raw config files. No unresolved troubleshooting section. |
| References (IEEE format) | 5 | 5 | IEEE format is correctly applied. 11 references, accessed dates included. |
| Writing style (client/handover tone, human voice, personal touch) | 10 | 4 | The document lacks personality entirely. The professor explicitly noted: "If you're bored to write it; I will likely be bored to read it." Many paragraphs use identical structural patterns. |

**TOTAL ESTIMATED SCORE: 77 / 100**

---

## PART 2 — DETAILED REVISION INSTRUCTIONS

---

### ISSUE 1 — Title Page: Missing Team Name and Due Date Ambiguity

**Problem:** The title page does not list a team name. The "Document Date" (March 26, 2026) is being used in a field that should represent the assignment due date, not the document creation date. The rubric requires both.

**Fix:** Add a "Team Name" field directly below the contributors list. Rename "Document Date" to "Document Date" and add a separate "Submission Due Date" field matching the actual course deadline. If the team has no formal name, use the site identifier (e.g., "Site 2 Team") or create a short identifier.

---

### ISSUE 2 — Executive Summary: Too Long, Too Technical, Wrong Audience

**Problem:** The Executive Summary runs for approximately 600 words and lists 15+ technical bullet points including IP addresses, port numbers, iSCSI target names, and resolver scopes. An executive summary is meant for decision-makers who need to understand what was done and whether it succeeded — not for engineers who need to verify iSCSI sessions.

The rubric says: "Short summary — should detail the key points for decision making purposes."

**Fix:** Reduce the Executive Summary to 200–300 words maximum. Structure it around three questions a client or manager would ask:
- What did we build and for whom?
- Does it work?
- Is it ready to hand over?

Remove all IP addresses, port numbers, and CLI-level observations. Mention the technologies (OPNsense, Samba AD, Veeam, Nginx, iSCSI) only by name and purpose. The technical detail lives in the Discussion.

Example restructure:
> "Site 2 was designed and deployed as a multi-tenant managed service environment supporting MSP administration, Company 1, and Company 2 operations within a single integrated platform. The environment uses OPNsense for network segmentation and secure remote access, Samba-based Active Directory for identity and DNS, isolated iSCSI storage for file services, Nginx for internal web delivery, and Veeam for backup and offsite protection. Validation completed March 23–25, 2026 confirmed that all major service components are operational and behaving as designed. This report is written to support formal handover to client IT staff and successor operations teams."

---

### ISSUE 3 — Conclusion: Introduces New Framing and Omits "What Was Learned"

**Problem:** The rubric explicitly says: "DO NOT introduce new content here." The conclusion introduces the framing of "explainable at three depths" (stakeholder, network engineer, sysadmin) — this never appeared in the Discussion. It also does not say what the team learned from the project, which is the primary purpose of a conclusion in academic technical writing.

**Fix:**
1. Remove the "explainable at different depths" paragraph — move it to Section 3.14 (Integrated Design Summary) where it belongs.
2. Add a genuine "what we learned" paragraph. This should be written in first person or inclusive "we" voice and reflect actual team experience. Examples of honest learning statements:
   - That synchronization and backup are operationally distinct problems requiring separate tooling.
   - That DNS resolver scope configuration is a hidden dependency that appears only at the client layer.
   - That isolated SAN transport requires deliberate interface planning that is easy to overlook until file services fail.
3. The conclusion should summarize what the document covered — not restate individual findings in list form.

---

### ISSUE 4 — Discussion: No Acknowledgment of Limitations or Non-Functioning Equipment

**Problem:** The rubric asks: "Are there limitations / non-functioning equipment?" The current document presents every component as fully functional with "High" assurance. In a real multi-system deployment, there are always caveats, partial validations, or components that could not be fully verified. The absence of any limitation reads as either overconfident or incomplete.

**Fix:** Add a subsection to Section 3 (Discussion) titled "Limitations and Outstanding Items" (or fold it into Section 3.13 Troubleshooting). Be honest. Examples of appropriate limitations to document:
- C1WindowsClient was present in inventory but not directly validated through CLI inspection — its operational state is based on inventory evidence rather than live observation.
- OPNsense management returned HTTP 403, meaning web UI access was not confirmed beyond the access check.
- Company 1 SAN (C1SAN) was confirmed through addressing evidence but no live iSCSI session was directly observed, unlike C2SAN.
- Any timeout, failed port check, or DNS query that did not return the expected result.

If nothing was broken, say so — but explain what evidence supports that claim and what was not testable.

---

### ISSUE 5 — Writing Style: AI-Generated Cadence Must Be Replaced with Human Voice

**Problem:** The professor explicitly warned: "If you're bored to write it; I will likely be bored to read it." The current document has several structural patterns that repeat throughout almost every section:
- Paragraph 1: Explains what will be described.
- Paragraph 2: Describes the thing.
- Paragraph 3: Explains why the thing matters.
- Paragraph 4: Connects to the next section.

This pattern is technically correct but mechanically repetitive. It reads as machine-generated. Additionally, phrases like "that is why later sections repeatedly return," "the environment reads coherently from end to end," and "that is the threshold a formal handover document should meet" appear in almost identical form across multiple sections.

**Fix:** Apply the following changes section by section:

**Section 3.1 (Environment Overview):**
Rewrite the opening. Instead of: "Site 2 should be read as a complete service site, not as a loose grouping of servers," try something like: "The first thing a new operator needs to understand about Site 2 is that pulling any one service out of context makes the rest harder to explain. The network boundary only makes sense when you know which identities it protects. The storage isolation only makes sense when you see what the file server does with it."

**Section 3.3 (MSP Entry / Segmentation):**
The phrase "the network layer is the controlling discipline of Site 2" is accurate but clinical. A human writer would say something like: "Everything else in this document depends on the network design being correct. If the segmentation is wrong, no amount of careful Samba configuration or Veeam scheduling will produce a secure, supportable environment."

**Section 3.8 (Backup):**
The backup section is the thinnest of the major service sections despite being one of the most operationally important. It leans heavily on tables. Add at least two paragraphs of written explanation covering: why the file-share backup is kept separate from VM backup, and what a real recovery would look like (which machine do you restore first, from which repository).

**Throughout:**
- Replace "that is why" with direct statements.
- Replace "it is important to note that" with the actual note.
- Remove all instances of "in a handover context" — the entire document is a handover document; this qualifier adds nothing.
- Remove "that is the more supportable model" — say why it is more supportable instead.

---

### ISSUE 6 — Section Distribution Is Uneven

**Problem:** The Discussion sections are not balanced. The identity section (3.5) and the client access section (3.7) are both longer and more narratively developed than the storage section (3.6) and the backup section (3.8). The professor expects the document to cover all services with roughly equivalent depth and care.

**Fix:**
- **Storage section (3.6):** Add a paragraph explaining the decision to use iSCSI rather than NFS or a direct-attached model, and why the SAN isolation matters from a security standpoint — not just from a support standpoint.
- **Backup section (3.8):** Add a paragraph describing what a realistic recovery scenario would look like. Which machine fails? What does an operator do in the first ten minutes? Where is the repository? How does the offsite copy get invoked?
- **Company 1 section (3.4):** Currently shorter than Company 2. If Company 1 was less directly observable, say so explicitly and explain what evidence fills that gap. Do not let the section read as though Company 1 was less important.

---

### ISSUE 7 — Document Language: Terminological Consistency and Heading Naturalness

**Problem:** Some heading names read as internally generated taxonomy rather than natural technical writing. Examples:
- "3.2 Site 2 Logical Service Inventory and Platform Roles" — awkward. Could be "3.2 Service Inventory and Platform Layout."
- "3.9 Requirement-to-Implementation Traceability" — acceptable in a formal standards document but heavy for a course report. Could be "3.9 Requirements Coverage" or "3.9 How Requirements Were Met."
- "3.11 Storage, Backup, and Recovery Flow" — this section overlaps substantially with 3.6 and 3.8. The overlap should either be removed or the section should be clearly marked as a cross-cutting summary.

**Fix:** Rename headings to read as natural English titles, not database field names. Each heading should tell the reader what they are about to learn, not simply label the category.

---

### ISSUE 8 — No Personal Voice or Team Perspective Anywhere

**Problem:** The rubric says: "Include things that you find interesting or important. Include your own personal touch." The current document has zero instances of team perspective, personal observation, or genuine reflection. Every sentence is neutral third person. A reader cannot tell who wrote this or what they thought of the work.

**Fix:** Add brief first-person or team-perspective passages at natural points:
- In the Introduction: One or two sentences about how the team approached the project — what the starting point was, what the biggest challenge turned out to be.
- In the Discussion: In sections where design choices were made, note briefly why the team made that choice over alternatives, using "we" as appropriate for a team report.
- In the Conclusion: The "what was learned" section should be genuinely reflective, not a restatement of technical outcomes.

These do not need to be long. Two or three sentences of genuine perspective in four or five places throughout the document will change its tone significantly.

---

### ISSUE 9 — Background Section: Intended Audience Not Restated

**Problem:** The title page says the intended audience is "Client IT staff, MSP support teams, and successor operations staff." The Background section is supposed to tell the reader what they need to understand before reading the document, and who the intended reader is. The current Background section describes evidence classes and methodology but does not address prerequisites or audience framing.

**Fix:** Add a short paragraph at the start of Section 2 that says who this document is written for and what they are expected to know. For example: "This document is written for IT staff taking over operational responsibility for Site 2, and for MSP technicians who may need to support or modify the environment. Readers are expected to be comfortable with basic networking concepts, Windows Server administration, and Linux command-line operations. No prior knowledge of Site 2 specifically is required — this document is intended to provide that context."

---

### ISSUE 10 — Appendices: No Raw Configuration Files, No Unresolved Troubleshooting

**Problem:** The rubric says: "Config files go well here" and "Unresolved troubleshooting." The appendices currently contain three summary tables. These are useful but they are not configuration files. No raw config output — OPNsense rules, Samba smb.conf, nginx virtual host blocks, or Veeam job definitions — appears anywhere in the document.

**Fix:**
- Add at least one raw configuration excerpt as an appendix. The most useful options are: a sanitized smb.conf block from C2FS showing the C2_Public and C2_Private share definitions, or the relevant OPNsense firewall rule export.
- Add an "Appendix D: Unresolved Items and Known Gaps" section. Even if everything worked, this section should note what could not be fully verified, any assumptions made, and any items left for the client to confirm post-handover.

---

## PART 3 — SUMMARY OF CHANGES FOR CODEX

Apply all of the following to the existing document file:

1. **Title Page:** Add "Team Name" field. Separate document date from submission due date.
2. **Table of Contents:** Add Executive Summary entry with page number.
3. **Executive Summary:** Reduce to 200–300 words. Remove all IPs, ports, and CLI details. Focus on: what was built, for whom, does it work, is it ready for handover.
4. **Background (Section 2):** Add audience and prerequisite paragraph at the start.
5. **Discussion Section 3.4 (Company 1):** Expand to match the depth of Section 3.5 (Company 2). Add explicit statement of what was directly observed vs. inferred from evidence.
6. **Discussion Section 3.6 (Storage):** Add paragraph on iSCSI choice rationale and security reasoning behind SAN isolation.
7. **Discussion Section 3.8 (Backup):** Add realistic recovery scenario narrative. Add paragraph distinguishing file-share backup from VM backup.
8. **Add Section 3.x — Limitations and Outstanding Items:** Acknowledge what could not be fully verified. Include C1WindowsClient observability gap, OPNsense UI 403 status, and C1SAN live session observability. If there are no unresolved items, explain the basis for that confidence.
9. **Rewrite every section opening paragraph** to eliminate the "explain what will be described, describe it, explain why it matters, connect to next section" four-paragraph pattern. The writing should feel like a senior engineer explaining the environment to a colleague — direct, specific, occasionally personal.
10. **Remove the following phrases throughout:** "in a handover context," "that is the more supportable model," "it is important to note that," "from a documentation standpoint," "that is why later sections," "the environment reads coherently from end to end."
11. **Conclusion:** Remove new framing content. Add genuine team learning paragraph in first person. Ensure conclusion only references content from the Discussion.
12. **Appendices:** Add raw config file excerpt (smb.conf or OPNsense rule block). Add Appendix D for unresolved items and known gaps.
13. **Heading names:** Rename awkward headings to natural English titles (see Issue 7).
14. **Personal voice:** Insert two to three brief team-perspective passages in Introduction, Discussion, and Conclusion.

---

*Assessment prepared against CST8248 Week 09 rubric. Document version assessed: V3.9 Revised, March 26, 2026.*
