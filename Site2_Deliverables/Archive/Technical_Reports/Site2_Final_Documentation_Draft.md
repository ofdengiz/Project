# Public Cloud Infrastructure Deployment

## CST8248 - Emerging Technologies Technical Report

**Design and Implementation of a Site 2 Hybrid Infrastructure Using Proxmox Services, Samba Identity, Veeam Backup, and an AWS-Hosted HTTPS Web Platform**

| Field | Value |
|---|---|
| Course | CST8248 - Emerging Technologies |
| Professor | Denis Latremouille |
| Team Name | Raspberry Pioneers |
| Submission Type | Group Submission |
| Due Date | March 30, 2026 |
| Program | Computer Systems Technology - Networking |
| Institution | Algonquin College |
| Document Version | 1.0 Draft |
| Document Date | March 19, 2026 |
| Intended Audience | Client IT staff, MSP support teams, and Level 4 graduates assuming operations support |

**Team Members:** Bailey Kulla, Elyazid Sidelkheir, Ru Wang, Justin Rosseleve, Yiqin Huang, Omer Deniz

> Report intent: this document is written in a client/MSP handover style, while preserving the formal structure expected in CST8248. It focuses on the Site 2 deliverable, but includes cross-site dependencies wherever Site 2 services rely on Company 1 infrastructure or the inter-site VPN path.

\newpage

# Contents

1. Introduction  
2. Background  
3. Discussion  
   3.1 Environment Overview and Topology  
   3.2 Network Design and IP Addressing Rationale  
   3.3 Identity Infrastructure and Tenant Separation  
   3.4 Platform and Service Choice Rationale  
   3.5 Compute and Virtualization  
   3.6 Identity, DNS, and DHCP Services  
   3.7 Storage and File Services  
   3.8 Backup and Recovery  
   3.9 Value Added Features  
   3.10 Site-to-Site VPN Security and Administrative Access  
   3.11 Maintenance and Daily Duties  
   3.12 Limitations, Risks, and Unresolved Items  
4. Conclusion  
5. Appendices  
6. References  

# List of Figures

**Figure 1.** AWS EC2 instances for the ClearRoots public website  
**Figure 2.** Public ClearRoots HTTPS landing page  
**Figure 3.** Kubernetes nodes and running ClearRoots web pods  
**Figure 4.** Terraform remote state stored in Amazon S3  
**Figure 5.** Route53 public DNS record for `clearroots.omerdengiz.com`  
**Figure 6.** Veeam success history for Site 2 backup operations  
**Figure 7.** Site 2 offsite backup copy folders on the Site 1 SMB repository  
**Figure 8.** Group Policy deployment for the internal Lumora web certificate  

# List of Tables

**Table 1.** Technology stack summary  
**Table 2.** Site 2 core server inventory  
**Table 3.** Network and service path summary  
**Table 4.** Identity services summary  
**Table 5.** Platform and service choice rationale  
**Table 6.** Site 2 protected systems in Veeam  
**Table 7.** AWS public website deployment components  
**Table 8.** Site 2 backup job schedule summary  
**Table A1.** Site 2 network addressing summary  
**Table B1.** DHCP service reference  
**Table C1.** Storage and file-service reference  
**Table D1.** Backup repository reference  

# Executive Summary

This report documents the Site 2 portion of a multi-site infrastructure project designed to support tenant-separated services, centralized identity, file sharing, backup and offsite recovery, and a public HTTPS web presence. The Site 2 environment combines Linux-based identity and file services with VMware-style operational expectations, cross-site administrative access, and backup workflows aligned to enterprise support practices.

At the infrastructure level, Site 2 provides Company 2 identity and DHCP services using Samba Active Directory Domain Controllers, replicated Linux file services, tenant-aware routing through OPNsense, remote administration through Windows and Ubuntu jump systems, and backup orchestration through Veeam Backup and Replication. In addition, Site 2 hosts a public-facing ClearRoots Foundation website in AWS using Terraform, Kubernetes, Docker, Route53, Elastic IP, S3-backed Terraform state, and automated HTTPS publishing through Caddy and Let's Encrypt.

Operationally, the environment progressed through several troubleshooting stages before stabilization. Earlier testing identified issues with Windows jump routing behavior, DMZ web server reachability, C2LinuxClient SSSD identity resolution, and the Site 2 to Site 1 sync path. Those core service issues were later corrected. The final validated state shows healthy Company 2 identity services, restored web reachability, functioning Linux client identity lookup, successful file synchronization, healthy Kubernetes web deployment, and working Veeam local and offsite backup copy jobs.

