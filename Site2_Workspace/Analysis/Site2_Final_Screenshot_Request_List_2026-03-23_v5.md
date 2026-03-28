# Site 2 Final Screenshot Request List

Date: 2026-03-23

This list is now evidence-driven. Each requested screenshot is tied to a specific section and claim in the revised Site 2 final document. Veeam is intentionally left to the end.

## Priority 1: Route and Firewall Evidence

1. Site 2 OPNsense routed-path proof
   Supports: Section `3.2` and Section `3.10.1`
   Claim proved: inter-site administration, backup copy, and mirrored internal web validation depended on specific routed paths and firewall scope.
   Exact screens needed:
   - `Firewall > Rules > OpenVPN`
   - `Firewall > Rules > C1LAN`
   - `Firewall > Rules > C2LAN`
   - one actual route view such as `System > Routes > Status` or the OPNsense route table page

2. Site 2 OPNsense alias proof
   Supports: Section `3.8` and Section `3.10.1`
   Claim proved: the final backup and cross-site rule design used explicit alias scoping rather than broad unrestricted access.
   Exact screens needed:
   - alias list entry for `S2_VEEAM`
   - alias list entry for `VEEAM_COPY_PORTS`

## Priority 2: File Services and Client Isolation

3. `C2LinuxClient` interactive private-share isolation
   Supports: Section `3.7`
   Claim proved: private storage is presented per user rather than as a flat unrestricted share.
   Exact screens needed:
   - one clean user-context view of the user's own private location
   - one denied or blocked attempt against another user's private location

## Priority 3: Public Cloud Proof

4. External browser proof for `https://clearroots.omerdengiz.com`
   Supports: Section `3.9.1`
   Claim proved: the public ClearRoots website is reachable over HTTPS from a normal external browser path.
   Exact screen needed: browser window with the live site and visible address bar.

5. Route53 hosted-zone record
   Supports: Section `3.9.1`
   Claim proved: the public hostname is intentionally published through Route53 rather than being an ad hoc browser-only proof.
   Exact screen needed: the hosted-zone record showing the final `A` record for `clearroots.omerdengiz.com`.

## Final Pass Only: Veeam

6. `S2Veeam` final job-state proof
   Supports: Section `3.8`
   Claim proved: the final Site 2 backup design is agent-based and operational in the resolved state.
   Exact screens needed:
   - final job list showing the Windows, Linux, and file-share job set
   - one final completed-session or success-history screen

7. `S2Veeam` final repository and listener proof
   Supports: Section `3.8`
   Claim proved: the final Veeam repository and control-path configuration are in the resolved state described in the document.
   Exact screens needed:
   - repository list with the final repository object
   - `Get-NetTCPConnection` output showing listeners on `10005` and `10006`
   - Windows Firewall rule showing the inbound allow for `10005-10006` only if we still want a remediation-proof figure in the appendix

8. Final host-to-VBR connectivity proof
    Supports: Section `3.8`
    Claim proved: the protected-host control path to `S2Veeam` was restored after the final fixes.
    Exact screen needed:
    - one clean `nc -zvw5 172.30.65.180 10005`
    - one clean `nc -zvw5 172.30.65.180 10006`

## Already Collected and Ready to Use

1. `C2IdM1` replication and DNS proof
2. `C2IdM2` replication and DNS proof
3. `C2LinuxClient` hostname resolution proof
4. `C2LinuxClient` SSSD and domain-identity proof
5. `C2WebServer` Docker and hostname-only hardening proof
6. `C2FS` mounted storage and sync-log proof
