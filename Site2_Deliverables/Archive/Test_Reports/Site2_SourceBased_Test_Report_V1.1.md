# Site 2 Source-Based Test Report

Date: 2026-03-23  
Test style: broad read-only validation  
Evidence basis: only the source documents named in the current request plus live Site 2 validation

## 1. Scope

This test report was built to match the spirit of the provided `Site1_test_V0.1.xlsx` while also respecting the Service Blocks model and the project brief. The goal was not only to test Company 2 services, but to confirm the broader Site 2 story implied by the supplied documents:

- Site 2 is the MSP public-cloud site
- both Company 1 and Company 2 must remain visible in the demo scope
- jump-host access, storage, iSCSI, backup, and remote management matter as much as individual service-state checks

## 2. Source Basis

This test report was prepared from:

- `25F-Project (1).pdf`
- `09 - CST8248 – Emerging Technologies (2).pdf`
- `ServiceBlocks.pdf`
- `Site1_Final_Documentation_V3.0.docx`
- `Site1_test_V0.1.xlsx`
- the week 3 to week 7 notes
- live Site 2 read-only validation performed on March 23, 2026

Earlier Site 2 draft reports were not used as source content for this version.

## 3. Validation Paths Used

- Local workstation to Site 2 jump systems over Tailscale
- Local workstation to teacher-edge published jump services
- Ubuntu jump as the primary CLI bastion for internal validation
- Direct read-only SSH from the bastion to Company 2 Linux systems
- Local CLI checks for public-DNS behavior

## 4. Executive Summary

The March 23 read-only validation showed that Site 2 is operational across the main internal demo paths and should not be treated as Company 2-only.

### High-confidence PASS findings

- both jump systems were reachable from the local workstation
- OPNsense responded on the internal management path
- Company 1 cross-site administrative targets were reachable from the Ubuntu jump
- both Company 2 identity nodes were healthy for Samba AD, DHCP, and DNS
- `C2LinuxClient` domain identity lookup worked for `employee1@c2.local` and `employee2@c2.local`
- `C2FS` showed active iSCSI-backed storage, valid SMB share definitions, and successful synchronization
- Company 1 and Company 2 internal web services both returned `200` by hostname and `404` by raw IP
- `S2Veeam` was reachable on `445`, `3389`, `9392`, `5985`, `10005`, and `10006`

### REVIEW items

- interactive user-session proof for share mounting or per-user isolation on `C2LinuxClient`
- GUI-based Veeam console, repository, and job-history evidence
- browser or cloud-console proof for the Site 2 public-cloud deliverable

### Important interpretation

The broad test set confirms that Site 2 currently carries:

- Company 2 tenant services
- Company 1 cross-site or mirrored demo behavior
- MSP management and recovery workflows

## 5. Detailed Results by Validation Area

## 5.1 Management and Entry Paths

### PASS

- Local workstation to Windows jump over Tailscale succeeded.
- Local workstation to Ubuntu jump over Tailscale succeeded.
- Teacher-edge access to the Windows jump succeeded on `10.50.17.31:33464`.
- Teacher-edge access to the Ubuntu jump succeeded on `10.50.17.31:33564`.

### REVIEW

- Teacher-edge public web test on `10.50.17.31:33465` timed out.
- This should be treated as a provisional public edge path, not as proof that internal web services are down.

## 5.2 OPNsense, Routing, and Bastion-Controlled Access

### PASS

- OPNsense returned `HTTP 403` on the internal management address, which is consistent with a present but non-anonymous management plane.
- OPNsense TCP `53` was reachable from the Ubuntu jump.
- These results support using the jump-host path as the primary demo and support route into Site 2.

## 5.3 Company 1 Presence in the Site 2 Scope

### PASS

- Cross-site reachability from Site 2 to `C1DC1` on `3389` and `445` succeeded.
- Cross-site reachability from Site 2 to `C1DC2` on `3389` and `445` succeeded.
- Cross-site reachability from Site 2 to `C1FS` on `445` succeeded.
- Cross-site reachability from Site 2 to `C1LinuxClient` on `22` succeeded.
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

## 5.5 Company 2 Client and User Validation

### PASS

- `C2LinuxClient` reported valid realm membership in `C2.LOCAL`.
- `getent passwd employee1@c2.local` returned a valid user record.
- `getent passwd employee2@c2.local` returned a valid user record.
- `C2LinuxClient` resolved both `c1-webserver.c1.local` and `c2-webserver.c2.local`.

### REVIEW

- No persistent CIFS or NFS mount entries were visible in the current non-interactive context.
- A final interactive screenshot is still recommended for file-share presentation or mounted-share proof.

## 5.6 Storage, iSCSI, and File Services

### PASS

- `C2FS` returned `active` for `smbd`.
- `/mnt/c2_public` was mounted from `/dev/sdb`.
- The storage transport showed as `iscsi`.
- `iscsiadm -m session` reported an active session to `172.30.65.194:3260` for `iqn.2024-03.org.clearroots:c2san`.
- `C2_Public` and `C2_Private` share definitions were visible in the effective Samba configuration.
- The latest sync log showed `Sync completed successfully`.

## 5.7 Internal Web Services

### PASS

- Company 1 internal web on the Site 2 path returned `HTTP 200` when accessed by hostname.
- Company 1 internal web on the Site 2 path returned `HTTP 404` when accessed by raw IP.
- Company 2 internal web on the Site 2 path returned `HTTP 200` when accessed by hostname.
- Company 2 internal web on the Site 2 path returned `HTTP 404` when accessed by raw IP.

## 5.8 Backup and Recovery Readiness

### PASS

- `S2Veeam` was reachable on TCP `445`.
- `S2Veeam` was reachable on TCP `3389`.
- `S2Veeam` was reachable on TCP `9392`.
- `S2Veeam` was reachable on TCP `5985`.
- `S2Veeam` was reachable on TCP `10005`.
- `S2Veeam` was reachable on TCP `10006`.

### REVIEW

- Current read-only proof is control-path oriented, not console oriented.
- Final submission should add one GUI screenshot showing the backup host, repository, and current job state.

## 5.9 Public Cloud and External Evidence

### REVIEW

- `nslookup clearroots.omerdengiz.com 8.8.8.8` returned `Query refused`.
- `nslookup clearroots.omerdengiz.com 1.1.1.1` returned `Query refused`.
- Local `curl` could not resolve `clearroots.omerdengiz.com`.

These results do not prove the public-cloud deliverable is absent. They prove only that the current CLI path could not validate it. This should be closed with browser or cloud-console evidence in the final package.

## 6. Overall Assessment

Site 2 passed the most important broad read-only tests for demo readiness:

- bastion access healthy
- Company 2 identity healthy
- Company 1 still present in Site 2 scope
- storage and iSCSI healthy
- internal web behavior healthy
- Veeam host reachability healthy

The remaining open items are documentation-evidence gaps, not broad internal-service failures.

## 7. Recommended Final Screenshot Additions

- OPNsense rule or route evidence
- `C2IdM1` and `C2IdM2` service screenshots
- `C2FS` iSCSI session, mount, share definitions, and sync-log screenshots
- `C2LinuxClient` interactive share-access screenshot
- Company 1 and Company 2 internal web screenshots
- Veeam console or repository screenshot
- external browser or cloud-console screenshot for the public-cloud deliverable

## 8. Internal Evidence Files Generated

- `tmp/site2_live_validation_2026-03-23.txt`
- `tmp/site2_demo_scenarios_2026-03-23.txt`
- `Site2test_service/04_Results/20260323_193411_Summary.txt`