The final Site 2 design therefore supports four major outcomes:

- reliable tenant services for Company 2 identity, DNS, DHCP, and file access
- cross-site recoverability through backup copy to Site 1
- secure internal and public web publishing paths
- an operations-ready handover model suitable for client support, final demonstration, and future maintenance

# 1. Introduction

The purpose of this document is to describe the deployed Site 2 environment in a form suitable for support handover, academic submission, and demonstration review. Site 2 is not an isolated lab segment; it is part of a broader two-site design where services are intentionally distributed across local tenant systems, shared infrastructure, and inter-site recovery paths.

The report emphasizes the Site 2 responsibilities and outcomes:

- Company 2 identity, DNS, and DHCP services
- Company 2 Linux file services and client access
- Site 2 Veeam backup and offsite copy operations
- public AWS-based ClearRoots web publishing with HTTPS
- cross-site reachability and administrative workflows needed to operate the environment

Where useful, the report also references Company 1 systems, because several Site 2 functions depend on them. These include certificate trust distribution, inter-site backup copy, administrative reachability, and shared testing workflows.

# 2. Background

The broader project goal was to create an MSP-style, tenant-aware infrastructure spanning two sites and two companies. The design required not only local service delivery, but also operational readiness: backups needed to be scheduled and verifiable, web services had to be reachable through approved paths, client access needed to align with identity systems, and remote administration had to remain workable from jump hosts.

Site 2 specifically became the center of three major deliverables:

- Company 2 service hosting and recovery
- Veeam-based backup and offsite copy workflows
- AWS-based public web delivery for the ClearRoots Foundation website

The environment therefore bridges traditional private infrastructure operations and cloud-hosted web publishing. That combination made Site 2 especially important to the overall project because it demonstrates both internal enterprise service management and modern public deployment practices.

### Table 1. Technology stack summary

| Layer | Technologies Used | Site 2 Purpose |
|---|---|---|
| Private compute | Proxmox-hosted virtual machines | Company 2 service hosting, jump systems, backup server |
| Routing and segmentation | OPNsense, multi-path administration | Tenant control, service reachability, MSP access |
| Identity | Samba AD DC, DNS, ISC DHCP | Company 2 directory, naming, and client onboarding |
| File services | Linux SMB services, mounted storage, sync scripting | Public and private shared data for Company 2 |
| Backup | Veeam Backup and Replication | Agent backup, file backup, and offsite copy |
| Cloud hosting | AWS EC2, Route53, S3, Elastic IP | Public ClearRoots web delivery |
| Application delivery | Docker, Kubernetes, Caddy, Let's Encrypt | Containerized site deployment and HTTPS publishing |

# 3. Discussion

## 3.1 Environment Overview and Topology

Site 2 includes internal tenant services, remote administration entry points, cross-site connectivity, and a separate AWS public web stack.

The practical service flow is as follows:

- Company 2 users authenticate against Site 2 Samba AD identity services
- Company 2 clients consume DNS and DHCP from those identity nodes
- Company 2 file services are presented from Linux-based storage and SMB publishing
- Veeam on Site 2 protects selected Windows and Linux systems and then copies selected backup chains to Site 1 through an SMB offsite repository
- the ClearRoots public web service is hosted in AWS, fronted by Route53 and HTTPS, and deployed through a Kubernetes master/worker pair

This means Site 2 is both an operational tenant site and a platform site for backup and public web publishing.

### Table 1. Site 2 core server inventory

| System | Role | IP / Public Endpoint | Platform |
|---|---|---|---|
| C2IdM1 | Company 2 primary identity / DNS / DHCP | 172.30.65.66 | Linux / Samba AD |
| C2IdM2 | Company 2 secondary identity / DNS / DHCP | 172.30.65.67 | Linux / Samba AD |
| C2FS | Company 2 file services and sync host | 172.30.65.68 | Linux |
| C2LinuxClient | Company 2 Linux client validation host | 172.30.65.70 | Linux |
| C2WebServer | Company 2 web host | 172.30.65.170 | Linux |
| OPNsense | Site 2 routing / segmentation / MSP management path | 172.30.65.177 | Firewall appliance |
| Jump64 | Windows administrative jump host | 172.30.65.178 | Windows |
| Ubuntu Jump | Linux administrative jump host | Tailscale path validated | Ubuntu |
| S2Veeam | Site 2 Veeam Backup and Replication server | 172.30.65.180 | Windows Server |
| clearroots-kube-master | AWS Kubernetes control plane | 54.159.15.106 | Ubuntu EC2 |
| clearroots-kube-worker | AWS Kubernetes worker / public web node | 54.91.153.28 | Ubuntu EC2 |

