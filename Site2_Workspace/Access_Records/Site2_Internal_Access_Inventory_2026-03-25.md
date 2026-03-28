# Site 2 Internal Access Inventory

Date: March 25, 2026

This inventory lists internal project IP addresses, access methods, usernames, and role notes for the Site 2 environment. Passwords are intentionally excluded from this record and should be handled through the separately maintained credential source.

## Direct Administrative Access

| Hostname | Internal IP | Access Method | Username | Role / Notes |
|---|---|---|---|---|
| `MSPUbuntuJump` | `172.30.65.179` | `SSH` | `admin` | MSP Linux bastion host |
| `Jump64` | `172.30.65.178` | `RDP` | `.\Administrator` | MSP Windows jump host |
| `S2Veeam` | `172.30.65.180` | `RDP` | `.\Administrator` | Site 2 Veeam server |
| `C2IdM1` | `172.30.65.66` | `SSH` | `admin` | Company 2 identity, DNS, and DHCP node |
| `C2IdM2` | `172.30.65.67` | `SSH` | `admin` | Company 2 identity, DNS, and DHCP node |
| `C2FS` | `172.30.65.68` | `SSH` | `admin` | Company 2 file server |
| `C2LinuxClient` | `172.30.65.70` | `SSH` | `admin` | Company 2 Linux client |
| `C2WebServer` | `172.30.65.170` | `SSH` | `admin` | Company 2 internal web server |

## Internal Service Inventory

| Hostname / Service | Internal IP | Primary Role | Access Notes |
|---|---|---|---|
| `RP-S2-Gateway` | `172.30.65.177` | OPNsense gateway | Managed from the MSP admin path |
| `C1DC1` | `172.30.65.2` | Company 1 domain controller | Company 1 internal service host |
| `C1DC2` | `172.30.65.3` | Company 1 domain controller | Company 1 internal service host |
| `C1FS` | `172.30.65.4` | Company 1 file server | Company 1 internal service host |
| `C1WindowsClient` | `172.30.65.11` | Company 1 Windows client | Company 1 internal client |
| `C1UbuntuClient` | `172.30.65.36` | Company 1 Linux client | Company 1 internal client |
| `C1WebServer` | `172.30.65.162` | Company 1 internal web server | Hostname-based IIS service |
| `C1SAN` | `172.30.65.186` | Company 1 isolated SAN | Storage-side network only |
| `C2SAN` | `172.30.65.194` | Company 2 isolated SAN | Storage-side network only |

## Internal Web Hostnames

| Service Hostname | Current A Records |
|---|---|
| `c1-webserver.c1.local` | `172.30.64.162`, `172.30.65.162` |
| `c2-webserver.c2.local` | `172.30.64.170`, `172.30.65.170` |

## Notes

- This inventory intentionally excludes external relay or overlay-network addresses.
- Passwords are not stored in this file.
- Storage-side SAN addresses are included for topology and service-reference purposes, not as ordinary user-facing access points.
