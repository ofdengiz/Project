# Site 2 Source-Based Test Report

Date: 2026-03-23  
Test style: broad read-only validation  
Evidence basis: only the source documents named in the current request, user-supplied Site 2 evidence, and live Site 2 validation

## 1. Scope

This test report was rebuilt to match the spirit of the provided `Site1_test_V0.1.xlsx` while respecting the Service Blocks model, the project brief, the OPNsense export, and the user's Site 2 clarifications.

The goal was not only to test Company 2 services. It was to confirm the broader Site 2 story implied by the supplied material:

- Site 2 is an MSP-operated service site, not a Company 2-only lab
- both Company 1 and Company 2 remain visible in the demo scope
- jump-host access, segmentation, storage, iSCSI, backup, and remote management matter as much as simple service-state checks
- the final evidence package should read like a real technical handover and test record

## 2. Source Basis

This test report was prepared from:

- `25F-Project (1).pdf`
- the week 9 technical-report PDF
- `ServiceBlocks.pdf`
- `Site1_Final_Documentation_V3.0.docx`
- `Site1_test_V0.1.xlsx`
- the week 3 to week 7 notes
- `config-rp-msp-gateway.et.lab-20260323222847.xml`
- the user-supplied Site 2 VM inventory and SAN screenshots
- live Site 2 read-only validation performed on March 23, 2026

Earlier Site 2 draft reports were not used as source content for this version.

## 3. Validation Paths Used

- Local workstation to Site 2 jump systems over Tailscale
- Local workstation to teacher-edge published jump services
- Ubuntu jump as the primary CLI bastion for internal validation
- Direct read-only SSH from the bastion to Company 2 Linux systems
- Direct read-only client validation on `S2-Ubuntu-Client` and `C2LinuxClient`
- OPNsense XML analysis for segmentation, NAT, alias, and inter-site policy validation

## 4. Executive Summary

The March 23 validation showed that Site 2 is operational across the main internal demo paths and should not be documented as Company 2-only.

### High-confidence PASS findings

- both jump systems were reachable from the local workstation
- OPNsense responded on the internal management path and its XML export confirmed deliberate segmentation and limited edge exposure
- Company 1 cross-site administrative targets were reachable from the Ubuntu jump
- both Company 2 identity nodes were healthy for Samba AD, DHCP, and DNS
- `S2-Ubuntu-Client` and `C2LinuxClient` both reached `c1-webserver.c1.local` and `c2-webserver.c2.local`
- `C2LinuxClient` domain identity lookup worked for `employee1@c2.local` and `employee2@c2.local`
- `C2FS` showed active iSCSI-backed storage, valid SMB share definitions, and successful synchronization
- `S2Veeam` was reachable on its main management and agent ports

### Review-only evidence gaps

- final Veeam console screenshot showing jobs, repository, and offsite copy
- one GUI OPNsense screenshot to complement the XML-backed findings
- one interactive share-access screenshot from a client session
- optional forest-management screenshot if the team wants explicit GUI proof of the shared-forest design

### Important interpretation

The broad test set confirms that Site 2 currently carries:

- Company 2 tenant services
- Company 1 cross-site and mirrored demo behavior
- MSP management and recovery workflows

## 5. Detailed Results by Validation Area

## 5.1 Management and Entry Paths

### PASS

- Local workstation to the Windows jump over Tailscale succeeded.
- Local workstation to the Ubuntu jump over Tailscale succeeded.
- Teacher-edge access to the Windows jump succeeded on `10.50.17.31:33464`.
- Teacher-edge access to the Ubuntu jump succeeded on `10.50.17.31:33564`.

### REVIEW

- The teacher-edge public web test on `10.50.17.31:33465` timed out.
- This is not part of the final Site 2 hostname scope and should not be used as the main proof for tenant web health.

## 5.2 OPNsense, Segmentation, and Bastion-Controlled Access

### PASS

- OPNsense returned `HTTP 403` on the internal management address, which is consistent with a present but non-anonymous management plane.
- OPNsense TCP `53` was reachable from the Ubuntu jump.
- The XML export showed these routed interfaces: `WAN`, `MSP`, `C1DMZ`, `C1LAN`, `C2DMZ`, `C2LAN`, and `SITE1_OVPN`.
- The XML export showed only two WAN NAT publications: Windows jump RDP on `33464` and Ubuntu jump SSH on `33564`.
- The XML export showed inter-site rules for Company 1, Company 2, and Veeam copy traffic.
- The XML export showed cross-site HTTP/HTTPS rules for Site 1 access to the opposite site's hosted web service.