**Suggested figure placement:** insert the AWS EC2 Instances screenshot here as Figure 1.

> **Figure 1 placeholder:** AWS EC2 console showing `clearroots-kube-master` and `clearroots-kube-worker` in the `Running` state.

## 3.2 Network Design and IP Addressing Rationale

The Site 2 design uses segmented addressing so that Company 2 tenant services, MSP management access, and cross-site dependencies can be tested independently. Internal services were validated primarily from approved jump workflows rather than from unrestricted flat reachability. This is important because several earlier failures looked like service failures at first, but were actually route preference or interface state problems.

The final testing outcome showed:

- Ubuntu jump was a reliable bastion for internal verification
- Windows jump needed interface correction before it became dependable
- inter-site routes were essential not just for administration, but for file synchronization and offsite backup copy

One design lesson from Site 2 is that reachability alone is not enough. Correct interface preference, DNS consistency, and route selection all materially affected service outcomes during validation.

### Table 3. Network and service path summary

| Path | Evidence | Final Interpretation |
|---|---|---|
| Operator to Windows jump | `100.97.37.83:3389` and `10.50.17.31:33464` reachable | Approved Windows administration path available |
| Operator to Ubuntu jump | `100.82.97.92:22` and `10.50.17.31:33564` reachable | Approved Linux administration path available |
| Ubuntu jump to C1 infrastructure | RDP/SMB reachable to C1DC1, C1DC2, C1FS | Reliable cross-site validation path |
| Ubuntu jump to C2 infrastructure | SSH/SMB reachable to C2IdM1, C2IdM2, C2FS, C2LinuxClient | Healthy internal management path |
| Public internal web edge | `10.50.17.31:33465` recovered | C1 web publishing restored |
| AWS public site | `clearroots.omerdengiz.com` on 443 | Public HTTPS web platform operational |

## 3.3 Identity Infrastructure and Tenant Separation

Company 2 uses Samba Active Directory Domain Controller services rather than Windows Server AD DS. This allowed the Site 2 design to demonstrate cross-platform identity operations while still supporting standard enterprise functions such as DNS integration, user and group administration, and client domain workflows.

The final validated identity design includes:

- two Company 2 identity nodes with healthy replication
- active DHCP service on both nodes
- internal and external DNS resolution from both nodes
- expected Company 2 users and groups present
- Company 2 Linux client correctly resolving domain users after SSSD recovery

This architecture also reinforced tenant separation. Company 2 identity services were functionally independent even though some cross-site management and DNS policy observations remained relevant. One earlier test showed Company 2 client visibility to Company 1 DNS over TCP 53, which was later treated as a policy/hardening review item rather than a core outage. In other words, service delivery was working, but segmentation policy could still be tightened further if required for final hardening.

## 3.4 Platform and Service Choice Rationale

Site 2 combines Linux-based tenant services with Windows-based backup orchestration and AWS public hosting. That combination was chosen because it demonstrates practical heterogeneity rather than a single-vendor stack.

The rationale behind the major choices is summarized below:

- **Samba AD for Company 2:** supports directory, DNS, and administrative workflows in a Linux environment
- **Linux file services for C2FS:** appropriate for SMB-backed shared storage and scripted sync workflows
- **Veeam on Windows Server:** aligns with common enterprise backup operations and gives strong GUI-driven management for backup, copy, and recovery workflows
- **Terraform on AWS:** repeatable infrastructure provisioning for the public web tier
- **Kubernetes on EC2:** demonstrates containerized deployment rather than static VM-only hosting
- **Caddy with Let's Encrypt:** lowest-cost public HTTPS enablement for a short-duration project deployment

### Table 5. Platform and service choice rationale

| Component | Why It Was Chosen | Operational Benefit |
|---|---|---|
| Samba AD | Linux-based directory services for Company 2 | Cross-platform identity management without requiring Windows AD for both tenants |
| Linux SMB/file host | Simple and scriptable file-service operations | Easy validation of storage, mounts, and scheduled sync |
| Veeam on Windows Server | Mature backup orchestration and reporting | Clear agent/file/copy workflows and easier demo evidence |
| AWS EC2 + Route53 | Public cloud hosting with DNS control | Real internet-facing deployment rather than internal-only publishing |
| Docker + Kubernetes | Reproducible application delivery | Cleaner deployment than static VM-only web hosting |
| Caddy | Automatic HTTPS and simple reverse proxy | Fast low-cost certificate automation for the public site |

