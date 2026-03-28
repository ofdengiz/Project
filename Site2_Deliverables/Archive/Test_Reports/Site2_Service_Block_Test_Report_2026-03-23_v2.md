# Site 2 Service Block Test Report

Date: 2026-03-23  
Test method: read-only validation only  
Execution style: evidence collected from approved jump paths and direct read-only service probes

## Scope

This test report adapts the Site 1 service block checklist format for Site 2 and records the final read-only validation state of the environment as of March 23, 2026, while also incorporating the later same-day Veeam remediation outcome so the backup conclusion matches the final working state. No configuration changes were made during the original read-only pass. The goal was to confirm that Site 2 core services, cross-site dependencies, and final demo paths were healthy enough to support handover and presentation.

## Approved Validation Paths

- Local workstation to MSP Ubuntu jump over Tailscale and SSH
- Existing Windows jump evidence for approved GUI-oriented tasks
- Read-only SSH into Site 2 Linux systems from the Ubuntu jump
- Read-only HTTP, HTTPS, DNS, and TCP reachability probes from the Ubuntu jump
- Existing final-state implementation evidence where a GUI-only artifact was more appropriate than a synthetic probe

## Executive Summary

- Company 2 identity, DNS, and DHCP services tested healthy on both Samba AD nodes.
- Cross-site reachability from the Site 2 admin path to Company 1 infrastructure was healthy on the required ports.
- Internal hostname-based HTTPS for both tenant web names was healthy from the Ubuntu jump.
- Raw IP access to the Site 2 internal web mirrors returned `404`, which matches the final hostname-only hardening model.
- The Company 2 file-service data volume, published roots, and Site 1 to Site 2 sync workflow all tested healthy.
- Site 2 Veeam management listeners existed and the later live troubleshooting pass closed the remaining control-path issues between protected hosts and `S2Veeam`.
- A small number of rows remain `REVIEW` only because they need GUI screenshots or interactive user-session proof rather than non-interactive read-only probing.

## Validation Results by Service Block

## Service Block 1: Remote Access, DHCP, Account Administration

### PASS

- `C2IdM1`, `C2IdM2`, `C2FS`, and `C2LinuxClient` all accepted read-only SSH from the approved Ubuntu jump path.
- `Jump64` responded on TCP `3389`, confirming the Windows jump remained available for GUI-based demo tasks.
- `isc-dhcp-server` returned `active` on both `C2IdM1` and `C2IdM2`.
- `samba-tool drs showrepl` showed successful replication with `0 consecutive failure(s)`.
- `samba-tool user list` and `samba-tool group list` confirmed the expected tenant users and the `c2_file_users` group.
- `C2LinuxClient` resolved both `c1-webserver.c1.local` and `c2-webserver.c2.local` with the expected dual-record results.

### Cross-Site PASS

- From the Site 2 admin path, TCP connectivity to `C1DC1`, `C1DC2`, the Site 2-hosted `C1` web mirror, and `C1LinuxClient` was healthy on the expected support ports.

## Service Block 2: DNS and HTTPS

### PASS

- `C2IdM1` and `C2IdM2` both returned the expected dual A records for `c2-webserver.c2.local`.
- `C2IdM1` and `C2IdM2` both returned the expected dual A records for `c1-webserver.c1.local`, confirming the Company 1 mini-zone state on the Company 2 DNS side.
- From the Ubuntu jump, `c1-webserver.c1.local` and `c2-webserver.c2.local` both resolved and returned `HTTP 200` over HTTPS.
- Pinned hostname tests proved the Site 2 mirrors answered correctly:
  - `c1-webserver.c1.local -> 172.30.65.162` returned `HTTP/2 200`
  - `c2-webserver.c2.local -> 172.30.65.170` returned `HTTP/1.1 200 OK`
- Raw IP hardening also behaved correctly:
  - `https://172.30.65.162` returned `404`
  - `https://172.30.65.170` returned `404`
  - `http://172.30.65.170` returned `404`
- Internal OPNsense management responded with `HTTP 403` and TCP `53` was reachable, confirming the management plane was present without exposing the GUI anonymously.

### REVIEW

- `curl -I https://clearroots.omerdengiz.com` from the Ubuntu jump returned `Could not resolve host`.
- This does not prove the public site is down. It more likely reflects the current DNS policy on the jump host. Public AWS proof should therefore come from an external browser screenshot, Route53 evidence, or an AWS console capture rather than from this internal jump-only probe.

## Service Block 3: Inter-Site and Management Paths

### PASS

- Dual-record internal web behavior was consistent with the intended design:
  - hostname-pinned requests to the Site 2 mirrors returned `200`
  - raw IP requests returned `404`
- The Ubuntu jump could reach `S2Veeam` on TCP `445`, `9392`, and `5985`.
- These results support the final statement that the Ubuntu jump is the cleanest and most reliable Site 2 validation vantage point.

## Service Block 4: File Services and Replication

### PASS

- `C2FS` showed `/dev/sdb` mounted read-write on `/mnt/c2_public`.
- `/mnt/c2_public`, `/mnt/c2_public/Public`, and `/mnt/c2_public/Private` were present on the mounted data volume.
- The latest sync log entries showed:
  - pull from `172.30.64.146:/mnt/sync_disk/Public`
  - pull from `172.30.64.146:/mnt/sync_disk/Private`
  - `Sync completed successfully`

### REVIEW

- Anonymous `smbclient -L localhost -N` listing on `C2FS` showed `C2_Public` and `IPC$`, but that is not enough by itself to prove the final private-share publication model. An authenticated screenshot is recommended for the appendix.
- Non-interactive probing on `C2LinuxClient` did not return CIFS/NFS mount evidence in `findmnt` or share lines in `/etc/fstab`. This row should be closed with an interactive user-session screenshot during the live walkthrough.
- Per-user private-share isolation on `C2LinuxClient` was intentionally left as an interactive follow-up item. It should be shown with `employee1` and `employee2` contexts during the final demo.

## Service Block 5: Veeam and Miscellaneous Evidence

### PASS

- `S2Veeam` responded on the expected management and SMB ports from the Ubuntu jump during the original read-only pass.
- `Get-NetTCPConnection` on `S2Veeam` later confirmed that `10005` and `10006` were listening locally.
- A dedicated Windows Firewall allow rule for `10005-10006` was added successfully during live remediation.

### REVIEW

- Final MSP Windows jump DNS order and MSP Ubuntu jump resolver-config screenshots should still be collected so the demo appendix shows exactly which resolver paths were used.

## Overall Assessment

Site 2 passed the important read-only service tests needed for a final demo and handover:

- tenant identity healthy
- internal DNS healthy
- internal HTTPS healthy
- cross-site internal web behavior healthy
- file replication healthy
- backup host listeners and protected-host path validated after remediation

The remaining `REVIEW` items are documentation-evidence gaps rather than core service failures. Core Site 2 identity, DNS, HTTPS, file replication, and Veeam backup paths are in a usable final state. The most valuable remaining additions are still the final GUI screenshots from the Windows jump, Ubuntu jump, and Veeam console.
