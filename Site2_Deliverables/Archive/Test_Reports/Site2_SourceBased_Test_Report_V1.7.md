# Site 2 Source-Based Test Report

Date: 2026-03-24  
Test style: broad read-only validation  
Evidence basis: course documents, Site 2 environment evidence, and live Site 2 validation

## 1. Scope

This test report was structured to match the spirit of the provided `Site1_test_V0.1.xlsx` while aligning the validation with the Service Blocks model, the project brief, the OPNsense export, and the current Site 2 environment evidence.

The goal was to validate Site 2 as a complete service environment. The validation was approached from project-delivery, network-engineering, and systems-administration perspectives at the same time. Test coverage therefore included:

- MSP administrative entry and controlled management paths
- Company 1 and Company 2 service visibility inside the same Site 2 operating model
- jump-host access, segmentation, storage, iSCSI, backup, and remote management behavior
- evidence quality appropriate for a professional technical handover and test record

## 2. Source Basis

This test report was prepared from:

- `25F-Project (1).pdf`
- the week 9 technical-report PDF
- `ServiceBlocks.pdf`
- `Site1_Final_Documentation_V3.0.docx`
- `Site1_test_V0.1.xlsx`
- the week 3 to week 7 notes
- `config-rp-msp-gateway.et.lab-20260323222847.xml`
- the Site 2 VM inventory and SAN screenshots
- live Site 2 read-only validation performed on March 23 and March 24, 2026


## 3. Validation Paths Used

- Approved remote-management access to Site 2 jump services
- `MSPUbuntuJump` as the primary CLI bastion for internal validation
- Direct read-only SSH from the bastion to Company 2 Linux systems
- MSP-origin read-only validation from `MSPUbuntuJump` into the Company 1 stack
- Direct read-only client validation on `S2-Ubuntu-Client` and `C2LinuxClient`
- OPNsense XML analysis for segmentation, NAT, alias, and inter-site policy validation

## 4. Executive Summary

The March 23-24 validation showed that Site 2 is operational across its main internal service paths and can be described as a coordinated MSP, Company 1, and Company 2 service environment.

### High-confidence PASS findings

- both jump systems were reachable from the local workstation
- OPNsense responded on the internal management path and its XML export confirmed deliberate segmentation and limited edge exposure
- Company 1 domain, file, web, client, and storage roles were all evidenced within the Site 2 model
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

- MSP management and recovery workflows
- Company 1 domain, file, web, client, and storage behavior inside the Site 2 operating model
- Company 2 tenant services

## 5. Detailed Results by Validation Area

## 5.1 Management and Entry Paths

### PASS

- Approved remote access to the Site 2 jump services succeeded.
- The jump systems remained the correct administrative entry points for the environment.
- The bastion-first design remains consistent with the OPNsense exposure model and the project intent.

## 5.2 MSP Entry, OPNsense, Segmentation, and Bastion-Controlled Access

### PASS

- OPNsense returned `HTTP 403` on the internal management address, which is consistent with a present but non-anonymous management plane.
- OPNsense TCP `53` was reachable from `MSPUbuntuJump`.
- The XML export showed these routed interfaces: `WAN`, `MSP`, `C1DMZ`, `C1LAN`, `C2DMZ`, `C2LAN`, and `SITE1_OVPN`.
- The XML export showed only two WAN NAT publications: Windows jump RDP on `33464` and `MSPUbuntuJump` SSH on `33564`.
- The XML export showed inter-site rules for Company 1, Company 2, and Veeam copy traffic.
- The XML export showed cross-site HTTP/HTTPS rules for Site 1 access to the opposite site's hosted web service.

## 5.3 Company 1 Service Stack Within Site 2

### PASS

- `C1DC1` and `C1DC2` were reachable from `MSPUbuntuJump` on `53`, `88`, `389`, `445`, `3389`, and `5985`.
- `C1FS` was reachable from `MSPUbuntuJump` on `445` and `3389`.
- `C1WebServer` was reachable from `MSPUbuntuJump` on `443`, `3389`, and `5985`, and responded successfully by hostname on the Site 2 path while the raw IP returned `404`.
- `S2-Ubuntu-Client` operated as the active Company 1 Linux client role and successfully consumed both required hostnames.
- `C1WindowsClient` was present in the Site 2 environment inventory evidence.
- `C1SAN` was evidenced as an isolated Company 1 storage segment with no general-purpose routed exposure from the MSP management plane.
- Company 1 DNS records were visible on both Company 2 identity nodes.

### Interpretation

The current evidence shows that Company 1 is not represented in Site 2 by a single mirrored web page alone. It is represented by domain services, file-service adjacency, client endpoints, hostname-based web delivery, and isolated storage design. The strongest proof now comes from a management-first validation path that begins in MSP and then verifies Company 1 services as part of the overall Site 2 operating model.

## 5.4 Company 2 Identity, DNS, and DHCP

### PASS

- `C2IdM1` returned `active` for `samba-ad-dc`.
- `C2IdM2` returned `active` for `samba-ad-dc`.
- `C2IdM1` returned `active` for `isc-dhcp-server`.
- `C2IdM2` returned `active` for `isc-dhcp-server`.
- Both identity nodes returned dual A records for `c1-webserver.c1.local`.
- Both identity nodes returned dual A records for `c2-webserver.c2.local`.
- The shared-forest design note is consistent with the observed cross-domain DNS visibility.

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
- Environment screenshot evidence identified `C1SAN` at `172.30.65.186/29` and `C2SAN` at `172.30.65.194/29`.
- Available environment evidence shows that both SAN systems are isolated and bridged only to the file servers.

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
- Available backup design evidence indicates that Veeam protects 10 machines, stores file-share backup data, and copies data offsite to Site 1.

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
- interactive share-access proof under a client session
- shared-forest administrative proof if the professor asks for directory-topology visuals
- OPNsense GUI proof to complement the XML export

### Partially evidenced items

- the project brief mentions Linux-client SSH accessibility from the college network; the current pass proved the administrative path and internal accessibility, but did not separately re-run that exact external-college-path scenario

## 5.11 Recovery and DR Interpretation

This Site 2 environment should be explained as having three different continuity layers:

- live service continuity through routed access, dual identity services, and cross-site rules
- content continuity through the Site 1 to Site 2 synchronization model on `C2FS`
- recovery continuity through Veeam backup, file-share backup, and offsite copy to Site 1

That distinction matters during final presentation and assessment. A synchronized file path is not the same thing as a backup repository, and a backup repository is not the same thing as a routed live-service path. The Site 2 design is stronger because it uses all three ideas together.

## 6. Overall Assessment

Site 2 passed the most important broad read-only tests for operational and presentation readiness:

- bastion access healthy
- OPNsense segmentation and routed design coherent
- Company 2 identity healthy
- Company 1 still visible in Site 2 scope
- storage and iSCSI healthy
- dual-client web behavior healthy
- Veeam host reachability healthy

The remaining open items are documentation-evidence gaps, not broad internal-service failures. The test position is therefore strong enough for final submission and can be made excellent with a small number of targeted screenshots.

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
- `tmp/site2_company1_readonly_validation_2026-03-24.txt`
- `tmp/site2_company1_readonly_validation_2026-03-24.json`
- `tmp/s2_ubuntu_client_web_dualcheck_2026-03-23.json`
- `tmp/c2linuxclient_web_dualcheck_2026-03-23.json`
- `Site2test_service/04_Results/20260323_193411_Summary.txt`