### 3.4.1 Physical and logical baseline

Although this report focuses on Site 2 service outcomes rather than rack-level detail, Site 2 still depends on the shared private-cloud foundation established for the project. Logical service success relied on functioning hypervisor capacity, correct vNIC state, storage presentation, and routed inter-site connectivity. This became visible during troubleshooting when VM NIC attach/state issues caused the temporary C1Web and C2Web outages observed during initial testing.

### 3.4.2 Public web hosting baseline

The AWS website stack intentionally used a small footprint to keep cost low while still demonstrating modern deployment practices. The final working baseline included:

- manually created S3 bucket for Terraform remote state
- Terraform-managed EC2 master and worker
- Route53 public hosted zone record pointing to the worker Elastic IP
- Docker image build and registry push before deployment
- Kubernetes deployment and service creation from the master node
- manual confirmation that Caddy was installed and proxying traffic on the worker

## 3.5 Compute and Virtualization

Site 2 service delivery depends on both private virtualization and public cloud compute.

On the private side, Site 2 systems were validated through their operational roles rather than through hypervisor screenshots alone. The strongest evidence was service-oriented:

- identity services on both C2IdM nodes were active
- C2FS mounted storage and published file services
- C2Web recovered after VM-side NIC correction
- jump systems enabled repeatable administration and testing

On the public side, the AWS environment was intentionally lightweight:

- one Kubernetes master node
- one Kubernetes worker node
- both running on `t3.micro` instances in `us-east-1c`

The worker node was associated with an Elastic IP and published the web application through Caddy on ports 80 and 443. Route53 then mapped `clearroots.omerdengiz.com` to that public worker endpoint.

**Suggested figure placement:** insert the Kubernetes nodes/pods terminal screenshot here as Figure 3.

> **Figure 2 placeholder:** Public browser view of the ClearRoots Foundation landing page over HTTPS.
>
> **Figure 3 placeholder:** `kubectl get nodes` and `kubectl get pods` showing both nodes `Ready` and the ClearRoots pods `Running`.

## 3.6 Identity, DNS, and DHCP Services

The final Company 2 identity stack achieved the intended operational outcomes:

- healthy Samba replication on both identity nodes
- active DHCP services on both nodes
- confirmed internal DNS resolution between identity hosts
- confirmed external resolution for public names
- restored domain-user lookup on the Linux client after SSSD restart

This area is especially important because the original test pass found a real failure on `C2LinuxClient`: domain membership existed, but user resolution through NSS/SSSD was broken. That issue would have prevented normal authentication workflows even though the machine appeared domain joined. After SSSD recovery, `administrator@c2.local` and `employee1@c2.local` resolved successfully, turning the issue from a service failure into a completed fix.

From an operations perspective, this shows that domain join state alone is not enough. Identity validation must include actual user resolution and client-side lookup behavior.

### Table 4. Identity services summary

| Service Area | Node(s) | Final State |
|---|---|---|
| AD replication | C2IdM1, C2IdM2 | Healthy, 0 consecutive failures observed |
| Internal DNS | C2IdM1, C2IdM2 | Internal host resolution confirmed |
| External DNS recursion | C2IdM1, C2IdM2 | External name resolution confirmed |
| DHCP | C2IdM1, C2IdM2 | Active on both nodes with failover configuration present |
| Domain user lookup | C2LinuxClient | Restored after SSSD recovery |

## 3.7 Storage and File Services

Company 2 file services are centered on `C2FS` and its Linux storage layout. Earlier evidence confirmed:

- `smbd` active on C2FS
- mounted storage under `/mnt/c2_public`
- `Public` and `Private` directories present
- sync automation scheduled through cron

The later refresh then confirmed that the Site 2 to Site 1 sync route had recovered and that a manual run of `/usr/local/bin/c2_site1_sync.sh` succeeded. This is an important change in final state because earlier evidence showed the sync path broken with `No route to host`.

As a result, the final documented state for Site 2 file services is:

- local SMB-backed Company 2 file service is healthy
- scheduled sync tooling is present
- inter-site path is operational again

### Table C1. Storage and file-service reference

| Host | Storage Path | Purpose |
|---|---|---|
| C2FS | `/mnt/c2_public` | Local mounted file-service storage |
| C2FS | `/mnt/c2_public/Public` | Shared collaboration area |
| C2FS | `/mnt/c2_public/Private` | User-private storage structure |
| C2FS | `/usr/local/bin/c2_site1_sync.sh` | Inter-site synchronization script |
| C2FS | `/var/log/c2_site1_sync.log` | Sync execution log |

