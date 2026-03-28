# Site 2 Documentation Gap Analysis vs Site 1 Final Document

## 1. Why the current Site 2 document still feels thin

The current Site 2 draft is structurally closer to a strong technical summary than to the full narrative style used in `Site1_Final_Documentation_V2.8.docx`.

The Site 1 final document is longer not only because it contains more words, but because it repeatedly uses this pattern:
- introduce a section
- add one or more tables
- add one or more figures
- explain each figure in prose
- connect the section back to design rationale and operations

The reference extraction showed more than 150 figure/table caption lines in the Site 1 document. The Site 2 draft currently has the right general topics, but not yet enough:
- figure density
- table density
- subsection depth
- explanatory paragraphs after each evidence item
- appendix detail

## 2. Sections that Site 2 still needs to expand

To truly match Site 1 style, Site 2 needs richer coverage in these areas:

1. Environment overview and topology
2. Network design and IP addressing rationale
3. Identity infrastructure and tenant separation
4. Platform and service choice rationale
5. Compute and virtualization
6. Identity, DNS, and DHCP services
7. Storage and SAN services
8. Backup and recovery
9. Value added features
10. Site-to-site VPN security and administrative access
11. Maintenance and daily duties
12. Limitations, risks, and unresolved items
13. Appendices

## 3. Specific content that is still missing or too thin

### 3.1 Topology and network explanation

Still needed:
- a clean Site 2 topology diagram
- a VLAN/subnet/gateway summary table
- a paragraph explaining why Company 1, Company 2, MSP, DMZ, and SAN paths are separated
- a figure and explanation for OPNsense interface layout
- a figure and explanation for OpenVPN routing intent

### 3.2 Identity and DHCP

Still needed:
- Company 1 AD summary table
- Company 2 Samba AD summary table
- DHCP scope table(s)
- account administration process explanation
- screenshots that show:
  - AD/DNS/DHCP on Company 1 side
  - Samba DC state or admin views on Company 2 side

### 3.3 Storage and replication

Still needed:
- dedicated storage service tables similar to Site 1’s storage section
- a clean explanation of:
  - SAN-backed Company 2 file services
  - Site 1 to Site 2 pull sync model
  - why this is replication and not backup
- screenshots for:
  - mounted data disk
  - sync script
  - sync log
  - if available, iSCSI session evidence

### 3.4 Backup and recovery

Still needed:
- a backup scope table by host class
- repository layout table
- file backup vs agent backup explanation
- offsite SMB copy rationale
- NTP troubleshooting note as an operational lesson learned
- more screenshots for:
  - repositories
  - protection groups
  - job success
  - offsite target folder

### 3.5 AWS web publication

Still needed:
- a short rationale for AWS instead of purely on-prem web hosting
- EC2 master/worker inventory table
- Route53/DNS flow explanation
- S3 state explanation
- HTTPS publication explanation with Caddy and public DNS
- screenshots already available for:
  - EC2 instances
  - Route53 record
  - S3 state
  - public website
  - `kubectl get nodes/pods`

### 3.6 Value-added features

Site 1 includes value-added features like Grafana, Cockpit, and Windows Admin Center.  
Site 2 should present its own value-added features explicitly, for example:
- internal HTTPS publication for Lumora
- public AWS HTTPS publication for ClearRoots
- offsite Veeam copy to Site 1
- certificate trust deployment by GPO
- service block validation and operational runbook

## 4. Best screenshot candidates already identified

These local screenshots are already strong candidates for the final Site 2 document:

### AWS / public web
- `C:\Algonquin\Winter2026\Emerging_Tech\Project\EkranGoruntuleri\Screenshot 2026-03-19 221015.png`
- `C:\Algonquin\Winter2026\Emerging_Tech\Project\EkranGoruntuleri\Screenshot 2026-03-19 221021.png`
- `C:\Algonquin\Winter2026\Emerging_Tech\Project\EkranGoruntuleri\Screenshot 2026-03-19 221039.png`
- `C:\Algonquin\Winter2026\Emerging_Tech\Project\EkranGoruntuleri\Screenshot 2026-03-19 221125.png`
- `C:\Algonquin\Winter2026\Emerging_Tech\Project\EkranGoruntuleri\Screenshot 2026-03-19 221244.png`

### Backup and offsite copy
- `C:\Algonquin\Winter2026\Emerging_Tech\Project\EkranGoruntuleri\Screenshot 2026-03-19 222005.png`
- `C:\Algonquin\Winter2026\Emerging_Tech\Project\EkranGoruntuleri\Screenshot 2026-03-19 222049.png`

### Company 1 web / internal service evidence
- `C:\Algonquin\Winter2026\Emerging_Tech\Project\EkranGoruntuleri\Screenshot 2026-03-17 215348.png`
- `C:\Algonquin\Winter2026\Emerging_Tech\Project\EkranGoruntuleri\Screenshot 2026-03-17 215512.png`

## 5. Screenshots still worth collecting or confirming

To fully bring Site 2 to Site 1 level, these screenshots would still help a lot if available:

1. OPNsense dashboard or interfaces page
2. OPNsense OpenVPN status page
3. OPNsense NAT rules page
4. Company 1 DHCP scope view
5. Company 2 DHCP scope or equivalent service proof
6. C2IdM1 Samba AD replication screenshot
7. C2IdM2 Samba AD replication screenshot
8. C2FS mounted disk and sync log screenshot
9. iSCSI session or SAN target screenshot
10. Veeam repository configuration screenshot
11. Veeam protection group screenshot
12. GPO certificate deployment screenshot
13. browser proof for Lumora HTTPS

## 6. Practical writing target

To feel comparable to Site 1, Site 2 should aim for:
- more figures with captions
- more tables with operational meaning
- more “why this design was chosen” paragraphs
- more appendix detail
- more operations-oriented content, not just build notes

In short:
- Site 2 is not missing because the environment is weak
- it is missing because the documentation still under-represents the amount of work that was actually completed

## 7. Recommendation

The next documentation revision should not start from scratch.  
It should:

1. keep the current Site 2 draft structure
2. expand each major section with at least:
   - one table
   - one figure
   - one explanatory paragraph
3. embed the identified screenshots
4. add appendix tables and demo/operations guidance

That approach will close the gap much faster than trying to write an entirely new document in one pass.
