---
title: "Site 2 Demonstration and Operations Runbook"
subtitle: "Companion Document for Final Presentation and Operational Walkthrough"
author:
  - "Raspberry Pioneers"
date: "March 23, 2026"
toc: true
toc-title: "Contents"
---

# Site 2 Demonstration and Operations Runbook

## Purpose

This companion document is separate from the formal technical documentation. Its purpose is to organize the final walkthrough of Site 2 so the team can present the strongest evidence in a clean, efficient order.

## Pre-Run Preparation

- Confirm that authorized administrative access to at least one Site 2 jump service is working.
- Open the OPNsense management view needed to explain segmentation, NAT, and inter-site policy.
- Open one Company 2 identity node and prepare the DNS proof for both required hostnames.
- Open `S2-Ubuntu-Client` and `C2LinuxClient` so both client perspectives can be shown quickly.
- Prepare `C2FS` commands or screenshots for iSCSI, mount, share definitions, and sync logs.
- Prepare the Veeam console page that shows repository, protected systems, and offsite-copy evidence.

## Recommended Walkthrough Order

### 1. Entry and Control Path

Show the authorized administrative entry point to Site 2 and explain that the environment is intentionally managed through jump services instead of broad direct server exposure.

### 2. Segmentation and Firewall Design

Show OPNsense interfaces, aliases, and inter-site rules. Explain the separation of MSP, Company 1, Company 2, DMZ, and isolated storage paths.

### 3. Company 2 Identity Services

Show `C2IdM1` or `C2IdM2` with Samba AD, DHCP, and DNS evidence. Highlight that both required web hostnames are present and that Company 1 remains visible in the Site 2 namespace.

### 4. Company 1 Presence in Site 2

Show cross-site reachability and the Company 1 internal web path. Use this moment to correct any assumption that Site 2 is only about Company 2.

### 5. Company 1 Client Perspective

From `S2-Ubuntu-Client`, show access to both:

- `https://c1-webserver.c1.local`
- `https://c2-webserver.c2.local`

### 6. Company 2 Client Perspective

From `C2LinuxClient`, show identity proof and access to the same two hostnames. This is one of the strongest end-user outcomes in the environment.

### 7. Storage and SAN Evidence

Show `C2FS` iSCSI session, mounted storage, share definitions, and synchronization logs. Pair this with the `C1SAN` and `C2SAN` interface screenshots to explain why storage is isolated.

### 8. Backup and Offsite Protection

Show the Veeam repository, protected workload list, file-share backup evidence, and the offsite-copy relationship to Site 1.

## Key Messages To Emphasize

- Site 2 is a multi-role service site for MSP, Company 1, and Company 2.
- Both required web hostnames are accessible from both company perspectives.
- Storage and backup are separate design layers: sync, SAN delivery, backup repository, and offsite copy.
- The environment is segmented and supportable, not flat or improvised.

## Fast Fallback Order

If time becomes short or a service console is slow to load, prioritize the following proof points:

1. OPNsense segmentation view
2. Company 2 identity and DNS view
3. Dual-client hostname proof
4. `C2FS` iSCSI and share proof
5. Veeam repository and offsite-copy proof

## Final Note

This runbook is intentionally separate from the formal technical documentation so the main documentation remains fully professional, architecture-focused, and suitable for handover or client review.