## 3.8 Backup and Recovery

Backup and recovery became one of the strongest Site 2 outcomes by the end of the project. After a difficult troubleshooting phase, Site 2 Veeam services were rebuilt, validated, and brought into a clean success state.

The final Veeam implementation includes three layers:

- local agent-based backups
- file-share backups
- offsite backup copy to Site 1 through SMB

An important operational finding was that time synchronization was a major hidden dependency. Earlier Veeam problems appeared to resemble firewall or component-registration failures, but after NTP correction the environment stabilized and rescans continued to succeed even with firewall protection re-enabled. This strongly suggests time skew was the primary root cause in the hardest phase of backup troubleshooting.

### 3.8.1 Agent-based system backup

Site 2 Veeam was configured to protect a mixed set of Windows and Linux systems through a single protection group and separate job types for the actual backup execution.

### Table 2. Site 2 protected systems in Veeam

| IP | System | Backup Type |
|---|---|---|
| 172.30.65.2 | C1DC1 | Windows agent backup |
| 172.30.65.4 | C1FS | Windows agent backup |
| 172.30.65.162 | C1WebServer | Windows agent backup |
| 172.30.65.11 | C1WindowsClient | Windows agent backup |
| 172.30.65.178 | Jump64 | Windows agent backup |
| 172.30.65.36 | C1LinuxClient | Linux agent backup |
| 172.30.65.66 | C2IdM1 | Linux agent backup |
| 172.30.65.68 | C2FS | Linux agent backup |
| 172.30.65.170 | C2WebServer | Linux agent backup |
| 172.30.65.70 | C2LinuxClient | Linux agent backup |

The production job set included:

- `Site2_Windows_AgentBackup`
- `Site2_Linux_AgentBackup`

Both were later shown in a successful state.

### 3.8.2 File-share backup

Two file-based jobs were created to protect file-service content separately from the system-level agent backups:

- `C1 File Backup Job`
- `C2 File Backup Job`

This design is appropriate because file-share retention and restore workflows are different from full system recovery workflows. It also made the later copy jobs easier to interpret in the offsite repository, where separate copy folders were created automatically by Veeam.

### 3.8.3 Offsite backup copy to Site 1

Site 2 offsite protection was implemented through an SMB shared-folder repository hosted on Site 1. The share path used for Site 2 offsite copy was:

`\\192.168.64.20\Site2OffsiteFromSite2`

This repository was mapped in Veeam as an offsite shared-folder target. Backup copy jobs then sent selected chains from Site 2 to the Site 1 SMB repository. The resulting offsite folder structure included:

- `C1 File Backup Job (Copy) 1`
- `C2 File Backup Job (Copy) 1`
- `Site2_Offsite_Copy`

This confirms that Site 2 data is no longer protected only locally. It now has an additional recovery location in Site 1, which materially improves resilience against local repository loss or single-site failure.

### Table D1. Backup repository reference

| Repository | Path / Type | Purpose |
|---|---|---|
| Site2 | Local Site 2 repository | Primary local Veeam backup target |
| `\\192.168.64.20\Site2OffsiteFromSite2` | SMB shared-folder repository | Site 2 offsite copy target hosted in Site 1 |
| `R:\Repo_Site2_Offsite\Site2OffsiteFromSite2` | Windows folder on Site 1 | Backing path for offsite copy storage |

### Table 8. Site 2 backup job schedule summary

| Job | Type | Intended Schedule / Role |
|---|---|---|
| Site2_Windows_AgentBackup | Windows agent backup | Daily operational protection for Windows hosts |
| Site2_Linux_AgentBackup | Linux agent backup | Daily operational protection for Linux hosts |
| C1 File Backup Job | File backup | File-level protection for selected share content |
| C2 File Backup Job | File backup | File-level protection for selected share content |
| Site2_Offsite_Copy | Backup copy | Offsite copy to Site 1 SMB repository |

**Suggested figure placement:** insert the Veeam Success history screenshot here as Figure 6.  
**Suggested figure placement:** insert the Site2OffsiteFromSite2 folder screenshot here as Figure 7.

> **Figure 6 placeholder:** Veeam job history showing successful Site 2 backup and backup copy sessions.
>
> **Figure 7 placeholder:** Windows Explorer view of `R:\Repo_Site2_Offsite\Site2OffsiteFromSite2` showing backup-copy folders.

## 3.9 Value Added Features

Site 2 includes several value-added elements beyond baseline tenant service delivery.

### 3.9.1 Public AWS-hosted ClearRoots website with automated HTTPS