## 5.3 Company 1 Presence in the Site 2 Scope

### PASS

- Cross-site reachability from Site 2 to `C1DC1` on `3389` and `445` succeeded.
- Cross-site reachability from Site 2 to `C1DC2` on `3389` and `445` succeeded.
- Cross-site reachability from Site 2 to `C1FS` on `445` succeeded.
- Cross-site reachability from Site 2 to the Company 1 client at `172.30.65.36` on `22` succeeded.
- Company 1 DNS records were visible on both Company 2 identity nodes.
- The Company 1 internal web hostname on the Site 2 path returned `HTTP 200`, while the raw IP returned `HTTP 404`.

## 5.4 Company 2 Identity, DNS, and DHCP

### PASS

- `C2IdM1` returned `active` for `samba-ad-dc`.
- `C2IdM2` returned `active` for `samba-ad-dc`.
- `C2IdM1` returned `active` for `isc-dhcp-server`.
- `C2IdM2` returned `active` for `isc-dhcp-server`.
- Both identity nodes returned dual A records for `c1-webserver.c1.local`.
- Both identity nodes returned dual A records for `c2-webserver.c2.local`.
- The user-provided shared-forest note is consistent with the observed cross-domain DNS visibility.

## 5.5 Company 1 Client Validation on `S2-Ubuntu-Client`

### PASS

- `S2-Ubuntu-Client` identified itself as `S2-Ubuntu-Client`.
- The active identity context was `administrator@c1.local`.
- Realm details showed `C1.LOCAL` / `c1.local` membership.
- `nslookup c1-webserver.c1.local` returned both Site 1 and Site 2 A records.
- `nslookup c2-webserver.c2.local` returned both Site 1 and Site 2 A records.
- `curl -k -I https://c1-webserver.c1.local` returned `HTTP/2 200`.
- `curl -k -I https://c2-webserver.c2.local` returned `HTTP/1.1 200 OK`.

## 5.6 Company 2 Client Validation on `C2LinuxClient`

### PASS

- `C2LinuxClient` reported valid realm membership in `C2.LOCAL`.
- `getent passwd employee1@c2.local` returned a valid user record.
- `getent passwd employee2@c2.local` returned a valid user record.
- `C2LinuxClient` resolved both `c1-webserver.c1.local` and `c2-webserver.c2.local`.
- `curl -k -I https://c1-webserver.c1.local` returned `HTTP/2 200`.
- `curl -k -I https://c2-webserver.c2.local` returned `HTTP/1.1 200 OK`.

### REVIEW

- No persistent CIFS or NFS mount entries were visible in the current non-interactive context.
- A final interactive screenshot is still recommended for file-share presentation or mounted-share proof.

## 5.7 Storage, iSCSI, and Isolated SAN Design

### PASS

- `C2FS` returned `active` for `smbd`.
- `/mnt/c2_public` was mounted from `/dev/sdb`.
- The storage transport showed as `iscsi`.
- `iscsiadm -m session` reported an active session to `172.30.65.194:3260` for `iqn.2024-03.org.clearroots:c2san`.
- `C2_Public` and `C2_Private` share definitions were visible in the effective Samba configuration.
- The latest sync log showed `Sync completed successfully`.
- User-supplied screenshot evidence identified `C1SAN` at `172.30.65.186/29` and `C2SAN` at `172.30.65.194/29`.
- User clarification stated that both SAN systems are isolated and bridged only to the file servers.

## 5.8 Internal Web Services

### PASS

- Company 1 internal web on the Site 2 path returned `HTTP 200` when accessed by hostname.
- Company 1 internal web on the Site 2 path returned `HTTP 404` when accessed by raw IP.
- Company 2 internal web on the Site 2 path returned `HTTP 200` when accessed by hostname.
- Company 2 internal web on the Site 2 path returned `HTTP 404` when accessed by raw IP.
- The same two hostnames were successfully reached from both the Company 1 and Company 2 client perspectives.

## 5.9 Backup and Offsite-Protection Readiness

### PASS