One of the clearest Site 2 value-add outcomes is the public ClearRoots Foundation website hosted in AWS. This design includes:

- Terraform-based EC2 provisioning
- Kubernetes deployment on a master/worker pair
- Docker image-based application packaging
- Route53 public DNS
- Elastic IP on the worker node
- S3 remote state backend
- Caddy reverse proxy for HTTPS
- automated certificate issuance using Let's Encrypt

The final public result is a working HTTPS site at:

`https://clearroots.omerdengiz.com`

This was not only a hosting exercise. It demonstrated that Site 2 could support a lightweight but realistic public publishing workflow with repeatable infrastructure and automated certificate handling.

### Table 3. AWS public website deployment components

| Component | Purpose |
|---|---|
| EC2 master node | Kubernetes control plane |
| EC2 worker node | Web workload host and public HTTPS endpoint |
| Route53 hosted zone | Public DNS for `clearroots.omerdengiz.com` |
| Elastic IP | Stable public address for the worker |
| S3 backend | Terraform remote state storage |
| Docker image | Application packaging for the web content |
| Kubernetes deployment/service | Web application scheduling and exposure |
| Caddy | Reverse proxy and automated HTTPS |

**Suggested figure placement:** insert the AWS EC2 screenshot as Figure 1.  
**Suggested figure placement:** insert the public ClearRoots page screenshot as Figure 2.  
**Suggested figure placement:** insert the S3 backend screenshot as Figure 4.  
**Suggested figure placement:** insert the Route53 hosted zone screenshot as Figure 5.

> **Figure 4 placeholder:** Amazon S3 console showing the Terraform state object under `clearroots/k8s/terraform.tfstate`.
>
> **Figure 5 placeholder:** Route53 public hosted zone showing the A record for `clearroots.omerdengiz.com`.

### 3.9.2 Internal HTTPS trust deployment for Lumora

Although primarily associated with Company 1 internal publishing, the Lumora HTTPS work is relevant to Site 2 documentation because it demonstrates another applied certificate-management workflow in the broader project. A self-signed certificate for `www.lumora.c1.local` was deployed and then distributed to trusted clients using Group Policy (`Deploy Lumora Web Certificate`). That process shows a second certificate management model in the project:

- internal trust by GPO for private domain use
- public trust by Let's Encrypt for AWS public web delivery

Together, these demonstrate practical understanding of different certificate deployment models for internal and public services.

> **Figure 8 placeholder:** Group Policy Management screenshot for `Deploy Lumora Web Certificate`.

### 3.9.3 Infrastructure-as-code improvements

The AWS website stack also benefitted from a more supportable Terraform design:

- S3 backend bucket creation was removed from Terraform to avoid repeated apply/destroy issues
- state remained remotely stored through a manually created S3 bucket
- deprecated inline IAM role policy usage was corrected by moving policy definition to a dedicated `aws_iam_role_policy` resource
- user-data scripts were hardened with logging, retries, and safer bootstrap steps

These are not just technical refinements; they improve repeatability, reduce deployment fragility, and make the environment easier to explain and maintain.

## 3.10 Site-to-Site VPN Security and Administrative Access

### 3.10.1 Site-to-site connectivity

The Site 1 and Site 2 environments rely on approved inter-site paths for:

- cross-site administrative validation
- file synchronization
- backup copy traffic
- support onboarding and final demonstration workflows

Earlier failures showed how dependent Site 2 services were on inter-site correctness. When the sync route to Site 1 failed, file replication appeared broken. Once the route was restored and the script retested manually, the service returned to a healthy state. This reinforces that Site 2’s recovery design depends on stable routed trust, not just local service uptime.

### 3.10.2 Administrative access

Two jump systems were part of the approved management model:

- a Windows jump box
- an Ubuntu jump box

In practice, the Ubuntu jump became the most reliable validation vantage point during troubleshooting. The Windows jump initially suffered from wrong-interface preference until the blue NIC was disabled. That corrective action turned the Windows jump back into a usable management host.

The practical lesson is that administrative access should be treated as a service dependency of its own. If jump workflows are unstable, even healthy backend services can appear broken during operations.

## 3.11 Maintenance and Daily Duties

Site 2 is now in a state where daily support duties can be described clearly.

### 3.11.1 Standard Change Workflow

The safest support workflow for Site 2 is a change-first, evidence-second model:

- validate current service state before making changes
- record whether the change affects private services, public cloud services, or both
- use `terraform plan` before AWS infrastructure changes
- confirm backup status before risky changes to C2FS, identity services, or Veeam
- apply the smallest practical change
- re-test from the correct approved vantage point, especially the Ubuntu jump for internal validation

In practice, this matters because several earlier problems were not true service failures. They were caused by route preference, VM NIC state, or identity cache behavior. A disciplined change workflow reduces the chance of diagnosing the wrong layer.

Routine daily checks should include:

- verify success of `Site2_Windows_AgentBackup`
- verify success of `Site2_Linux_AgentBackup`
- verify success of `C1 File Backup Job`
- verify success of `C2 File Backup Job`
- verify success of copy jobs including `Site2_Offsite_Copy`
- confirm offsite folders continue to populate under the Site 1 SMB repository

### 3.11.2 Failure Domains and Recovery Priority

Site 2 includes multiple distinct failure domains, and they should not all be treated equally. The recommended recovery order is:

1. Identity and DNS failure
   Company 2 authentication, DNS, and DHCP are foundational. If C2IdM1/C2IdM2 are unhealthy, most tenant workflows are affected.
2. File service failure
   If C2FS or its mounted storage fails, user data access is impacted even if identity is still healthy.
3. Backup platform failure
   If Veeam is unhealthy, immediate production services may still work, but recoverability degrades quickly.
4. Public cloud web failure
   The ClearRoots website is important and visible, but it is not as foundational to tenant login and internal file access as the identity and storage stack.

Within each failure domain, the recommended technical checks are:

- Samba replication status on C2IdM1 and C2IdM2
- DNS resolution of internal and external names
- DHCP service state on both identity nodes
- domain-user resolution from C2LinuxClient
- C2FS mount status and `smbd` service
- Veeam job success and offsite copy completion
- `kubectl get nodes`, `kubectl get pods`, and `systemctl status caddy`

The cloud web tier should still be checked routinely, but its recovery priority should be balanced against core tenant identity and file-service needs.

## 3.12 Limitations, Risks, and Unresolved Items

Although Site 2 reached a strong final state, several realistic limitations remain:

- the AWS Kubernetes web stack is intentionally lightweight and not highly available
- the public site uses a single worker node, so the web path still contains a single-node failure point
- Company 2 client visibility to Company 1 DNS was flagged earlier as a potential segmentation hardening issue
- some evidence in the project was produced after corrective action rather than on the first pass, which should be documented honestly during handover
- backup success has been validated operationally, but restore demonstrations should still be performed as part of ongoing best practice

These are acceptable limitations for a project environment, but they should be acknowledged clearly so that support staff understand both the strengths and the current boundaries of the design.

# 4. Conclusion

Site 2 ultimately matured into a stable, multi-role environment supporting Company 2 tenant services, cross-site recovery operations, and public HTTPS publishing. The final design successfully combines Linux identity services, file services, jump-based administration, Windows-based Veeam operations, and AWS-hosted public web delivery.

The most meaningful final outcomes are:

- Company 2 identity, DNS, DHCP, and file services are operational
- earlier service failures were resolved and narrowed to either routing, NIC state, SSSD, or temporary sync reachability
- Veeam now provides successful local backup, file backup, and offsite backup copy workflows
- the ClearRoots Foundation website is publicly reachable over HTTPS using a repeatable Terraform and Kubernetes deployment pattern

From a handover and demonstration standpoint, Site 2 now represents a credible supportable environment rather than only a lab build. It shows not just deployment, but troubleshooting, stabilization, and operational validation.

# 5. Appendices

## Appendix A. Network Addressing

### Table A1. Site 2 network addressing summary

| Host / Service | Address |
|---|---|
| C2IdM1 | 172.30.65.66 |
| C2IdM2 | 172.30.65.67 |
| C2FS | 172.30.65.68 |
| C2LinuxClient | 172.30.65.70 |
| C2WebServer | 172.30.65.170 |
| OPNsense management | 172.30.65.177 |
| Jump64 | 172.30.65.178 |
| S2Veeam | 172.30.65.180 |
| C1DC1 | 172.30.65.2 |
| C1DC2 | 172.30.65.3 |
| C1FS | 172.30.65.4 |
| C1WebServer | 172.30.65.162 |
| ClearRoots AWS worker public IP | 54.91.153.28 |
| ClearRoots AWS master public IP | 54.159.15.106 |

## Appendix B. DHCP Reference

### Table B1. DHCP service reference

| Node | Role | Status |
|---|---|---|
| C2IdM1 | Primary/active DHCP service host | Validated active |
| C2IdM2 | Secondary/failover DHCP service host | Validated active |
| Company 2 client subnet | `172.30.65.64/26` | Present in configuration |

## Appendix C. Storage Reference