- `S2Veeam` was reachable on TCP `445`.
- `S2Veeam` was reachable on TCP `3389`.
- `S2Veeam` was reachable on TCP `9392`.
- `S2Veeam` was reachable on TCP `5985`.
- `S2Veeam` was reachable on TCP `10005`.
- `S2Veeam` was reachable on TCP `10006`.
- The OPNsense XML defined `S2_VEEAM`, `SITE1_VEEAM`, `VEEAM_COPY_PORTS`, and a static route for Site 1 Veeam traffic.
- The user-provided environment clarification states that Veeam protects 10 machines, stores file-share backup data, and copies data offsite to Site 1.

### REVIEW

- Current read-only proof is architecture and control-path oriented, not console oriented.
- Final submission should add one GUI screenshot showing the backup host, repository, protected workload list, and current job state.

## 5.10 Requirement Coverage Interpretation

The broad validation set now supports a more formal requirement interpretation instead of a simple pass list.

### Proven in the current evidence set

- secure jump-host entry and controlled edge exposure
- segmented Site 2 networking with OPNsense-backed evidence
- Company 2 identity, DNS, and DHCP functionality
- Company 1 presence within the Site 2 scope
- isolated SAN-backed `C2FS` storage and synchronized file-service behavior
- dual-client access to both required hostnames
- Veeam control-path reachability and inter-site backup architecture evidence

### Strongly supported but still worth screenshot closure

- Veeam repository and offsite-copy presentation
- interactive share-access proof under a user session
- shared-forest administrative proof if the professor asks for directory-topology visuals
- OPNsense GUI proof to complement the XML export

### Partially evidenced items

- the project brief mentions Linux-client SSH accessibility from the college network; the current pass proved the administrative path and internal accessibility, but did not separately re-run that exact external-college-path scenario

## 5.11 Recovery and DR Interpretation

This Site 2 environment should be explained as having three different continuity layers:

- live service continuity through routed access, dual identity services, and cross-site rules
- content continuity through the Site 1 to Site 2 synchronization model on `C2FS`
- recovery continuity through Veeam backup, file-share backup, and offsite copy to Site 1

That distinction matters during demo and marking. A synchronized file path is not the same thing as a backup repository, and a backup repository is not the same thing as a routed live-service path. The Site 2 design is stronger because it uses all three ideas together.

## 5.12 Suggested Demo Run Order

1. Enter through one jump host and explain that only bastion services are edge-published.
2. Show OPNsense interfaces, aliases, NAT, and OpenVPN or inter-site policy.
3. Show `C2IdM1` or `C2IdM2` health plus dual DNS records for both web hostnames.
4. Show that Company 1 still exists in Site 2 through cross-site reachability and Company 1 web proof.
5. Show `S2-Ubuntu-Client` reaching both required hostnames.
6. Show `C2LinuxClient` identity proof plus access to both required hostnames.
7. Show `C2FS` iSCSI session, mount, shares, sync log, and the SAN screenshots.
8. Show `S2Veeam` repository, protected workload count, and offsite-copy proof.

## 6. Overall Assessment

Site 2 passed the most important broad read-only tests for demo readiness:

- bastion access healthy
- OPNsense segmentation and routed design coherent
- Company 2 identity healthy
- Company 1 still visible in Site 2 scope
- storage and iSCSI healthy
- dual-client web behavior healthy
- Veeam host reachability healthy

The remaining open items are documentation-evidence gaps, not broad internal-service failures. The test position is therefore strong enough for demo week and can be made excellent with a small number of targeted screenshots.

## 7. Recommended Final Evidence Additions

- OPNsense GUI view showing interfaces, aliases, NAT, or OpenVPN rules
- Proxmox inventory screenshot with VM names visible
- `C2IdM1` and `C2IdM2` service screenshots
- `C2FS` iSCSI session, mount, share definitions, and sync-log screenshots
- `C1SAN` and `C2SAN` interface screenshots
- `S2-Ubuntu-Client` screenshot showing both required web hostnames
- `C2LinuxClient` screenshot showing identity proof and both required web hostnames
- Veeam console or repository screenshot showing backup and offsite-copy evidence
- optional shared-forest or domain-topology screenshot if the professor asks how `c1.local` and `c2.local` relate

## 8. Internal Evidence Files Generated

- `tmp/site2_live_validation_2026-03-23.txt`
- `tmp/site2_demo_scenarios_2026-03-23.txt`
- `tmp/s2_ubuntu_client_web_dualcheck_2026-03-23.json`
- `tmp/c2linuxclient_web_dualcheck_2026-03-23.json`
- `Site2test_service/04_Results/20260323_193411_Summary.txt`