### Table C2. Storage reference

| Item | Path / Mount | Notes |
|---|---|---|
| C2FS shared storage | `/mnt/c2_public` | Mounted and healthy |
| Public share | `/mnt/c2_public/Public` | Shared collaboration |
| Private share | `/mnt/c2_public/Private` | Per-user private data |
| Site 2 offsite folder on Site 1 | `R:\Repo_Site2_Offsite\Site2OffsiteFromSite2` | SMB destination for backup copy |

## Appendix D. Backup Reference

### Table D2. Veeam job set

| Job | Type | Final Status |
|---|---|---|
| Site2_Windows_AgentBackup | Windows agent backup | Success |
| Site2_Linux_AgentBackup | Linux agent backup | Success |
| C1 File Backup Job | File backup | Success |
| C2 File Backup Job | File backup | Success |
| C1 File Backup Job (Copy) 1 | Backup copy | Success |
| C2 File Backup Job (Copy) 1 | Backup copy | Success |
| Site2_Offsite_Copy | Backup copy | Success |

## Appendix E. Site 2 Requirement Coverage and Demonstration Notes

### Network and Shared Infrastructure

- Site 2 administrative paths were validated from approved jump workflows.
- Ubuntu jump proved to be the most reliable bastion during troubleshooting.
- Inter-site connectivity was shown to be sufficient for administration, synchronization, and backup copy.

### Company 2

- Samba AD identity services on C2IdM1 and C2IdM2 were healthy and replicating.
- DHCP service was active on both identity nodes.
- DNS resolution worked for both internal and external targets.
- C2LinuxClient domain-user lookup was restored after SSSD restart.
- C2FS storage, SMB service, and manual inter-site sync were functioning in the refreshed final state.
- C2Web recovered and HTTP became reachable from approved validation paths.

### Cross-Site and Remote Access

- C1 infrastructure remained reachable from the Ubuntu jump for administration.
- Site 2 backup copy to Site 1 over SMB was implemented successfully.
- Route and sync issues that initially affected Site 2 were corrected before final validation.

### Public Cloud Deliverable

- Terraform state was stored in S3 under `clearroots/k8s/terraform.tfstate`.
- Route53 hosted zone `clearroots.omerdengiz.com` published the public A record to the worker Elastic IP.
- Kubernetes master and worker nodes both reached `Ready` state.
- two `clearroots-web` pods were shown `Running`.
- the public website loaded successfully over HTTPS.

### Operations and Demonstration Use

- Veeam success history demonstrates operationally completed backup jobs.
- offsite repository folder growth demonstrates that backup copy traffic reached Site 1.
- the AWS web stack provides a presentation-ready public deliverable that can be shown independently of internal tenant services.

# 6. References

[1] Proxmox Server Solutions GmbH, "Proxmox Virtual Environment Documentation," [Online]. Available: https://pve.proxmox.com/pve-docs/. [Accessed: Mar. 19, 2026].

[2] OPNsense Project, "OPNsense Documentation," [Online]. Available: https://docs.opnsense.org/. [Accessed: Mar. 19, 2026].

[3] Microsoft, "Windows Server Documentation," [Online]. Available: https://learn.microsoft.com/windows-server/. [Accessed: Mar. 19, 2026].

[4] Samba Team, "Setting up Samba as an Active Directory Domain Controller," [Online]. Available: https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller. [Accessed: Mar. 19, 2026].

[5] Veeam Software, "Veeam Backup and Replication Documentation," [Online]. Available: https://helpcenter.veeam.com/. [Accessed: Mar. 19, 2026].

[6] HashiCorp, "Terraform Documentation," [Online]. Available: https://developer.hashicorp.com/terraform/docs. [Accessed: Mar. 19, 2026].

[7] Amazon Web Services, "Amazon EC2 Documentation," [Online]. Available: https://docs.aws.amazon.com/ec2/. [Accessed: Mar. 19, 2026].

[8] Amazon Web Services, "Amazon Route 53 Documentation," [Online]. Available: https://docs.aws.amazon.com/route53/. [Accessed: Mar. 19, 2026].

[9] Amazon Web Services, "Amazon S3 Documentation," [Online]. Available: https://docs.aws.amazon.com/s3/. [Accessed: Mar. 19, 2026].

[10] Kubernetes Authors, "Kubernetes Documentation," [Online]. Available: https://kubernetes.io/docs/. [Accessed: Mar. 19, 2026].

[11] Caddy Server, "Caddy Documentation," [Online]. Available: https://caddyserver.com/docs/. [Accessed: Mar. 19, 2026].
